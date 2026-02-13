const mongoose = require("mongoose");

const godownSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },

    code: {
      type: String,
      unique: true, // e.g. KOC_GD_01
    },

    location: {
      type: {
        type: String,
        enum: ["Point"],
        default: "Point",
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        required: true,
      },
    },

    address: {
      type: String,
    },

    servicePincodes: [
      {
        type: String,
      },
    ],

    isActive: {
      type: Boolean,
      default: true,
    },

    contactNumber: {
      type: String,
    },
    location: {
      lat: Number,
      lng: Number,
    },
    pincodes: [String]

  },
  { timestamps: true }
);

// Geo index (useful if you later mix pincode + distance logic)
godownSchema.index({ location: "2dsphere" });

module.exports = mongoose.model("Godown", godownSchema);
