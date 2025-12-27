const express = require("express");

const {search} = require("../controllers/searchControllers");

const router = express.Router();

router.get("/", search);

module.exports = router;