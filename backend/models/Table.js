const mongoose = require('mongoose');

const tableSchema = new mongoose.Schema({
    name: { type: String, required: true },
    type: { type: String, enum: ['Pool', 'Snooker'], default: 'Pool' }, // Current/Primary type
    supportedTypes: [String],
    status: { type: String, enum: ['Idle', 'Running', 'Paused', 'Ended', 'Time Over'], default: 'Idle' },
    hourlyRate: { type: Number, required: true },
    currentSession: { type: mongoose.Schema.Types.ObjectId, ref: 'Session' },
    isActive: { type: Boolean, default: true }
}, { timestamps: true });

module.exports = mongoose.model('Table', tableSchema);
