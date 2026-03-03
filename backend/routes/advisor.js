const express = require("express");
const router = express.Router();
const advisorController = require("../controllers/advisorController");

// POST /api/advisor/analyse
router.post("/analyse", advisorController.analyseSymptoms);

module.exports = router;
