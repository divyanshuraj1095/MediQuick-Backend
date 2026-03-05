const express = require("express");

const { registerUser, loginUser, updateAddress, adminLogin } = require("../controllers/authControllers");

const { protect } = require("../middlewares/authMiddleware");

const router = express.Router();

router.post("/register", registerUser);
// router.post("/register", (req, res) => {
//   res.send("REGISTER ROUTE WORKING");
// });


router.post("/login", loginUser);

router.put("/address", protect, updateAddress);

router.post("/admin-login", adminLogin);

module.exports = router;

