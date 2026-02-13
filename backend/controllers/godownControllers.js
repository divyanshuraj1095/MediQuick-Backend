const Godown = require("../models/Godown");


// ================= CREATE GODOWN =================
exports.createGodown = async (req, res) => {
    try {

        const godown = await Godown.create(req.body);

        res.status(201).json({
            success: true,
            message: "Godown created successfully",
            godown
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to create godown",
            error: error.message
        });
    }
};



// ================= GET ALL GODOWNS =================
exports.getAllGodowns = async (req, res) => {
    try {

        const godowns = await Godown.find();

        res.status(200).json({
            success: true,
            count: godowns.length,
            godowns
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to fetch godowns",
            error: error.message
        });
    }
};



// ================= GET GODOWN BY ID =================
exports.getGodownById = async (req, res) => {
    try {

        const godown = await Godown.findById(req.params.id);

        if (!godown) {
            return res.status(404).json({
                success: false,
                message: "Godown not found"
            });
        }

        res.status(200).json({
            success: true,
            godown
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to fetch godown",
            error: error.message
        });
    }
};



// ================= UPDATE GODOWN =================
exports.updateGodown = async (req, res) => {
    try {

        const godown = await Godown.findByIdAndUpdate(
            req.params.id,
            req.body,
            { new: true }
        );

        if (!godown) {
            return res.status(404).json({
                success: false,
                message: "Godown not found"
            });
        }

        res.status(200).json({
            success: true,
            message: "Godown updated successfully",
            godown
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to update godown",
            error: error.message
        });
    }
};



// ================= DELETE GODOWN =================
exports.deleteGodown = async (req, res) => {
    try {

        const godown = await Godown.findByIdAndDelete(req.params.id);

        if (!godown) {
            return res.status(404).json({
                success: false,
                message: "Godown not found"
            });
        }

        res.status(200).json({
            success: true,
            message: "Godown deleted successfully"
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to delete godown",
            error: error.message
        });
    }
};
