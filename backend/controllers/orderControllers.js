const Order = require("../models/Order");
const Medicine = require("../models/Medicines");
const Pharmacy = require("../models/Pharmacy");

exports.createOrder = async(req, res) =>{
    try {
        const {pharmacy, items, deliveryAddress, paymentMethod} = req.body;

        let totalAmount = 0;
        for(let item of items){
            const medicine = await Medicine.findById(item.medicine);

            if(!medicine || medicine.stock < item.quantity){
                return res.status(400).json({
                    success : false,
                    message : `Medicine unavailable or insufficient stock`,
                });
            }
            totalAmount += medicine.price*item.quantity;
        }

        const order = await Order.create({
            user : req.user.id,
            pharmacy,
            items,
            deliveryAddress,
            paymentMethod,
            totalAmount,
        });
        for(let item of items){
            await Medicine.findByIdAndUpdate(item.medicine, {
                $inc : {stock : -item.quantity},
            });
        }
        res.status(201).json({
            success : true,
            message : "Order placed Successfully",
            order,

        });
    }catch(error){
        res.status(500).json({
            success : false,
            message : "Order creation failed",
            error : error.message,
        });
    }
};

exports.getMyOrders = async(req, res) =>{
    try {
        const orders = await Order.find({user : req.user.id})
        .populate("items.medicine", "name price")
        .sort({createdAt : -1});

        res.status(200).json({
            success : true,
            count : orders.length, 
            orders,
        });
    }catch(error){
        res.status(500).json({
            success : false,
            message : "failed to fetch orders",
            error : error.message,
        });
    }
};

exports.getOrderById = async(req, res) =>{
    try{
        const order = await Order.findById(req.params.id)
        .populate("user", "name email")
        .populate("items.medicine", "name price");

        if(!order){
            return res.status(404).json({
                success : false,
                message : "Order not found",
            });
        }
        res.status(200).json({
            success : true,
            order,
        });
    }catch(error){
        res.status(500).json({
            success : false,
            message : "failed to fetch order",
            error : error.message,
        });
    }
};

exports.userOrderStatus = async(req, res) =>{
    try {
        const {status} = req.body;
        const order = await Order.findByIdAndUpdate(
            req.params.id,
            {orderStatus : status},
            {new : true}
        );

        if(!order){
            return res.status(404).json({
                success : false,
                message : "Order not found",
            });
        }

        res.status(200).json({
            success : true,
            message : "order status updated",
        })

    }catch(error){
        res.status(500).json({
          success : false,
          message : "failed to update order",
          error : error.message,
        });
    }
};