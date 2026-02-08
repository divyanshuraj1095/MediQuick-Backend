const prescriptionService = require("../services/prescriptionSearchService");


// ⭐ Dummy AI Medicine Extractor (Replace Later)
const extractMedicinesFromImage = async (imageBuffer) => {

    // For now simulate AI extraction
    // Later replace with OCR / AI model

    return [
        "paracetamol",
        "azithromycin"
    ];
};


exports.processPrescriptionImage = async (req, res) => {

    try {

        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: "Prescription image required"
            });
        }

        // ⭐ Step 1 — Get image buffer
        const imageBuffer = req.file.buffer;

        // ⭐ Step 2 — Extract medicine names (AI placeholder)
        const extractedMedicines = await extractMedicinesFromImage(imageBuffer);

        // ⭐ Step 3 — Call your search service
        const result = await prescriptionService.searchPrescriptionMedicines(
            extractedMedicines
        );

        res.json({
            success: true,
            extractedMedicines,
            data: result
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: "Server Error"
        });
    }
};
