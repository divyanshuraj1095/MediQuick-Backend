const Medicine = require("../models/Medicines");
const { isPrescriptionRequired } = require("../utils/medicine.utils");

const blockRestrictedOrder = async (req, res, next) => {
  try {
    const { items, prescriptionId } = req.body;

    if (!items || items.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Order must contain at least one medicine"
      });
    }

    for (let item of items) {
      const medicine = await Medicine.findById(item.medicineId);

      if (!medicine) {
        return res.status(404).json({
          success: false,
          message: "Medicine not found"
        });
      }

      if (isPrescriptionRequired(medicine) && !prescriptionId) {
        return res.status(403).json({
          success: false,
          message: `Prescription required for ${medicine.name}`
        });
      }
    }

    next();
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Order validation failed",
      error: error.message
    });
  }
};

module.exports = {
  blockRestrictedOrder
};
