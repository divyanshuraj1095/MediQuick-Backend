const express = require('express')
const {getNearbyPharmacy, addPharmacy} = require("../controllers/pharmacyControllers")
const {protect, authorize} = require("../middlewares/authMiddleware")

const router = express.Router();
router.post("/", protect, authorize("pharmacy", "admin"), addPharmacy);
router.get("/nearby",getNearbyPharmacy);

module.exports = router;