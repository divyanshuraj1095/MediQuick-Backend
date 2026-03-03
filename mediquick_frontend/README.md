# MediQuick Frontend

A modern Flutter frontend for a medicine delivery app with a beautiful landing page and authentication interface.

## Features

- 🎨 Modern healthcare-themed UI with green/teal gradients
- 📱 Responsive design (desktop, tablet, mobile)
- 🔐 Sign In / Sign Up forms with validation
- 🚀 Fast delivery stats and feature highlights
- ✨ Material 3 design system

## Project Structure

```
lib/
├── main.dart                 # Entry point with landing page
├── screens/
│   └── auth/                 # Auth screens (placeholder)
├── widgets/
│   ├── feature_card.dart     # Feature card widget
│   ├── stat_card.dart        # Statistics card widget
│   └── auth_form.dart        # Authentication form widget
└── theme/
    └── app_theme.dart        # App theme and colors
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK

### Installation

1. Navigate to the project directory:
```bash
cd mediquick_frontend
```

2. Get dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## UI Components

### Landing Page
- Left side: Logo, heading, stats cards, feature grid, footer
- Right side: Authentication card with tabs

### Stats Cards
- 30min Delivery Time
- 500+ Medicines
- 50K+ Happy Users

### Feature Cards
- Instant Delivery
- 100% Authentic
- Expert Care
- Best Prices

### Authentication
- Sign In / Sign Up tabs
- Email and password fields
- Remember me checkbox
- Forgot password link
- Social login buttons (Google, Apple)

## Color Palette

- Primary Green: `#10B981`
- Primary Teal: `#14B8A6`
- Background: `#F9FAFB`
- Cards: White with shadows

## Responsive Design

The app automatically adapts to different screen sizes:
- **Desktop (>1024px)**: Side-by-side layout
- **Mobile/Tablet (<1024px)**: Stacked layout

## Notes

- No backend integration included
- Form validation is basic (can be extended)
- Social login buttons are placeholders
- All widgets are stateless where possible
