const Medicines = require("../models/Medicines");
const Medicine = require("../models/Medicines");
const Pharmacy = require("../models/Pharmacy");

exports.search = async(req, res) =>{
    try{
        const {keyword, lat, lng} = req.query;

        if(!keyword){
            return res.status(400).json({
                success : false,
                message : "Search keyword is required",
            });
        }

        const medicines = await Medicines.find({
            name : {$regex: keyword, $options: "i"},
            isAvailable : true,
        })
        .populate("pharmacy", "name address location")
        .limit(20);

        const pharmacies = await Pharmacy.find({
            name : {$regex : keyword, $options : "i"},
            
        }).limit(10);

        res.status(200).json({
            success : true,
            results : {
                medicines,
                pharmacies,
            },
        });
    }
    catch(error){
        res.status(500).json({
            success : false,
            message : "search failed",
            error : error.message
        });
    }
};