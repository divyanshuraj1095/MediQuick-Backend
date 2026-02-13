const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('./config/db.js');

dotenv.config();
connectDB();
const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/auth", require("./routes/auth.js"));
app.use("/api/medicine", require("./routes/medicine.js"));
app.use("/api/order", require("./routes/orders.js"));
app.use("/api/pharmacies", require("./routes/pharmacy.js"));
app.use("/api/searchmed", require("./routes/search.js"));
app.use("/api/prescription", require("./routes/prescriptionRoutes.js"));
app.use("/api/cart", require("./routes/cart"));
app.use("/api/godown", require("./routes/godown.js"));




const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));

