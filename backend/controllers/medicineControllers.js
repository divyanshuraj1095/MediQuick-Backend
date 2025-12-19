const Medicine = require('../models/Medicines');

exports.getAllMedicines = async (req, res) =>{
    try {
        const medicines = await Medicine.find({isAvailable : true})
        .populate("pharmacy", "name address");

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

exports.addMedicine = async(req, res)=>{
    try{
        const medicine = await Medicine.create(req.body);
        res.status(210).json({
            success : true,
            message : "Medicine Added successfully!!",
            medicine,
        }); 
    }catch(error){
        res.status(400).json({
            success : failed,
            message : "Failed to add mwdicine !!",
            error : error.message,
        });
    }
};

