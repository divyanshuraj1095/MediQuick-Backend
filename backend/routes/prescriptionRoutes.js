const express = require("express");
const router = express.Router();

const prescriptionController = require("../controllers/prescriptionController");
const upload = require("../middlewares/uploadMiddleware");

router.post(
   "/upload",
   upload.single("prescription"),
   prescriptionController.processPrescriptionImage
);

module.exports = router;
