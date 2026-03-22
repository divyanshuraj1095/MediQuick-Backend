import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/home/home_screen.dart';
import 'pages/dashboard_page.dart';
import 'pages/profile_page.dart';
import 'screens/medicine_details_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/upload_prescription_screen.dart';
import 'screens/prescription_results_screen.dart';
import 'screens/prescription_history_screen.dart';
import 'screens/local_advisor_screen.dart';
import 'services/cart_service.dart';
import 'widgets/auth_guard.dart';
import 'screens/admin/pages/admin_login_screen.dart';
import 'screens/admin/pages/admin_dashboard_screen.dart';
import 'screens/admin/admin_auth_guard.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartService(),
      child: const MediQuickApp(),
    ),
  );
}

class MediQuickApp extends StatelessWidget {
  const MediQuickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediQuick',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        // ── Public routes (no auth required) ──
        '/': (context) => const AuthGate(),
        '/home': (context) => const HomeScreen(),

        // ── Protected routes (require login) ──
        '/dashboard': (context) => const AuthGuard(child: DashboardPage()),
        '/profile': (context) => const AuthGuard(child: ProfilePage()),
        '/medicine': (context) => const AuthGuard(child: MedicineDetailsScreen()),
        '/cart': (context) => const AuthGuard(child: CartScreen()),
        '/checkout': (context) => const AuthGuard(child: CheckoutScreen()),
        '/upload-prescription': (context) =>
            const AuthGuard(child: UploadPrescriptionScreen()),
        '/prescription-results': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>? ??
              {};
          return AuthGuard(child: PrescriptionResultsScreen(responseData: args));
        },
        '/prescription-history': (context) =>
            const AuthGuard(child: PrescriptionHistoryScreen()),
        '/local-advisor': (context) =>
            const AuthGuard(child: LocalAdvisorScreen()),

        // ── Admin routes ──
        '/admin/login': (context) => const AdminLoginScreen(),
        '/admin/dashboard': (context) =>
            const AdminAuthGuard(child: AdminDashboardScreen()),
      },
    );
  }
}
