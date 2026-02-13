const GodownInventory = require("../models/GodownInventory");
const Medicine = require("../models/Medicines");
const Godown = require("../models/Godown");


// ================= ADD INVENTORY =================
exports.addInventory = async (req, res) => {
    try {

        const { godown, medicine, quantity, batchNumber, expiryDate } = req.body;

        // Check if already exists
        let inventory = await GodownInventory.findOne({ godown, medicine });

        if (inventory) {
            inventory.quantity += quantity;
            await inventory.save();
        } else {
            inventory = await GodownInventory.create({
                godown,
                medicine,
                quantity,
                batchNumber,
                expiryDate
            });
        }

        res.status(201).json({
            success: true,
            message: "Inventory added successfully",
            inventory
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to add inventory",
            error: error.message
        });
    }
};



// ================= GET ALL INVENTORY =================
exports.getAllInventory = async (req, res) => {
    try {

        const inventory = await GodownInventory.find()
            .populate("godown", "name location")
            .populate("medicine", "name price");

        res.status(200).json({
            success: true,
            count: inventory.length,
            inventory
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to fetch inventory",
            error: error.message
        });
    }
};



// ================= GET INVENTORY BY GODOWN =================
exports.getInventoryByGodown = async (req, res) => {
    try {

        const inventory = await GodownInventory.find({
            godown: req.params.godownId
        })
        .populate("medicine", "name price");

        res.status(200).json({
            success: true,
            inventory
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to fetch godown inventory",
            error: error.message
        });
    }
};



// ================= UPDATE INVENTORY =================
exports.updateInventory = async (req, res) => {
    try {

        const inventory = await GodownInventory.findByIdAndUpdate(
            req.params.id,
            req.body,
            { new: true }
        );

        if (!inventory) {
            return res.status(404).json({
                success: false,
                message: "Inventory not found"
            });
        }

        res.status(200).json({
            success: true,
            message: "Inventory updated",
            inventory
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to update inventory",
            error: error.message
        });
    }
};



// ================= DELETE INVENTORY =================
exports.deleteInventory = async (req, res) => {
    try {

        const inventory = await GodownInventory.findByIdAndDelete(req.params.id);

        if (!inventory) {
            return res.status(404).json({
                success: false,
                message: "Inventory not found"
            });
        }

        res.status(200).json({
            success: true,
            message: "Inventory deleted"
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to delete inventory",
            error: error.message
        });
    }
};
