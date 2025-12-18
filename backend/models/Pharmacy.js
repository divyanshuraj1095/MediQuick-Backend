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
            

        }
    }
)