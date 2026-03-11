# 💊 MediQuick

**MediQuick** is a full-stack medicine delivery platform that allows users to search for medicines based on their location, place orders, scan prescriptions using AI-powered OCR, and track their orders — all within a clean, modern Flutter web app backed by a Node.js/Express API and MongoDB.

---

## 📁 Project Structure

```
MediQuick/
├── backend/                  # Node.js + Express REST API
│   ├── controllers/          # Route handlers (auth, medicines, orders, etc.)
│   ├── models/               # Mongoose schemas
│   ├── routes/               # Express route definitions
│   ├── middlewares/          # Auth protection, order validation
│   ├── utils/                # Cloudinary upload, medicine utilities
│   ├── services/             # AI/ML integrations (Gemini OCR)
│   ├── config/               # MongoDB connection
│   └── server.js             # Entry point
│
├── mediquick_frontend/       # Flutter Web application
│   └── lib/
│       ├── pages/            # High-level screens (Dashboard, Landing)
│       ├── screens/          # Feature screens (Checkout, Prescription, Admin)
│       ├── widgets/          # Reusable UI components
│       ├── services/         # HTTP service classes
│       ├── theme/            # App colors, typography
│       └── config.dart       # API base URL config
│
└── ml_service/               # (Optional) Python ML microservice
```

---

## ✨ Features

### 👤 User
- **Register / Login** with JWT-based authentication
- **Location-aware medicine search** — only shows medicines from godowns within 5km
- **Emergency Mode** — expands search radius to 500km when no local stock is found
- **Prescription upload** with AI OCR (Google Gemini) to auto-extract medicines
- **Cart & Checkout** — add medicines, review cart, and place orders
- **Dashboard** — view total orders, most ordered medicine, monthly spending history, and order status tracking
- **Order Status Timeline** — Picked Up → In Transit → Delivered

### 🛡️ Admin
- **Secure admin login** with separate token-based auth
- **Godown management** — Add, view, edit, delete godowns with GPS coordinates
- **Medicine management** — Add medicines with type (Painkiller, Antibiotic, etc.), category, price, and stock
- **Inventory viewer** — View stock levels per godown with low-stock alerts

---

## 🔧 Backend Setup

### Prerequisites
- Node.js v18+
- MongoDB Atlas account
- Cloudinary account (for medicine images)
- Google Gemini API key (for OCR)

### Installation

```bash
cd backend
npm install
```

### Environment Variables

Create a `.env` file in the `backend/` folder:

```env
MONGO_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret
ADMIN_SECRET=your_admin_jwt_secret

CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

GEMINI_API_KEY=your_gemini_api_key

PORT=5000
```

### Running

```bash
# Development (with auto-reload)
npm run dev

# Production
npm start
```

Server runs at `http://localhost:5000`

---

## 📱 Frontend Setup

### Prerequisites
- Flutter SDK (3.x+)
- Chrome (for web debugging)

### Installation

```bash
cd mediquick_frontend
flutter pub get
```

### Configure API URL

Edit `lib/config.dart` and set your backend base URL:

```dart
static const String baseUrl = 'http://localhost:5000';
```

### Running

```bash
flutter run -d chrome
```

---

## 🌐 API Endpoints

| Method | Route | Description |
|--------|-------|-------------|
| POST | `/api/auth/register` | Register a new user |
| POST | `/api/auth/login` | Login and receive JWT |
| PUT | `/api/auth/location` | Update user GPS location |
| GET | `/api/medicine/search` | Search medicines (geo-filtered) |
| GET | `/api/medicine` | Get all medicines |
| POST | `/api/simple-order` | Place a new order |
| GET | `/api/simple-order/myorders` | Get current user's orders |
| POST | `/api/prescription/upload` | Upload & OCR a prescription |
| GET | `/api/godown` | List all godowns |
| POST | `/api/godown` | Create a new godown |
| POST | `/api/admin/login` | Admin login |
| POST | `/api/admin/godowns` | Admin: Create godown |
| PUT | `/api/admin/godowns/:id` | Admin: Update godown |
| DELETE | `/api/admin/godowns/:id` | Admin: Delete godown |

> **Emergency Mode**: Append `?emergencyMode=true` to `/api/medicine/search` to expand the search radius from 5km to 500km.

---

## 🗺️ Medicine Search & Emergency Mode

### Normal Mode
Medicines are filtered to show **only those available in godowns within 5km** of the user's GPS location. If no nearby godowns carry the searched medicine, the frontend shows an "Enable Emergency Mode" prompt.

### Emergency Mode
When activated, the search radius is expanded to **500km**. An orange warning banner informs the user that delivery may take longer. The mode resets automatically when the search is cleared.

---

## 🧠 AI Prescription OCR

Users can upload a **photo of their prescription**. The backend sends it to **Google Gemini** which extracts medicine names. These are then matched against the database and shown as searchable results the user can add directly to their cart.

---

## 🏗️ Data Models

| Model | Key Fields |
|-------|-----------|
| `User` | name, email, password (bcrypt), address, location (GeoJSON) |
| `Medicine` | name, type, category, price, stock, prescriptionRequired |
| `Godown` | name, code, location (GeoJSON Point), isActive |
| `GodownInventory` | godown (ref), product (ref), stock |
| `SimpleOrder` | user, items [ name, qty, price ], totalAmount, createdAt |
| `Prescription` | user, imageUrl, extractedMedicines |

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Web) |
| Backend | Node.js, Express.js |
| Database | MongoDB Atlas (Mongoose) |
| Auth | JWT (jsonwebtoken), bcrypt |
| Image Storage | Cloudinary |
| AI / OCR | Google Gemini API |
| Location | Geolocator (Flutter), MongoDB `$geoWithin` |

---

## 📄 License

ISC © 2025 MediQuick
