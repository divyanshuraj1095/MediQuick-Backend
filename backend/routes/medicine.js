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

// Accept both multipart (with image) and plain JSON (without image)
router.post("/", (req, res, next) => {
    const contentType = req.headers['content-type'] || '';
    if (contentType.includes('multipart/form-data')) {
        upload.single("image")(req, res, next);
    } else {
        next();
    }
}, addMedicine);

module.exports = router;