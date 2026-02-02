const mongoose = require('mongoose');

const pricingRuleSchema = new mongoose.Schema({
    gameType: { type: String, enum: ['Pool', 'Snooker'], required: true, unique: true },
    hourlyRate: { type: Number, default: 200 },
    minCharge: { type: Number, default: 0 },
    slots: [{
        durationMinutes: { type: Number, required: true }, // 30, 60, 90, etc.
        price: { type: Number, required: true }
    }],
    fixedRates: [{
        label: String,
        amount: Number
    }],
    peakHours: [{
        startHour: Number, // 0-23
        endHour: Number,
        multiplier: Number // e.g., 1.2 for 20% increase
    }]
}, { timestamps: true });

const globalSettingsSchema = new mongoose.Schema({
    key: { type: String, default: 'main', unique: true },
    businessDetails: {
        name: { type: String, default: 'TTC Pool Club' },
        address: { type: String, default: '' },
        phone: { type: String, default: '' },
        gstin: { type: String, default: '' }
    },
    taxPercentage: { type: Number, default: 12 },
    taxEnabled: { type: Boolean, default: true },
    currency: { type: String, default: '₹' },
    autoLogoutDuration: { type: Number, default: 30 }, // in minutes
    autoEndOnTimeOver: { type: Boolean, default: false },
    pricingRules: [pricingRuleSchema]
}, { timestamps: true });

module.exports = mongoose.model('Settings', globalSettingsSchema);
