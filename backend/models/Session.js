const mongoose = require('mongoose');

const sessionSchema = new mongoose.Schema({
    table: { type: mongoose.Schema.Types.ObjectId, ref: 'Table', required: true },
    startTime: { type: Date, default: Date.now },
    endTime: { type: Date },
    pricingMode: { type: String, enum: ['per_hour', 'per_minute', 'fixed'], default: 'per_hour' },
    players: { type: Number, default: 1 },
    timeLimitInMinutes: { type: Number, default: 0 }, // 0 means no limit
    hourlyRateAtStart: { type: Number, required: true },
    minChargeAtStart: { type: Number, default: 0 },
    taxRateAtStart: { type: Number, default: 0 },
    segments: [{
        start: { type: Date, required: true },
        end: { type: Date } // if null, it's currently running
    }],
    subtotal: { type: Number, default: 0 },
    taxAmount: { type: Number, default: 0 },
    totalAmount: { type: Number, default: 0 },
    totalBilled: { type: Number, default: 0 }, // legacy/total
    paymentMethod: { type: String, enum: ['Cash', 'UPI', 'Other', null], default: null },
    handledBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    status: { type: String, enum: ['Active', 'Completed'], default: 'Active' }
}, { timestamps: true });

module.exports = mongoose.model('Session', sessionSchema);
