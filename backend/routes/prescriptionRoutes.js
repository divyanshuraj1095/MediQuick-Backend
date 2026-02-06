const express = require("express");
const router = express.Router();

const prescriptionController = require("../controllers/prescriptionController");

router.post("/process", prescriptionController.processPrescription);

module.exports = router;
