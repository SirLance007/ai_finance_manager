import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_finance_manager/theme/app_colors.dart';
import 'package:ai_finance_manager/screens/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _salaryController = TextEditingController();
  final _emiController = TextEditingController();
  final _budgetController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_salaryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your salary')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': user.displayName ?? 'User',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'salary': double.tryParse(_salaryController.text) ?? 0.0,
        'emi': double.tryParse(_emiController.text) ?? 0.0,
        'budget': double.tryParse(_budgetController.text) ?? 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save data: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _emiController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Setup AI Profile', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Let's personalize your AI Finance Manager.",
              style: TextStyle(color: AppColors.textDark, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "We need some basic details to give you accurate financial advice.",
              style: TextStyle(color: AppColors.textLight, fontSize: 16),
            ),
            const SizedBox(height: 40),
            
            _buildInputField(
              label: 'Monthly Salary (Income)',
              hint: 'e.g., 5000',
              controller: _salaryController,
              icon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 24),
            
            _buildInputField(
              label: 'Total EMIs / Loan Payments',
              hint: 'e.g., 1200',
              controller: _emiController,
              icon: Icons.credit_score_outlined,
            ),
            const SizedBox(height: 24),
            
            _buildInputField(
              label: 'Target Monthly Budget',
              hint: 'e.g., 2000',
              controller: _budgetController,
              icon: Icons.track_changes_outlined,
            ),
            
            const SizedBox(height: 60),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Complete Setup & Enter Dashboard',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label, 
    required String hint, 
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textDark, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textLight.withOpacity(0.5)),
            prefixIcon: Icon(icon, color: AppColors.darkGreen),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.darkGreen, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
