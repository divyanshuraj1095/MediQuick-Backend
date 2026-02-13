const mongoose = require("mongoose");

const godownInventorySchema = new mongoose.Schema(
  {
    godown: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Godown",
      required: true,
      index: true,
    },

    product: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Product", // or Medicine (based on your repo)
      required: true,
      index: true,
    },

    stock: {
      type: Number,
      required: true,
      default: 0,
      min: 0,
    },

    reservedStock: {
      type: Number,
      default: 0,
      min: 0,
    },

    reorderLevel: {
      type: Number,
      default: 10, // Alert threshold
    },

    lastRestockedAt: {
      type: Date,
    },
  },
  { timestamps: true }
);

// Prevent duplicate product entry per godown
godownInventorySchema.index({ godown: 1, product: 1 }, { unique: true });

module.exports = mongoose.model("GodownInventory", godownInventorySchema);
