import 'package:flutter/material.dart';
import 'services/admin_auth_service.dart';

/// Wraps an admin route. If no admin token exists → redirect to /admin/login.
class AdminAuthGuard extends StatefulWidget {
  final Widget child;
  const AdminAuthGuard({super.key, required this.child});

  @override
  State<AdminAuthGuard> createState() => _AdminAuthGuardState();
}

class _AdminAuthGuardState extends State<AdminAuthGuard> {
  bool _checking = true;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final loggedIn = await AdminAuthService.isAdminLoggedIn();
    if (!mounted) return;
    if (!loggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/admin/login', (_) => false);
        }
      });
    } else {
      setState(() {
        _isAuthorized = true;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_isAuthorized) return const SizedBox.shrink();
    return widget.child;
  }
}
