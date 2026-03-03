const express = require("express");
const {
    getAllMedicines,
    searchMedicines,
    addMedicine,
    getMedicineById
} = require("../controllers/medicineControllers");
const upload = require("../middlewares/uploadMiddleware");


const router = express.Router();

router.get("/getmeds", getAllMedicines);

router.get("/search", searchMedicines);

router.get("/:id", getMedicineById);

router.post("/", upload.single("image"), addMedicine);


module.exports = router;