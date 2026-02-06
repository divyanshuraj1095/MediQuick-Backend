const mongoose = require("mongoose");

const productSchema = new mongoose.Schema({
  name: { type: String, required: true },
  genericName: { type: String, required: true },
  saltComposition: [String],
  strength: String,
  stock: { type: Number, default: 0 }
});

module.exports = mongoose.model("Product", productSchema);
