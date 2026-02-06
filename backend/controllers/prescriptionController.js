const prescriptionService = require("../services/prescriptionSearchService");

exports.processPrescription = async (req, res) => {

    try {

        const { medicines } = req.body;

        if (!medicines || !Array.isArray(medicines)) {
            return res.status(400).json({
                message: "Medicines array required"
            });
        }

        // ⭐ THIS IS WHERE YOUR SERVICE IS CALLED
        const result = await prescriptionService.searchPrescriptionMedicines(medicines);

        res.json({
            success: true,
            data: result
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({
            message: "Server Error"
        });
    }
};
