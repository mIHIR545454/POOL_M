const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');
const morgan = require('morgan');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const tableRoutes = require('./routes/tables');
const adminRoutes = require('./routes/admin');
const Table = require('./models/Table');
const Session = require('./models/Session');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

// Middleware
app.use(express.json());
app.use(cors());
app.use(morgan('dev'));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/tables', tableRoutes);
app.use('/api/admin', adminRoutes);

// Socket logic
io.on('connection', (socket) => {
    console.log('New client connected');

    // Send initial data
    const sendUpdates = async () => {
        const tables = await Table.find().populate('currentSession');
        socket.emit('tableUpdate', tables);
    };

    sendUpdates();

    socket.on('disconnect', () => {
        console.log('Client disconnected');
    });
});

// Periodically broadcast updates for live timers (every 2 seconds for high precision)
setInterval(async () => {
    try {
        const tables = await Table.find({ status: { $in: ['Running', 'Paused', 'Time Over'] } }).populate('currentSession');

        for (let table of tables) {
            if (table.status === 'Running' && table.currentSession) {
                const session = table.currentSession;

                // Calculate current elapsed minutes
                let totalMinutes = 0;
                session.segments.forEach(seg => {
                    const end = seg.end || new Date();
                    totalMinutes += (end - seg.start) / (1000 * 60);
                });

                // Check for Time Over
                if (session.timeLimitInMinutes > 0 && totalMinutes >= session.timeLimitInMinutes) {
                    table.status = 'Time Over';
                    await table.save();
                    io.emit('notification', {
                        type: 'TIME_OVER',
                        tableName: table.name,
                        message: `${table.name} has finished its allotted time!`
                    });
                }
            }
        }

        // Always broadcast latest state to all clients
        const allTables = await Table.find().populate('currentSession');
        io.emit('tableUpdate', allTables);
    } catch (err) {
        console.error('Error in timer broadcast:', err);
    }
}, 2000);

// Database Connection
mongoose.connect(process.env.MONGODB_URI)
    .then(() => console.log('Connected to MongoDB'))
    .catch(err => console.error('Could not connect to MongoDB', err));

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});

module.exports = { io };
