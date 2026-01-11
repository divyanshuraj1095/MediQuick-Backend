const mongoose = require('mongoose');

const orderSchema = mongoose.Schema(
    {
        user : {
            type : mongoose.Schema.Types.ObjectId,
            ref : "User",
            required : true,
        },
        pharmacy : {
            type : mongoose.Schema.Types.ObjectId,
            ref : "Pharmacy",
            required : true,
        },
        items : [
            {
                medicine : {
                    type : mongoose.Schema.Types.ObjectId,
                    ref : "Medicine",
                    required : true,
                },
                quantity : {
                    type : Number,
                    required : true,
                    min : 1,
                },
                price : {
                    type : Number,
                    required : true,
                },
            },
        ],
        totalAmount : {
            type : Number,
            required : true,
        },
        paymentMethod : {
            type : String,
            enum : ['COD', 'UPI', 'CARD'],
            default : 'COD',
        },
        orderStatus : {
            type : String,
            enum : ["placed", "confirmed", "packed", "out_for_delivery", "delivered", "cancelled"],
            default : "placed",
        },
        deliveryAddress : {
            type : String,
            required : true,
        },
        estimatedDeliveryTime : {
            type : Number,
        },
    },
    {timestamps : true}
);

module.exports = mongoose.model("Order", orderSchema);