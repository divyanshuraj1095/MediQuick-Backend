const mongoose = require('mongoose');

const medicineSchema = mongoose.Schema(
    {
        name : {
            type : String,
            required : true,
            trim : true,
            index : true,
        },
        description : {
            type : String,
        },
        category : {
            type : String,
            required : true,
            index : true,
        },
        price : {
            type : Number,
            required : true,
        },
        prescriptionRequired : {
            type : Boolean,
            default : false,
        },
        manufacturer : {
            type : String,
        },
        expiryDate : {
            type : Date,
        },
        pharmacy : {
            type : mongoose.Schema.Types.ObjectId,
            ref : "Pharmacy",
            required : true,
        },
        stock : {
            type : Number,
            required : true,
            min : 0,
        },
        isAvailable : {
            type : Boolean,
            default : true,
        },
    },
    {timestamps : true}
);

module.exports = mongoose.model("Medicine", medicineSchema);

