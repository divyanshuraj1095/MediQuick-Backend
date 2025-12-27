const express = require("express");
const {
    getAllMedicines,
    searchMedicines,
    addMedicine} = require("../controllers/medicineControllers");

const router = express.Router();

router.get("/getmeds", getAllMedicines);

router.get("/search", searchMedicines);

router.post("/addmeds", addMedicine);

module.exports = router;