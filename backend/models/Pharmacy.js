const mongoose = require('mongoose');

const pharmacySchema = new mongoose.Schema(
    {
        name : {
            type : String,
            required : true,
            trim : true,
        },
        phone : {
            type : String,
            required : [true, "phone number is required!!"],
        },
        owner : {
            type : mongoose.Schema.Types.ObjectId,
            ref : "User",
            required : true,
        },
        location : {
            type : {
                type : String,
                enum : ["Point"],
                default : "Point",
            },
            coordinates : {
                type : [Number],
                required : true,
            },
        },
        isOpen : {
            type : Boolean,
            default : true,
        },
        deliveryRadiusKm : {
            type : Number,
            default : 5,
        },
        createdAt : {
            type : Date,
            default : Date.now,
        },
    },
    {timestamps : true}
);

pharmacySchema.index({location : "2dsphere"});
module.exports = mongoose.model("Pharmacy", pharmacySchema);