const mongoose = require('mongoose');
const Settings = require('./models/Settings');
require('dotenv').config();

const initializePricing = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        let settings = await Settings.findOne({ key: 'main' });
        if (!settings) {
            settings = new Settings({ key: 'main' });
        }

        // Pool: 30 min = ₹100, 1 hour = ₹200
        // Snooker: 30 min = ₹150, 1 hour = ₹300
        settings.pricingRules = [
            {
                gameType: 'Pool',
                hourlyRate: 200,
                minCharge: 0,
                slots: [
                    { durationMinutes: 30, price: 100 },
                    { durationMinutes: 60, price: 200 }
                ]
            },
            {
                gameType: 'Snooker',
                hourlyRate: 300,
                minCharge: 0,
                slots: [
                    { durationMinutes: 30, price: 150 },
                    { durationMinutes: 60, price: 300 }
                ]
            }
        ];

        await settings.save();
        console.log('✅ Pricing rules initialized successfully');
        console.log(JSON.stringify(settings, null, 2));
        await mongoose.disconnect();
        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error.message);
        await mongoose.disconnect();
        process.exit(1);
    }
};

initializePricing();
