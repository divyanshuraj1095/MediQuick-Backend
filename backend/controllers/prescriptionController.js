const prescriptionService = require("../services/prescriptionSearchService");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const Prescription = require("../models/Prescription");
const cloudinary = require("../config/cloudinary");

// Initialize Gemini from environment variable
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

const extractMedicinesFromFile = async (fileBuffer, mimeType) => {
    try {
        const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });

        const prompt = `You are a medical AI assistant. Extract ALL medicine/drug names, dosages, and quantities from this prescription.
Return ONLY a valid JSON array. Do not wrap it in markdown or code blocks.
Each object must have: "name" (string), "dosage" (string), "quantity" (number).
Example: [{"name":"Paracetamol 500mg","dosage":"Twice daily","quantity":10}]
If nothing is found, return [].`;

        const filePart = {
            inlineData: {
                data: fileBuffer.toString("base64"),
                mimeType: mimeType,
            },
        };

        const result = await model.generateContent([prompt, filePart]);
        let responseText = result.response.text().trim();

        // Strip markdown code fences if present
        responseText = responseText
            .replace(/^```json\s*/i, "")
            .replace(/^```\s*/i, "")
            .replace(/```\s*$/i, "")
            .trim();

        const extractedMedicines = JSON.parse(responseText);
        return Array.isArray(extractedMedicines) ? extractedMedicines : [];
    } catch (error) {
        console.error("Gemini AI Error:", error.message);
        return [];
    }
};

// POST /api/prescription/upload
exports.processPrescriptionImage = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: "Prescription file required (jpg, png, or pdf)",
            });
        }

        const fileBuffer = req.file.buffer;
        const mimeType = req.file.mimetype;

        // Step 1: Upload to Cloudinary for storage
        const base64File = `data:${mimeType};base64,${fileBuffer.toString("base64")}`;
        let uploadResult;
        try {
            uploadResult = await cloudinary.uploader.upload(base64File, {
                folder: "prescriptions",
                resource_type: mimeType === "application/pdf" ? "raw" : "image",
            });
        } catch (err) {
            console.warn("Cloudinary Upload Failed:", err.message);
        }
        const fileUrl = uploadResult ? uploadResult.secure_url : null;

        // Step 2: Extract medicines using Gemini AI
        const rawExtractedList = await extractMedicinesFromFile(fileBuffer, mimeType);
        const extractedNames = rawExtractedList.map((m) => m.name);

        // Step 3: Fuzzy-match extracted names against the Medicine database
        const searchResults =
            extractedNames.length > 0
                ? await prescriptionService.searchPrescriptionMedicines(extractedNames)
                : [];

        // Step 4: Compute confidence scores
        const medicinesWithConfidence = rawExtractedList.map((med, idx) => {
            const matchInfo = searchResults[idx];
            const hasMatch = matchInfo && matchInfo.medicines && matchInfo.medicines.length > 0;
            const topScore = hasMatch ? (matchInfo.medicines[0]._score || 0) : 0;

            // Normalize score into 0-100 confidence
            // Max possible score ~240 (exact+salt+pharmacy+stock+OTC)
            const confidence = hasMatch ? Math.min(100, Math.round((topScore / 240) * 100)) : 0;

            return {
                ...med,
                confidence,
            };
        });

        // Step 5: Save to prescription history (only if user is logged in)
        let savedPrescription = null;
        if (req.user) {
            const formattedMeds = medicinesWithConfidence.map((med, idx) => {
                const matchInfo = searchResults[idx];
                const bestMatchId =
                    matchInfo && matchInfo.medicines && matchInfo.medicines.length > 0
                        ? matchInfo.medicines[0]._id
                        : null;
                return {
                    extractedName: med.name,
                    dosage: med.dosage,
                    quantity: med.quantity,
                    matchedMedicineId: bestMatchId,
                    confidenceScore: med.confidence,
                };
            });

            savedPrescription = await Prescription.create({
                user: req.user._id,
                imageUrl: fileUrl || "https://placeholder.com/prescription.jpg",
                verified: extractedNames.length > 0,
                medicines: formattedMeds,
                status: "processed",
            });
        }

        return res.json({
            success: true,
            prescriptionId: savedPrescription ? savedPrescription._id : null,
            verified: extractedNames.length > 0,
            extractedList: medicinesWithConfidence,
            searchResults: searchResults,
        });
    } catch (error) {
        console.error("Prescription Processing Error:", error);
        return res.status(500).json({
            success: false,
            message: "Server error while processing prescription",
            error: error.message,
        });
    }
};

// GET /api/prescription/history  (requires auth)
exports.getPrescriptionHistory = async (req, res) => {
    try {
        const prescriptions = await Prescription.find({ user: req.user._id })
            .sort({ createdAt: -1 })
            .limit(20)
            .populate("medicines.matchedMedicineId", "name price images");

        return res.json({
            success: true,
            prescriptions,
        });
    } catch (error) {
        console.error("Prescription History Error:", error);
        return res.status(500).json({
            success: false,
            message: "Failed to fetch prescription history",
        });
    }
};
