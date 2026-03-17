const Medicine = require('../models/Medicines');
const GodownInventory = require('../models/GodownInventory');
const { isPrescriptionRequired } = require("../utils/medicine.utils");
const uploadToCloudinary = require("../utils/uploadToCloudinary");


exports.getAllMedicines = async (req, res) => {
    try {
        const medicines = await Medicine.find({ isAvailable: true })

        res.status(200).json({
            success: true,
            count: medicines.length,
            medicines,
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to fetch medicines !!",
            error: error.message,
        });
    }
};

exports.getMedicineById = async (req, res) => {
    try {
        const medicine = await Medicine.findById(req.params.id);

        if (!medicine) {
            return res.status(404).json({
                success: false,
                message: "Medicine not found"
            });
        }

        res.status(200).json({
            success: true,
            medicine
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to fetch medicine details",
            error: error.message
        });
    }
};

exports.searchMedicines = async (req, res) => {
    try {
        const { keyword, lat, lng } = req.query;

        if (!keyword) {
            return res.status(200).json({ success: true, results: 0, medicines: [] });
        }

        // Use a case-insensitive regex pattern for names
        const regexPattern = new RegExp(keyword, "i");

        // For type matching, replace spaces with .* to handle "pain killer" -> "PAINKILLER"
        const typeRegexPattern = new RegExp(keyword.split(/\s+/).join(".*"), "i");

        // Base query
        const query = {
            isAvailable: true,
            $or: [
                { name: regexPattern },
                { type: typeRegexPattern }
            ]
        };

        // --- Geographic Filter Pipeline ---
        let finalQuery = { ...query };

        if (lat && lng) {
            const latitude = parseFloat(lat);
            const longitude = parseFloat(lng);

            // Determine search radius based on emergency mode
            const { emergencyMode } = req.query;
            const searchRadiusKm = (emergencyMode === 'true') ? 500 : 5;

            // 1. Find Godowns within radius
            const Godown = require("../models/Godown");
            const nearbyGodowns = await Godown.find({
                isActive: true,
                location: {
                    $geoWithin: {
                        $centerSphere: [[longitude, latitude], searchRadiusKm / 6378.1] // radius in radians
                    }
                }
            });

            // If no godowns nearby, trigger noService
            if (!nearbyGodowns || nearbyGodowns.length === 0) {
                return res.status(200).json({
                    success: false,
                    noService: true,
                    message: "No godowns available for your location.",
                    results: 0,
                    medicines: []
                });
            }

            // Extract Godown IDs
            const nearbyGodownIds = nearbyGodowns.map(g => g._id);

            // 2. Find Medicines specifically inside these Godowns that have Active Stock (> 0)
            const GodownInventory = require("../models/GodownInventory");
            const activeInventory = await GodownInventory.find({
                godown: { $in: nearbyGodownIds },
                stock: { $gt: 0 } // Only if they actually have it on hand
            }).select('product');

            // Map purely to distinct medicine IDs
            const availableMedicineIds = [...new Set(activeInventory.map(inv => inv.product.toString()))];

            // 3. Inject strict ID constraints onto our Medicine query
            finalQuery._id = { $in: availableMedicineIds };
        }
        // --- End Geographic Pipeline ---

        const medicines = await Medicine.find(finalQuery).populate("pharmacy", "name address");

        // If not in emergency mode, and we found NO medicines matching the query in the nearby godowns, 
        // prompt the frontend to ask the user to expand the radius.
        const { emergencyMode } = req.query;
        if (medicines.length === 0 && emergencyMode !== 'true' && lat && lng) {
            return res.status(200).json({
                success: false,
                noService: true,
                message: "This medicine is not available within your normal delivery area.",
                results: 0,
                medicines: []
            });
        }

        // Only return success true if we actually have standard results or aren't blocked by noService
        res.status(200).json({
            success: true,
            results: medicines.length,
            medicines,
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Search Failed",
            error: error.message,
        });
    }
};

exports.addMedicine = async (req, res) => {
    try {
        const { godownId, ...medicineData } = req.body;

        // Handle image: either uploaded file (multipart) or URL string in body
        if (req.file) {
            const result = await uploadToCloudinary(req.file.buffer);
            medicineData.image = result.secure_url;
        } else if (!medicineData.image) {
            medicineData.image = "";
        }

        const medicine = await Medicine.create(medicineData);

        if (godownId) {
            await GodownInventory.create({
                godown: godownId,
                product: medicine._id,
                stock: medicine.stock || 0
            });
        }

        res.status(201).json({
            success: true,
            message: "Medicine Added Successfully",
            medicine
        });

    } catch (error) {
        console.error("[addMedicine] Error:", error.message);
        res.status(500).json({
            success: false,
            message: "Failed to add medicine",
            error: error.message
        });
    }
};



