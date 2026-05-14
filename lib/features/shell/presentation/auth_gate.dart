import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/presentation/login_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../presentation/main_shell.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => _loadingScreen(),
      error: (_, __) => const _UnauthenticatedGate(),
      data: (user) {
        if (user != null) return _UserReadyGate(user: user);
        return const _UnauthenticatedGate();
      },
    );
  }

  static Widget _loadingScreen() {
    return const Scaffold(
      backgroundColor: Color(0xFF0F1117),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF))),
    );
  }
}

class _UnauthenticatedGate extends StatefulWidget {
  const _UnauthenticatedGate();

  @override
  State<_UnauthenticatedGate> createState() => _UnauthenticatedGateState();
}

class _UnauthenticatedGateState extends State<_UnauthenticatedGate> {
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _onboardingDone = prefs.getBool('onboarding_done') ?? false);
    }
  }

  void _onOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) setState(() => _onboardingDone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) return AuthGate._loadingScreen();
    if (_onboardingDone!) return const LoginScreen();
    return OnboardingScreen(onComplete: _onOnboardingComplete);
  }
}

class _UserReadyGate extends StatefulWidget {
  final User user;
  const _UserReadyGate({required this.user});

  @override
  State<_UserReadyGate> createState() => _UserReadyGateState();
}

class _UserReadyGateState extends State<_UserReadyGate> {
  bool _isReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ensureUserDocument();
  }

  Future<void> _ensureUserDocument() async {
    try {
      final db = FirebaseFirestore.instance;
      final doc = db.collection('users').doc(widget.user.uid);
      final snapshot = await doc.get();

      if (!snapshot.exists) {
        await doc.set({
          'uid': widget.user.uid,
          'displayName': widget.user.displayName ??
              widget.user.email?.split('@').first ??
              'Savaşçı',
          'email': widget.user.email ?? '',
          'level': 1,
          'xp': 0,
          'xpToNextLevel': 500,
          'streak': 0,
          'lastActiveDate': null,
          'title': 'Acemi Savaşçı',
          'stats': {
            'focus': 5,
            'energy': 5,
            'knowledge': 5,
            'strength': 5,
          },
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) setState(() => _isReady = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F1117),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Bağlantı hatası:\n$_error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() { _error = null; _isReady = false; });
                    _ensureUserDocument();
                  },
                  child: const Text('Tekrar Dene'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  child: const Text('Çıkış Yap', style: TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isReady) return AuthGate._loadingScreen();

    return const MainShell();
  }
}
