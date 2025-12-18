const mongoose = require('mongoose');

const connectDB = async() => {
    try {
      const conn = mongoose.connect(process.env.MONGO_URI, {
            useNewUrlParser : true,
            useUnifiedTopology : true,
      });
      console.log(`MongoDB Connected: ${conn.connection.host}`);
    }
    catch(error){
       console.error("MongoDB connection Failed!! : ",error.message),
       process.exit(1);
    }   
}

module.exports = connectDB;