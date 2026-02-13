const Order = require("../models/Order");
const Medicine = require("../models/Medicines");
const Pharmacy = require("../models/Pharmacy");
const GodownInventory = require("../models/GodownInventory");


// Distance utility (Haversine or your custom)
const { getDistance } = require("../utils/distance.utils");

exports.createOrder = async (req, res) => {
    try {

        const { items, deliveryAddress, paymentMethod } = req.body;

        if (!items || items.length === 0) {
            return res.status(400).json({
                success: false,
                message: "Order items required"
            });
        }

        if (!deliveryAddress) {
            return res.status(400).json({
                success: false,
                message: "Delivery address required"
            });
        }

        // ⭐ User Location (MUST exist in user model or request)
        const userLat = req.user.location?.lat;
        const userLng = req.user.location?.lng;

        if (!userLat || !userLng) {
            return res.status(400).json({
                success: false,
                message: "User location not available"
            });
        }

        let totalAmount = 0;
        let processedItems = [];

        // 🔥 Process each item
        for (let item of items) {

            // 1️⃣ Check Medicine Exists
            const medicine = await Medicine.findById(item.medicine);

            if (!medicine) {
                return res.status(404).json({
                    success: false,
                    message: "Medicine not found"
                });
            }

            // 2️⃣ Find All Godowns Having Stock
            const inventories = await GodownInventory.find({
                medicine: item.medicine,
                quantity: { $gte: item.quantity }
            }).populate("godown");

            if (!inventories.length) {
                return res.status(400).json({
                    success: false,
                    message: `${medicine.name} unavailable or insufficient stock`
                });
            }

            // 3️⃣ Find Nearest Godown
            let selectedInventory = null;
            let minDistance = Infinity;

            for (let inv of inventories) {

                if (!inv.godown?.location) continue;

                const distance = getDistance(
                    userLat,
                    userLng,
                    inv.godown.location.lat,
                    inv.godown.location.lng
                );

                if (distance < minDistance) {
                    minDistance = distance;
                    selectedInventory = inv;
                }
            }

            if (!selectedInventory) {
                return res.status(400).json({
                    success: false,
                    message: "No godown found near user"
                });
            }

            // 4️⃣ Atomic Stock Deduction (VERY IMPORTANT)
            const updatedInventory = await GodownInventory.findOneAndUpdate(
                {
                    _id: selectedInventory._id,
                    quantity: { $gte: item.quantity }
                },
                {
                    $inc: { quantity: -item.quantity }
                },
                { new: true }
            );

            if (!updatedInventory) {
                return res.status(400).json({
                    success: false,
                    message: "Stock changed. Please retry."
                });
            }

            // 5️⃣ Calculate Total
            totalAmount += medicine.price * item.quantity;

            // 6️⃣ Add To Order Items
            processedItems.push({
                medicine: medicine._id,
                quantity: item.quantity,
                price: medicine.price,
                godown: updatedInventory.godown
            });
        }

        // ⭐ Create Final Order
        const order = await Order.create({
            user: req.user._id,
            items: processedItems,
            deliveryAddress,
            paymentMethod,
            totalAmount
        });

        res.status(201).json({
            success: true,
            message: "Order placed successfully",
            order
        });

    } catch (error) {

        console.error("Create Order Error:", error);

        res.status(500).json({
            success: false,
            message: "Order creation failed",
            error: error.message
        });
    }
};



// ================= GET MY ORDERS =================
exports.getMyOrders = async (req, res) => {
    try {

        const orders = await Order.find({ user: req.user.id })
            .populate("items.medicine", "name price")
            .populate("items.godown", "name location")
            .sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            count: orders.length,
            orders
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to fetch orders",
            error: error.message
        });
    }
};



// ================= GET ORDER BY ID =================
exports.getOrderById = async (req, res) => {
    try {

        const order = await Order.findById(req.params.id)
            .populate("user", "name email")
            .populate("items.medicine", "name price")
            .populate("items.godown", "name location");

        if (!order) {
            return res.status(404).json({
                success: false,
                message: "Order not found"
            });
        }

        res.status(200).json({
            success: true,
            order
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to fetch order",
            error: error.message
        });
    }
};



// ================= UPDATE ORDER STATUS =================
exports.userOrderStatus = async (req, res) => {
    try {

        const { status } = req.body;

        const order = await Order.findByIdAndUpdate(
            req.params.id,
            { orderStatus: status },
            { new: true }
        );

        if (!order) {
            return res.status(404).json({
                success: false,
                message: "Order not found"
            });
        }

        res.status(200).json({
            success: true,
            message: "Order status updated"
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to update order",
            error: error.message
        });
    }
};



// ================= CANCEL ORDER =================
exports.cancelOrder = async (req, res) => {
    try {

        const order = await Order.findById(req.params.id);

        if (!order) {
            return res.status(404).json({
                success: false,
                message: "Order not found"
            });
        }

        if (order.user.toString() !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: "Not authorized to cancel this order"
            });
        }

        if (order.orderStatus === "delivered") {
            return res.status(400).json({
                success: false,
                message: "Delivered orders cannot be cancelled"
            });
        }

        // ⭐ Restore Stock To Godown Inventory
        for (let item of order.items) {

            const inventory = await GodownInventory.findOne({
                medicine: item.medicine,
                godown: item.godown
            });

            if (inventory) {
                inventory.quantity += item.quantity;
                await inventory.save();
            }
        }

        order.orderStatus = "cancelled";
        await order.save();

        res.status(200).json({
            success: true,
            message: "Order cancelled successfully"
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to cancel order",
            error: error.message
        });
    }
};
