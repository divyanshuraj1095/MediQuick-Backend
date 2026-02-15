const cloudinary = require("../config/cloudinary");
const streamifier = require("streamifier");

const uploadToCloudinary = (buffer) => {
    return new Promise((resolve, reject) => {

        const stream = cloudinary.uploader.upload_stream(
            { folder: "medicines" },
            (error, result) => {
                if (error) reject(error);
                else resolve(result);
            }
        );

        streamifier.createReadStream(buffer).pipe(stream);
    });
};

module.exports = uploadToCloudinary;
