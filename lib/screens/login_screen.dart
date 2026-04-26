import 'package:ai_finance_manager/screens/home_screen.dart';
import 'package:ai_finance_manager/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_finance_manager/screens/onboarding_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGreen,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'AI Finance Manager',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Track, analyze, and grow your wealth.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 60),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await GoogleSignIn.instance.initialize();
                    final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
                    if (googleUser != null) {
                      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
                      final AuthCredential credential = GoogleAuthProvider.credential(
                        idToken: googleAuth.idToken,
                      );
                      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);

                      if (userCred.user != null) {
                        try {
                          final userDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userCred.user!.uid)
                              .get();
                          if (context.mounted) {
                            if (userDoc.exists &&
                                userDoc.data() != null &&
                                userDoc.data()!.containsKey('salary')) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => const HomeScreen()),
                              );
                            } else {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                              );
                            }
                          }
                        } catch (_) {
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                            );
                          }
                        }
                      }
                    }
                  } catch (e) {
                    debugPrint('Login failed: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Login failed: ${e.toString()}')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.login, color: AppColors.darkGreen),
                label: const Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
