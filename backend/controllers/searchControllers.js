const Medicines = require("../models/Medicines");
const Pharmacy = require("../models/Pharmacy");

exports.search = async (req, res) => {
  try {
    const { keyword, lat, lng } = req.query;

    if (!keyword || !lat || !lng) {
      return res.status(400).json({
        success: false,
        message: "keyword, lat and lng are required"
      });
    }

    const userLocation = {
      type: "Point",
      coordinates: [parseFloat(lng), parseFloat(lat)]
    };

    // 1. Find nearby pharmacies first
    const nearbyPharmacies = await Pharmacy.find({
      location: {
        $near: {
          $geometry: userLocation,
          $maxDistance: 5000 // 5km
        }
      },
      isOpen: true
    }).select("_id name location");

    const pharmacyIds = nearbyPharmacies.map(p => p._id);

    // 2. Find medicines only from nearby pharmacies
    const medicines = await Medicines.find({
      name: { $regex: keyword, $options: "i" },
      isAvailable: true,
      pharmacy: { $in: pharmacyIds }
    })
    .populate("pharmacy", "name location")
    .limit(20);

    res.status(200).json({
      success: true,
      count: medicines.length,
      medicines,
      nearbyPharmacies
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Search failed",
      error: error.message
    });
  }
};
