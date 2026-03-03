const jwt = require("jsonwebtoken");
const User = require("../models/User")

const protect = async (req, res, next) => {
    let token

    if (req.headers.authorization && req.headers.authorization.startsWith("Bearer")) {
        try {
            token = req.headers.authorization.split(" ")[1];

            const decoded = jwt.verify(token, process.env.JWT_SECRET);

            req.user = await User.findById(decoded.id).select("-password");

            next();
        }
        catch (error) {
            res.status(401).json({
                success: false,
                message: "Not Authorized, token failed",
            });
        }
    }

    if (!token) {
        res.status(401).json({
            success: false,
            message: "Not authorized, no token",
        });
    }
};

const authorize = (...roles) => {
    return (req, res, next) => {
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                message: "Access Denied",
            });
        }
        next();
    };
};

// Optional protect: sets req.user if token is present & valid, otherwise continues as guest
const optionalProtect = async (req, res, next) => {
    if (req.headers.authorization && req.headers.authorization.startsWith("Bearer")) {
        try {
            const token = req.headers.authorization.split(" ")[1];
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            req.user = await User.findById(decoded.id).select("-password");
        } catch (error) {
            // Token invalid - treat as guest, don't block
            req.user = null;
        }
    } else {
        req.user = null;
    }
    next();
};

module.exports = { protect, authorize, optionalProtect };