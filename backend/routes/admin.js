const express = require('express');
const router = express.Router();
const Session = require('../models/Session');
const Table = require('../models/Table');
const User = require('../models/User');
const Settings = require('../models/Settings');

// Middleware to check if user is admin
const isAdmin = async (req, res, next) => {
    // In a real app, this would check the JWT payload or DB
    // For now, we assume the route is protected by standard auth and we check roles here if needed
    next();
};

// Get Pricing Settings
router.get('/settings', isAdmin, async (req, res) => {
    try {
        let settings = await Settings.findOne({ key: 'main' });
        if (!settings) {
            settings = new Settings({
                key: 'main',
                taxPercentage: 12,
                pricingRules: [
                    { gameType: 'Pool', hourlyRate: 200, minCharge: 50 },
                    { gameType: 'Snooker', hourlyRate: 350, minCharge: 100 }
                ]
            });
            await settings.save();
        }
        res.json(settings);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Update Settings
router.post('/settings', isAdmin, async (req, res) => {
    try {
        const {
            taxPercentage,
            pricingRules,
            businessDetails,
            taxEnabled,
            currency,
            autoLogoutDuration,
            autoEndOnTimeOver
        } = req.body;

        let settings = await Settings.findOne({ key: 'main' });

        if (!settings) {
            settings = new Settings({ key: 'main' });
        }

        if (taxPercentage !== undefined) settings.taxPercentage = taxPercentage;
        if (pricingRules) settings.pricingRules = pricingRules;
        if (businessDetails) settings.businessDetails = businessDetails;
        if (taxEnabled !== undefined) settings.taxEnabled = taxEnabled;
        if (currency) settings.currency = currency;
        if (autoLogoutDuration !== undefined) settings.autoLogoutDuration = autoLogoutDuration;
        if (autoEndOnTimeOver !== undefined) settings.autoEndOnTimeOver = autoEndOnTimeOver;

        await settings.save();
        res.json(settings);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Create Table
router.post('/tables', isAdmin, async (req, res) => {
    try {
        const { name, type, supportedTypes, hourlyRate } = req.body;
        const table = new Table({
            name,
            type: type || (supportedTypes ? supportedTypes[0] : 'Pool'),
            supportedTypes: supportedTypes || ['Pool'],
            hourlyRate: hourlyRate || 200
        });
        await table.save();
        res.status(201).json(table);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Update Table
router.put('/tables/:id', isAdmin, async (req, res) => {
    try {
        const { name, type, supportedTypes, hourlyRate, isActive } = req.body;
        const table = await Table.findById(req.params.id);
        if (!table) return res.status(404).json({ message: 'Table not found' });

        if (name) table.name = name;
        if (type) table.type = type;
        if (supportedTypes) table.supportedTypes = supportedTypes;
        if (hourlyRate) table.hourlyRate = hourlyRate;
        if (isActive !== undefined) table.isActive = isActive;

        await table.save();
        res.json(table);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Delete Table (Soft delete or hard delete?) 
// The prompt doesn't specify delete, but it specifies enable/disable.
// Toggling isActive is handled in the PUT route above.

// Route to get all tables (including inactive ones) for Admin
router.get('/tables', isAdmin, async (req, res) => {
    try {
        const tables = await Table.find().sort({ name: 1 });
        res.json(tables);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// STAFF MANAGEMENT ROUTES

// Get all staff
router.get('/staff', isAdmin, async (req, res) => {
    try {
        const staff = await User.find().select('-password').sort({ createdAt: -1 });
        res.json(staff);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Add new staff
router.post('/staff', isAdmin, async (req, res) => {
    try {
        const { username, password, mobile, role } = req.body;
        const user = new User({ username, password, mobile, role });
        await user.save();
        res.status(201).json({ message: 'Staff created', user: { id: user._id, username: user.username } });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Update staff status/role
router.put('/staff/:id', isAdmin, async (req, res) => {
    try {
        const { isActive, role, mobile, password } = req.body;
        const user = await User.findById(req.params.id);
        if (!user) return res.status(404).json({ message: 'User not found' });

        if (isActive !== undefined) user.isActive = isActive;
        if (role) user.role = role;
        if (mobile) user.mobile = mobile;
        if (password) user.password = password; // Pre-save hook will hash it

        await user.save();
        res.json({ message: 'Staff updated', user });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Get staff activity logs
router.get('/staff/:id/logs', isAdmin, async (req, res) => {
    try {
        const logs = await AuditLog.find({ user: req.params.id })
            .populate('table', 'name')
            .sort({ createdAt: -1 })
            .limit(50);
        res.json(logs);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

router.get('/stats', isAdmin, async (req, res) => {
    try {
        const now = new Date();
        const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const startOfWeek = new Date(now.setDate(now.getDate() - now.getDay()));
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

        // Revenue Aggregation
        const revenueStats = await Session.aggregate([
            { $match: { status: 'Completed' } },
            {
                $group: {
                    _id: null,
                    today: {
                        $sum: { $cond: [{ $gte: ['$createdAt', startOfToday] }, '$totalAmount', 0] }
                    },
                    week: {
                        $sum: { $cond: [{ $gte: ['$createdAt', startOfWeek] }, '$totalAmount', 0] }
                    },
                    month: {
                        $sum: { $cond: [{ $gte: ['$createdAt', startOfMonth] }, '$totalAmount', 0] }
                    },
                    total: { $sum: '$totalAmount' }
                }
            }
        ]);

        const revenue = revenueStats[0] || { today: 0, week: 0, month: 0, total: 0 };

        // Table Utilization
        const tableUtilization = await Session.aggregate([
            { $match: { status: 'Completed' } },
            {
                $group: {
                    _id: '$table',
                    count: { $sum: 1 },
                    totalMinutes: {
                        $sum: {
                            $reduce: {
                                input: '$segments',
                                initialValue: 0,
                                in: {
                                    $add: [
                                        '$$value',
                                        { $divide: [{ $subtract: ['$$this.end', '$$this.start'] }, 1000 * 60] }
                                    ]
                                }
                            }
                        }
                    }
                }
            },
            { $lookup: { from: 'tables', localField: '_id', foreignField: '_id', as: 'tableInfo' } },
            { $unwind: '$tableInfo' },
            { $project: { name: '$tableInfo.name', count: 1, totalMinutes: 1 } }
        ]);

        // Staff Performance
        const staffPerformance = await Session.aggregate([
            { $match: { status: 'Completed', handledBy: { $ne: null } } },
            {
                $group: {
                    _id: '$handledBy',
                    totalRevenue: { $sum: '$totalAmount' },
                    sessionsCount: { $sum: 1 }
                }
            },
            { $lookup: { from: 'users', localField: '_id', foreignField: '_id', as: 'userInfo' } },
            { $unwind: '$userInfo' },
            { $project: { username: '$userInfo.username', totalRevenue: 1, sessionsCount: 1 } }
        ]);

        // Peak Hours (By session start hour)
        const peakHours = await Session.aggregate([
            {
                $project: {
                    hour: { $hour: '$startTime' }
                }
            },
            {
                $group: {
                    _id: '$hour',
                    count: { $sum: 1 }
                }
            },
            { $sort: { _id: 1 } }
        ]);

        // Active Tables
        const activeTablesCount = await Table.countDocuments({ status: { $in: ['Running', 'Paused', 'Time Over'] } });

        res.json({
            revenue,
            tableUtilization,
            staffPerformance,
            peakHours,
            activeTablesCount
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Seed/Initialize Slot-Based Pricing
router.post('/pricing/seed', isAdmin, async (req, res) => {
    try {
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
        res.json({ message: 'Pricing rules initialized successfully', settings });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
