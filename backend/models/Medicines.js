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
            enum: ["COMMON", "PRESCRIPTION"],
            required : true,
            default: "COMMON"
        },
        drugSchedule: {
            type: String,
            enum: ["OTC", "H", "H1", "X"],
            default: "OTC"
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
        saltComposition : {
            type : String,
            index : true
        },
        alternatives : [
            {
               type : mongoose.Schema.Types.ObjectId,
               ref : "Medicine"
            }
]
    },
    {timestamps : true}
);
medicineSchema.index({ name: "text", saltComposition: "text" });
module.exports = mongoose.model("Medicine", medicineSchema);

