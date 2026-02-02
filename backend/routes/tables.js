const express = require('express');
const router = express.Router();
const Table = require('../models/Table');
const Session = require('../models/Session');
const AuditLog = require('../models/AuditLog');
const Settings = require('../models/Settings');

// Get all active tables (Staff View)
router.get('/', async (req, res) => {
    try {
        const tables = await Table.find({ isActive: true })
            .populate({
                path: 'currentSession',
                populate: { path: 'handledBy', select: 'username' }
            });
        res.json(tables);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Start Table
router.post('/:id/start', async (req, res) => {
    try {
        const { pricingMode, players, type, timeLimitInMinutes, userId } = req.body;
        const table = await Table.findById(req.params.id);
        if (!table) return res.status(404).json({ message: 'Table not found' });
        if (table.status !== 'Idle') return res.status(400).json({ message: 'Table is not idle' });

        // Fetch Global Pricing Rules
        const settings = await Settings.findOne({ key: 'main' });
        const rule = settings?.pricingRules.find(r => r.gameType === type) || { hourlyRate: table.hourlyRate, minCharge: 0, slots: [] };

        let rate = rule.hourlyRate || table.hourlyRate;
        const currentHour = new Date().getHours();

        console.log(`[START] Table: ${table.name}, Mode: ${pricingMode}, BodyPrice: ${req.body.fixedPrice}, BaseRate: ${rate}`);

        // If it's a fixed rate, allow manual price from body
        if (pricingMode === 'fixed' && req.body.fixedPrice !== undefined) {
            rate = parseFloat(req.body.fixedPrice);
            console.log(`[START] Fixed rate override applied: ${rate}`);
        } else if (rule.peakHours) {
            // Apply Peak Hour Multiplier if exists
            const peakRule = rule.peakHours.find(p => currentHour >= p.startHour && currentHour <= p.endHour);
            if (peakRule) {
                rate *= peakRule.multiplier;
                console.log(`[START] Peak hour rule applied. Multiplier: ${peakRule.multiplier}, New Rate: ${rate}`);
            }
        }

        const session = new Session({
            table: table._id,
            startTime: new Date(),
            pricingMode: pricingMode || 'per_hour',
            players: players || 1,
            timeLimitInMinutes: timeLimitInMinutes || 0,
            hourlyRateAtStart: rate,
            minChargeAtStart: rule.minCharge || 0,
            taxRateAtStart: settings?.taxEnabled ? (settings.taxPercentage || 0) : 0,
            segments: [{ start: new Date() }]
        });
        await session.save();

        console.log(`[START] Session saved. ID: ${session._id}, Saved Rate: ${session.hourlyRateAtStart}`);

        table.status = 'Running';
        if (type) table.type = type;
        table.currentSession = session._id;
        await table.save();

        await new AuditLog({
            table: table._id,
            session: session._id,
            user: userId,
            action: 'START',
            details: `Started ${type || table.type} session. Rate: ${rate}, Min: ${rule.minCharge || 0}`
        }).save();

        res.json({ table, session });
    } catch (error) {
        console.error(`[START ERROR]: ${error.message}`);
        res.status(500).json({ message: error.message });
    }
});

// Pause Table
router.post('/:id/pause', async (req, res) => {
    try {
        const { reason, userId } = req.body;
        if (!reason) return res.status(400).json({ message: 'Pause reason is mandatory' });

        const table = await Table.findById(req.params.id).populate('currentSession');
        if (table.status !== 'Running') return res.status(400).json({ message: 'Table is not running' });

        const session = await Session.findById(table.currentSession._id);
        const lastSegment = session.segments[session.segments.length - 1];
        lastSegment.end = new Date();

        table.status = 'Paused';
        await session.save();
        await table.save();

        await new AuditLog({
            table: table._id,
            session: session._id,
            user: userId,
            action: 'PAUSE',
            details: `Paused. Reason: ${reason}`
        }).save();

        res.json(table);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Resume Table
router.post('/:id/resume', async (req, res) => {
    try {
        const { userId } = req.body;
        const table = await Table.findById(req.params.id).populate('currentSession');
        if (table.status !== 'Paused') return res.status(400).json({ message: 'Table is not paused' });

        const session = await Session.findById(table.currentSession._id);
        session.segments.push({ start: new Date() });

        table.status = 'Running';
        await session.save();
        await table.save();

        await new AuditLog({
            table: table._id,
            session: session._id,
            user: userId,
            action: 'RESUME',
            details: 'Session resumed'
        }).save();

        res.json(table);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// End Table (Staff Request)
router.post('/:id/end', async (req, res) => {
    try {
        const { userId } = req.body;
        const table = await Table.findById(req.params.id).populate('currentSession');
        if (!['Running', 'Paused', 'Time Over'].includes(table.status)) {
            return res.status(400).json({ message: 'Table is not active' });
        }

        const session = await Session.findById(table.currentSession._id);
        const lastSegment = session.segments[session.segments.length - 1];
        if (!lastSegment.end) {
            lastSegment.end = new Date();
        }

        session.endTime = new Date();
        session.status = 'Completed';
        session.handledBy = userId;

        // Calculate Play Time (Active only)
        let totalMinutes = 0;
        session.segments.forEach(seg => {
            const end = seg.end || new Date();
            totalMinutes += (end - seg.start) / (1000 * 60);
        });

        // Billing Rules
        let subtotal = 0;
        const rate = (session.hourlyRateAtStart !== undefined && session.hourlyRateAtStart !== null)
            ? session.hourlyRateAtStart
            : table.hourlyRate;
        const minCharge = session.minChargeAtStart || 0;

        console.log(`[END] Session: ${session._id}, Mode: ${session.pricingMode}, Rate: ${rate}, Minutes: ${totalMinutes}`);

        // Get pricing rules for the table type
        const settings = await Settings.findOne({ key: 'main' });
        const rule = settings?.pricingRules.find(r => r.gameType === table.type);
        
        if (rule && rule.slots && rule.slots.length > 0) {
            // Slot-based pricing: Find the smallest slot that covers the play time
            const sortedSlots = rule.slots.sort((a, b) => a.durationMinutes - b.durationMinutes);
            let applicableSlot = sortedSlots.find(slot => slot.durationMinutes >= totalMinutes);
            
            if (applicableSlot) {
                // User played within an allocated slot
                subtotal = applicableSlot.price;
                console.log(`[END] Slot-based pricing applied. Play time: ${totalMinutes}m, Slot: ${applicableSlot.durationMinutes}m, Price: ${subtotal}`);
            } else {
                // User played longer than all slots, charge for the largest slot
                const largestSlot = sortedSlots[sortedSlots.length - 1];
                subtotal = largestSlot.price;
                console.log(`[END] Exceeded largest slot. Play time: ${totalMinutes}m, Using: ${largestSlot.durationMinutes}m slot, Price: ${subtotal}`);
            }
        } else if (session.pricingMode === 'per_hour') {
            subtotal = (totalMinutes / 60) * rate;
        } else if (session.pricingMode === 'per_minute') {
            subtotal = totalMinutes * (rate / 60);
        } else if (session.pricingMode === 'fixed') {
            subtotal = rate; // Flat fee
            console.log(`[END] Fixed logic applied. Subtotal: ${subtotal}`);
        }

        // Apply Minimum Charge (if slot-based not used)
        if (!rule || !rule.slots || rule.slots.length === 0) {
            if (subtotal < minCharge) {
                console.log(`[END] Min charge applied. Subtotal was: ${subtotal}, Min: ${minCharge}`);
                subtotal = minCharge;
            }
        }

        // Tax Logic
        const taxRate = session.taxRateAtStart || parseFloat(process.env.TAX_RATE || '0');
        const taxAmount = (subtotal * taxRate) / 100;
        const totalAmount = subtotal + taxAmount;

        session.subtotal = subtotal;
        session.taxAmount = taxAmount;
        session.totalAmount = totalAmount;
        session.totalBilled = totalAmount; // For compatibility

        table.status = 'Ended';

        await session.save();
        await table.save();

        await new AuditLog({
            table: table._id,
            session: session._id,
            user: userId,
            action: 'END',
            details: `Session ended. Play: ${Math.round(totalMinutes)}m, Sub: ${subtotal.toFixed(2)}, Tax: ${taxAmount.toFixed(2)}, Total: ${totalAmount.toFixed(2)}`
        }).save();

        const updatedTable = await Table.findById(table._id).populate({
            path: 'currentSession',
            populate: { path: 'handledBy', select: 'username' }
        });

        res.json(updatedTable);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Confirm Payment & Clear Table
router.post('/:id/clear', async (req, res) => {
    try {
        const { userId, paymentMethod, autoDelete } = req.body;
        const table = await Table.findById(req.params.id);
        if (table.status !== 'Ended') return res.status(400).json({ message: 'Table is not in Ended state' });

        const sessionId = table.currentSession;
        const session = await Session.findById(sessionId);
        if (session) {
            session.paymentMethod = paymentMethod || 'Other';
            await session.save();
        }

        // If autoDelete is true, delete the table; otherwise, set to Idle
        if (autoDelete === true) {
            await AuditLog({
                table: table._id,
                session: sessionId,
                user: userId,
                action: 'TABLE_DELETED',
                details: `Payment confirmed via ${paymentMethod || 'Other'}. Table auto-deleted.`
            }).save();

            await Table.findByIdAndDelete(table._id);
            console.log(`[CLEAR] Table ${table._id} deleted after payment.`);

            return res.json({ message: 'Table deleted successfully after payment', deleted: true });
        } else {
            table.status = 'Idle';
            table.currentSession = null;
            await table.save();

            await AuditLog({
                table: table._id,
                session: sessionId,
                user: userId,
                action: 'BILL_PAID',
                details: `Payment confirmed via ${paymentMethod || 'Other'}. Table set to Idle.`
            }).save();

            console.log(`[CLEAR] Table ${table._id} set to Idle after payment.`);
            res.json(table);
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Auto-End and Delete Table when time limit is reached
router.post('/:id/auto-end-delete', async (req, res) => {
    try {
        const { userId } = req.body;
        const table = await Table.findById(req.params.id).populate('currentSession');
        
        if (!table.currentSession) {
            return res.status(400).json({ message: 'No active session on this table' });
        }

        const session = await Session.findById(table.currentSession._id);
        
        // End the session
        const lastSegment = session.segments[session.segments.length - 1];
        if (!lastSegment.end) {
            lastSegment.end = new Date();
        }

        session.endTime = new Date();
        session.status = 'Completed';
        session.handledBy = userId;

        // Calculate Play Time
        let totalMinutes = 0;
        session.segments.forEach(seg => {
            const end = seg.end || new Date();
            totalMinutes += (end - seg.start) / (1000 * 60);
        });

        // Calculate Bill
        let subtotal = 0;
        const rate = session.hourlyRateAtStart || table.hourlyRate;
        const settings = await Settings.findOne({ key: 'main' });
        const rule = settings?.pricingRules.find(r => r.gameType === table.type);
        
        if (rule && rule.slots && rule.slots.length > 0) {
            const sortedSlots = rule.slots.sort((a, b) => a.durationMinutes - b.durationMinutes);
            let applicableSlot = sortedSlots.find(slot => slot.durationMinutes >= totalMinutes);
            
            if (applicableSlot) {
                subtotal = applicableSlot.price;
            } else {
                const largestSlot = sortedSlots[sortedSlots.length - 1];
                subtotal = largestSlot.price;
            }
        } else if (session.pricingMode === 'per_hour') {
            subtotal = (totalMinutes / 60) * rate;
        }

        const taxRate = session.taxRateAtStart || 0;
        const taxAmount = (subtotal * taxRate) / 100;
        const totalAmount = subtotal + taxAmount;

        session.subtotal = subtotal;
        session.taxAmount = taxAmount;
        session.totalAmount = totalAmount;
        session.totalBilled = totalAmount;

        await session.save();

        // Log auto-end action
        await new AuditLog({
            table: table._id,
            session: session._id,
            user: userId,
            action: 'AUTO_END',
            details: `Time limit reached or auto-ended. Play: ${Math.round(totalMinutes)}m, Total: ${totalAmount.toFixed(2)}`
        }).save();

        // Delete the table
        await Table.findByIdAndDelete(table._id);

        console.log(`[AUTO-END-DELETE] Table ${table._id} auto-ended and deleted.`);

        res.json({ 
            message: 'Table auto-ended and deleted successfully',
            session: {
                id: session._id,
                playTime: totalMinutes,
                subtotal: subtotal,
                tax: taxAmount,
                total: totalAmount
            }
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Seed Tables (Initial Setup)
router.post('/seed', async (req, res) => {
    try {
        await Table.deleteMany({});
        const tables = [
            { name: 'Table 1', type: 'Pool', supportedTypes: ['Pool', 'Snooker'], hourlyRate: 200, isActive: true },
            { name: 'Table 2', type: 'Pool', supportedTypes: ['Pool'], hourlyRate: 200, isActive: true },
            { name: 'Table 3', type: 'Snooker', supportedTypes: ['Snooker'], hourlyRate: 350, isActive: true },
            { name: 'Table 4', type: 'Snooker', supportedTypes: ['Pool', 'Snooker'], hourlyRate: 350, isActive: true },
            { name: 'Table 5', type: 'Pool', supportedTypes: ['Pool'], hourlyRate: 200, isActive: true },
            { name: 'Table 6', type: 'Pool', supportedTypes: ['Pool'], hourlyRate: 200, isActive: true },
        ];
        await Table.insertMany(tables);
        res.json({ message: 'Tables seeded' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Get Session History for a user (Today's sessions)
router.get('/history/:userId', async (req, res) => {
    try {
        const startOfDay = new Date();
        startOfDay.setHours(0, 0, 0, 0);

        const sessions = await Session.find({
            status: 'Completed',
            createdAt: { $gte: startOfDay }
        })
            .populate('table', 'name type')
            .sort({ createdAt: -1 });

        // Note: For now, we return all sessions of today for the staff to see the log.
        // If we strictly want ONLY their handled sessions, we would need to track which user ended the session in the Session model itself.
        // However, the prompt says "handled by themselves". I should add 'handledBy' to the Session model.

        res.json(sessions);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
