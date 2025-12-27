const User = require("../models/User");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

exports.registerUser = async(req, res) =>{
    try {
        const {name, email, password, role} = req.body;
        if(!name || !email || !password){
            return res.status(400).json({
                success : false,
                message : "All fields are required !!",
            });
        }
        const existingUser = await User.findOne({email});
        if(existingUser){
            return res.status(400).json({
                success : false,
                message : "User already exists",
            });
        }
        // const salt = await bcrypt.genSalt(10);
        // const hashedPassword = await bcrypt.hash(password, salt);

        const user = await User.create({
            name,
            email, 
            password,
            role,
        });

        const token = jwt.sign(
            {id : user._id, role : user.role},
            process.env.JWT_SECRET,
            {expiresIn : "7d"}
        );
        res.status(201).json({
            success : true,
            message : "User Registered Successfully !!",
            token,
            user : {
                id : user._id,
                name : user.name,
                email : user.email,
                role : user.role,
            },
        });
    }catch(error){
        res.status(500).json({
            success : false,
            message : "Registration failed !!",
            error : error.message,
        });
    }
};

exports.loginUser = async(req, res) =>{
    try {
        const {email, password} = req.body
        if(!email || !password){
            return res.status(400).json({
                success : false,
                message : "Email and password are required !!",
            });
        }
        const user = await User.findOne({email}).select('+password');
        if(!user){
          return res.status(400).json({
            success : false,
            message : "Invalid email or password",
          });
        }
        console.log("LOGIN password:", password);
        console.log("HASH from DB:", user.password);

        const isMatch = await bcrypt.compare(password, user.password);
        if(!isMatch){
            return res.status(400).json({
                success : false,
                message : "Invaild email or password",
            });
        }

        const token = jwt.sign(
            {id : user._id, role : user.role},
            process.env.JWT_SECRET,
            {expiresIn : "7d"}
        );

        res.status(200).json({
            success : true,
            message : "Loggin successful",
            token,
            user : {
                id : user._id,
                name : user.name,
                email : user.email,
                role : user.role,
            },
        });
            
    }catch(error){
        res.status(500).json({
            success : false,
            message : "Loggin failed",
            error : error.message,
        });
    }
};
