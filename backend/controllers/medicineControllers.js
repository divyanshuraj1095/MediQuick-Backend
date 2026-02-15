const Medicine = require('../models/Medicines');
const { isPrescriptionRequired } = require("../utils/medicine.utils");
const uploadToCloudinary = require("../utils/uploadToCloudinary");


exports.getAllMedicines = async (req, res) =>{
    try {
        const medicines = await Medicine.find({isAvailable : true})

        res.status(200).json({
            success : true,
            count : medicines.length,
            medicines,
        });
    }catch(error) {
        res.status(500).json({
            success : false,
            message : "Failed to fetch medicines !!",
            error : error.message,
        });
    }
};

exports.searchMedicines = async (req, res) =>{
    try {
        const {keyword} = req.query;
        const medicines = await Medicine.find({
            name : {$regex : keyword, $options : "i"},
            isAvailable : true,
        }).populate("pharmacy","name address");

        res.status(200).json({
            success : true,
            results : medicines.length,
            medicines,
        });
    }catch(error){
        res.status(500).json({
            success : false,
            message : "Search Failed",
            error : error.message,
        });
    }
};

exports.addMedicine = async (req, res) => {
    try {

        let imageUrl = "";

        // Upload image if exists
        if (req.file) {
            const result = await uploadToCloudinary(req.file.buffer);
            imageUrl = result.secure_url;
        }

        const medicine = await Medicine.create({
            ...req.body,
            image: imageUrl
        });

        res.status(201).json({
            success: true,
            message: "Medicine Added Successfully",
            medicine
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to add medicine",
            error: error.message
        });
    }
};


