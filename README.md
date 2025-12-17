# ⚡💊 MediQuick — Quick Commerce Pharmacy Platform

**MediQuick** is a **location-based quick commerce pharmacy application** designed to deliver medicines and healthcare products in **minutes (10–30 mins)** using **nearby inventory**, inspired by Zepto and Blinkit — but focused exclusively on **pharmacy and healthcare**.

This project is built with a **product-first mindset**, emphasizing **speed, real-time availability, and scalable backend architecture**, with future **AI/ML-powered medical assistance**.

---

## 🚀 What Makes MediQuick a Quick Commerce App?

MediQuick is not traditional e-commerce. It is designed around **instant fulfillment**:

* 📍 **Location-based pharmacy selection**
* 🏪 **Nearby inventory only (dark-store model)**
* ⚡ **Instant order processing**
* 📦 **Real-time stock validation**
* ⏱️ **Fast delivery commitment (ETA)**

> If a product cannot be delivered immediately, it is **not shown** to the user.

---

## 🧩 Core Features

### 🔐 Authentication & Users

* User registration & login
* JWT-based secure authentication
* Role-based access (User / Admin)

---

### 🏥 Pharmacies & Inventory (Quick Commerce Core)

* Each pharmacy has:

  * Location (latitude & longitude)
  * Delivery radius (e.g. 3 km)
* Products are tied to **specific nearby pharmacies**
* Only **deliverable products** are visible to the user

---

### 🔍 Ultra-Fast Search

* Real-time medicine search
* Case-insensitive partial matching
* Optimized for quick discovery (sub-second response)

---

### 🛒 Orders & Fulfillment

* Instant order placement
* Order lifecycle:

  ```
  PLACED → CONFIRMED → OUT_FOR_DELIVERY → DELIVERED
  ```
* Real-time order status tracking
* Automatic stock reduction on order confirmation

---

### ⏱️ ETA & Speed Commitment

* Estimated delivery time shown before checkout
* ETA based on:

  * Distance from pharmacy
  * Average delivery speed
  * Packing time
* Designed to support **10–30 minute delivery windows**

---

### 🧠 AI / ML (Planned & Extensible)

* Symptom-based medical recommendation system
* ML-powered medicine suggestions
* Patient description analysis
* Future prescription intelligence

---

## 🛠 Tech Stack

### Backend (Implemented)

* **Node.js**
* **Express.js**
* **MongoDB + Mongoose**
* **JWT Authentication**
* **bcrypt**
* RESTful API architecture

### Frontend (Planned)

* **React.js**
* **Tailwind CSS**
* **Axios**

### Dev & Infrastructure

* Nodemon
* Git & GitHub
* Environment-based configuration
* Cloud-ready architecture

---

## 📁 Project Structure

```
MediQuick/
├── backend/
│   ├── config/
│   │   └── db.js
│   ├── controllers/
│   ├── models/
│   ├── routes/
│   ├── middleware/
│   ├── server.js
│   ├── package.json
│   └── .env
├── frontend/ (planned)
└── README.md
```

---

## ⚙️ Setup Instructions

### 1️⃣ Clone Repository

```bash
git clone git@github.com:divyanshuraj1095/MediQuick.git
```

### 2️⃣ Backend Setup

```bash
cd MediQuick/backend
npm install
```

### 3️⃣ Environment Variables

Create a `.env` file inside `backend/`:

```env
MONGO_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret
PORT=5000
```

### 4️⃣ Run Backend

```bash
npm run dev
```

Backend will run at:

```
http://localhost:5000
```

---

## 🔌 API Capabilities (Sample)

| Method | Endpoint                    | Purpose             |
| ------ | --------------------------- | ------------------- |
| POST   | `/api/auth/register`        | Register user       |
| POST   | `/api/auth/login`           | Login               |
| GET    | `/api/products?search=para` | Fast search         |
| POST   | `/api/orders`               | Place instant order |
| GET    | `/api/orders/user`          | User order history  |

---

## 🎯 Project Vision

MediQuick is designed as a **scalable quick commerce product**, focusing on:

* Real-world backend architecture
* Location-aware delivery systems
* High-speed commerce logic
* Production-ready API design
* Future AI integration

---

## 👨‍💻 Author

**Divyanshu Raj**
GitHub: [https://github.com/divyanshuraj1095](https://github.com/divyanshuraj1095)

---

## 📌 Status

🚧 Actively under development
Upcoming:

* Frontend UI
* AI/ML medical assistant
* Advanced search & caching
* Deployment to cloud
