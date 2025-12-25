const express = require("express");
const {
    getAllMedicnes,
    searchMedicines,
    addMedicine} = require("../controllers/medicineControllers");

const router = express.Router();

router.get("/getmeds", getAllMedicnes);

router.get("/search", searchMedicines);

router.post("/addmeds", addMedicine);

module.exports = router;