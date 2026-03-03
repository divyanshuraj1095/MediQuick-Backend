const mongoose = require('mongoose');

const extractedMedicineSchema = new mongoose.Schema({
    extractedName: { type: String, required: true },
    matchedMedicineId: { type: mongoose.Schema.Types.ObjectId, ref: 'Medicine' },
    dosage: { type: String },
    quantity: { type: Number },
    confidenceScore: { type: Number }
});

const prescriptionSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    imageUrl: { type: String, required: true },
    verified: { type: Boolean, default: false },
    medicines: [extractedMedicineSchema],
    status: { type: String, enum: ['pending', 'processed', 'failed'], default: 'pending' },
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Prescription', prescriptionSchema);
