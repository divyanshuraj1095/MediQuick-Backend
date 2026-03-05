const User = require('../models/User');
const Order = require('../models/Order');
const Medicine = require('../models/Medicines');
const SimpleOrder = require('../models/SimpleOrder');
const Godown = require('../models/Godown');

// ── Dashboard Stats ──────────────────────────────────────────────────────────
exports.getAdminStats = async (req, res) => {
    try {
        const [totalUsers, totalOrders, totalMedicines, totalSimpleOrders, totalGodowns] = await Promise.all([
            User.countDocuments({ role: 'user' }),
            Order.countDocuments(),
            Medicine.countDocuments({ isAvailable: true }),
            SimpleOrder.countDocuments(),
            Godown.countDocuments(),
        ]);

        res.status(200).json({
            success: true,
            stats: {
                totalUsers,
                totalOrders: totalOrders + totalSimpleOrders,
                totalMedicines,
                totalGodowns,
            },
        });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Failed to fetch admin stats', error: error.message });
    }
};

// ── Users ────────────────────────────────────────────────────────────────────
exports.getAllUsers = async (req, res) => {
    try {
        const users = await User.find({ role: 'user' }).select('-password').sort({ createdAt: -1 });
        res.status(200).json({ success: true, count: users.length, users });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Failed to fetch users', error: error.message });
    }
};

// ── Godowns ──────────────────────────────────────────────────────────────────
exports.getGodowns = async (req, res) => {
    try {
        const godowns = await Godown.find().sort({ createdAt: -1 });
        res.status(200).json({ success: true, count: godowns.length, godowns });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Failed to fetch godowns', error: error.message });
    }
};

exports.updateGodown = async (req, res) => {
    try {
        const godown = await Godown.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
        if (!godown) return res.status(404).json({ success: false, message: 'Godown not found' });
        res.status(200).json({ success: true, message: 'Godown updated successfully', godown });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Failed to update godown', error: error.message });
    }
};

exports.deleteGodown = async (req, res) => {
    try {
        const godown = await Godown.findByIdAndDelete(req.params.id);
        if (!godown) return res.status(404).json({ success: false, message: 'Godown not found' });
        res.status(200).json({ success: true, message: 'Godown deleted successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Failed to delete godown', error: error.message });
    }
};
