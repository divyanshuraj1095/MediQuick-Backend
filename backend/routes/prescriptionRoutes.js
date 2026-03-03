const express = require("express");
const router = express.Router();

const prescriptionController = require("../controllers/prescriptionController");
const upload = require("../middlewares/uploadMiddleware");
const { handleUploadError } = require("../middlewares/uploadMiddleware");
const { protect, optionalProtect } = require("../middlewares/authMiddleware");

// POST /api/prescription/upload — works for both logged-in users and guests
router.post(
   "/upload",
   optionalProtect,
   upload.single("prescription"),
   handleUploadError,
   prescriptionController.processPrescriptionImage
);

// GET /api/prescription/history — requires login
router.get("/history", protect, prescriptionController.getPrescriptionHistory);

module.exports = router;
