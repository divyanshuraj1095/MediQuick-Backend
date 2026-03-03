const SimpleOrder = require("../models/SimpleOrder");

// POST /api/simple-order  — create order from cart items
exports.createSimpleOrder = async (req, res) => {
    try {
        const { items, deliveryAddress, paymentMethod } = req.body;

        if (!items || items.length === 0) {
            return res.status(400).json({ success: false, message: "Cart is empty" });
        }
        if (!deliveryAddress || deliveryAddress.trim() === "") {
            return res.status(400).json({ success: false, message: "Delivery address required" });
        }

        const processedItems = items.map((item) => ({
            medicineId: item.id || item.medicineId || null,
            name: item.name || "Unknown Medicine",
            quantity: Math.max(1, parseInt(item.quantity) || 1),
            price: parseFloat(item.price) || 0,
        }));

        const totalAmount = processedItems.reduce(
            (sum, item) => sum + item.price * item.quantity,
            0
        );

        const order = await SimpleOrder.create({
            user: req.user._id,
            items: processedItems,
            totalAmount,
            deliveryAddress: deliveryAddress.trim(),
            paymentMethod: paymentMethod || "COD",
            estimatedDelivery: "15–30 minutes",
        });

        return res.status(201).json({
            success: true,
            message: "Order placed successfully",
            orderId: order._id.toString(),
            order,
        });
    } catch (error) {
        console.error("SimpleOrder Error:", error.message);
        return res.status(500).json({ success: false, message: "Order creation failed" });
    }
};

// GET /api/simple-order/myorders — get current user's orders
exports.getMySimpleOrders = async (req, res) => {
    try {
        const orders = await SimpleOrder.find({ user: req.user._id })
            .sort({ createdAt: -1 })
            .lean();

        return res.json({ success: true, orders });
    } catch (error) {
        console.error("GetOrders Error:", error.message);
        return res.status(500).json({ success: false, message: "Failed to fetch orders" });
    }
};
