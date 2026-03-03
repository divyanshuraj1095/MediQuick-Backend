const multer = require("multer");

const ALLOWED_TYPES = ["image/jpeg", "image/jpg", "image/png", "application/pdf"];

const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
    if (ALLOWED_TYPES.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new Error("Invalid file type. Only JPG, PNG, and PDF files are accepted."), false);
    }
};

const upload = multer({
    storage,
    limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
    fileFilter,
});

// Handle multer errors gracefully
const handleUploadError = (err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        if (err.code === "LIMIT_FILE_SIZE") {
            return res.status(400).json({ success: false, message: "File too large. Maximum size is 10MB." });
        }
        return res.status(400).json({ success: false, message: `Upload error: ${err.message}` });
    }
    if (err && err.message) {
        return res.status(400).json({ success: false, message: err.message });
    }
    next(err);
};

module.exports = upload;
module.exports.handleUploadError = handleUploadError;
