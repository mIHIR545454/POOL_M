const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema({
    table: { type: mongoose.Schema.Types.ObjectId, ref: 'Table' },
    session: { type: mongoose.Schema.Types.ObjectId, ref: 'Session' },
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    action: { type: String, required: true }, // START, PAUSE, RESUME, END, BILL_GENERATED
    details: { type: String },
    timestamp: { type: Date, default: Date.now }
}, { timestamps: true });

module.exports = mongoose.model('AuditLog', auditLogSchema);
