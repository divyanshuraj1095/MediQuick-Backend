const Cart = require("../models/Cart");
const Medicine = require("../models/Medicines");

exports.addToCart = async (req, res) => {
    try {
        const userId = req.user.id;   // from auth middleware
        const { medicineId, quantity } = req.body;

        if (!medicineId) {
            return res.status(400).json({ message: "Medicine ID required" });
        }

        // Check medicine exists
        const medicine = await Medicine.findById(medicineId);
        if (!medicine) {
            return res.status(404).json({ message: "Medicine not found" });
        }

        // Find user cart
        let cart = await Cart.findOne({ user: userId });

        if (!cart) {
            cart = new Cart({
                user: userId,
                items: []
            });
        }

        // Check if medicine already in cart
        const itemIndex = cart.items.findIndex(
            item => item.medicine.toString() === medicineId
        );

        if (itemIndex > -1) {
            // Already exists → increase quantity
            cart.items[itemIndex].quantity += quantity || 1;
        } else {
            // Add new item
            cart.items.push({
                medicine: medicineId,
                quantity: quantity || 1
            });
        }

        await cart.save();

        res.json({
            success: true,
            message: "Item added to cart",
            cart
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Server Error" });
    }
};
