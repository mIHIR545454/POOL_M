const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Login Route
router.post('/login', async (req, res) => {
    try {
        const { identifier, password } = req.body; // identifier can be username or mobile

        const user = await User.findOne({
            $or: [{ username: identifier }, { mobile: identifier }]
        });

        if (!user) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        if (!user.isActive) {
            return res.status(403).json({ message: 'Your account has been disabled. Please contact admin.' });
        }

        const isMatch = await user.comparePassword(password);
        if (!isMatch) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        // Update last active
        user.lastActive = new Date();
        await user.save();

        const token = jwt.sign(
            { id: user._id, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: '8h' }
        );

        res.json({
            token,
            user: {
                id: user._id,
                username: user.username,
                role: user.role,
                mobile: user.mobile
            }
        });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

// Seed Admin (Temporary for setup)
router.post('/seed', async (req, res) => {
    try {
        const adminExists = await User.findOne({ role: 'Admin' });
        if (adminExists) return res.status(400).json({ message: 'Admin already exists' });

        const admin = new User({
            username: 'admin',
            password: 'admin123',
            mobile: '1234567890',
            role: 'Admin'
        });

        const staff = new User({
            username: 'staff',
            password: 'staff123',
            mobile: '0987654321',
            role: 'Staff'
        });

        await admin.save();
        await staff.save();

        res.json({ message: 'Users seeded successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Seed failed', error: error.message });
    }
});

module.exports = router;
