const mongoose = require("mongoose");

// A lightweight order model that works without pharmacy/godown setup.
// Stores cart items from the frontend directly.
const simpleOrderSchema = new mongoose.Schema(
    {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
        },
        items: [
            {
                medicineId: { type: String }, // optional — may or may not be a valid ObjectId
                name: { type: String, required: true },
                quantity: { type: Number, required: true, min: 1 },
                price: { type: Number, required: true },
            },
        ],
        totalAmount: { type: Number, required: true },
        deliveryAddress: { type: String, required: true },
        paymentMethod: { type: String, default: "COD" },
        orderStatus: {
            type: String,
            enum: ["placed", "confirmed", "out_for_delivery", "delivered", "cancelled"],
            default: "placed",
        },
        estimatedDelivery: { type: String, default: "15–30 minutes" },
    },
    { timestamps: true }
);

module.exports = mongoose.model("SimpleOrder", simpleOrderSchema);
