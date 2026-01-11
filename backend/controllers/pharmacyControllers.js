const Pharmacy = require("../models/Pharmacy")

exports.getNearbyPharmacy = async(req, res)=>{
    try{
        const {lat, lng} = req.query;

        const pharmacies = await Pharmacy.find({
            location: {
                $near: {
                    $geometry: {
                        type: "Point",
                        coordinates: [parseFloat(lng), parseFloat(lat)],
                    },
                    $maxDistance: 5000
                }
            },
            isOpen : true

        });
        res.json({
            success : true,
            count : pharmacies.length,
            pharmacies
        }); 
    }
    catch(error){
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
};

exports.addPharmacy = async(req,res)=>{
    try {
        const {name, phone, location, deliveryRadiusKm} = req.body;

        const pharmacy = await Pharmacy.create({
            name,
            phone,
            owner : req.user.id,
            location,
            deliveryRadiusKm
        })

        res.status(201).json({
            success : true,
            message : "pharmacy added successfully",
            pharmacy
        });
    }
    catch(error){
        res.status(400).json({
            success: false,
            message : error.message
        }); 
    }
};