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
  final _nameController = TextEditingController();
  final _salaryController = TextEditingController();
  final _membersController = TextEditingController();
  final _emiController = TextEditingController();
  final _emiDateController = TextEditingController();
  final _subscriptionsController = TextEditingController();
  final _subscriptionsDateController = TextEditingController();
  final _groceriesController = TextEditingController();
  final _tvInternetController = TextEditingController();
  final _tvInternetDateController = TextEditingController();
  final _otherBillsController = TextEditingController();
  final _otherBillsDateController = TextEditingController();
  final _budgetController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() => _isLoading = true);
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      if (data.containsKey('salary')) _isEditing = true;
      
      _nameController.text = data['name']?.toString() ?? user.displayName ?? '';
      _salaryController.text = data['salary']?.toString() ?? '';
      _membersController.text = data['familyMembers']?.toString() ?? '';
      _emiController.text = data['emi']?.toString() ?? '';
      _emiDateController.text = data['emiDate']?.toString() ?? '';
      _subscriptionsController.text = data['subscriptions']?.toString() ?? '';
      _subscriptionsDateController.text = data['subscriptionsDate']?.toString() ?? '';
      _groceriesController.text = data['groceries']?.toString() ?? '';
      _tvInternetController.text = data['tvInternet']?.toString() ?? '';
      _tvInternetDateController.text = data['tvInternetDate']?.toString() ?? '';
      _otherBillsController.text = data['otherBills']?.toString() ?? '';
      _otherBillsDateController.text = data['otherBillsDate']?.toString() ?? '';
      _budgetController.text = data['budget']?.toString() ?? '';
    } else {
      _nameController.text = user.displayName ?? '';
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

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
        'name': _nameController.text.isNotEmpty ? _nameController.text : (user.displayName ?? 'User'),
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'salary': double.tryParse(_salaryController.text) ?? 0.0,
        'familyMembers': int.tryParse(_membersController.text) ?? 1,
        'emi': double.tryParse(_emiController.text) ?? 0.0,
        'emiDate': int.tryParse(_emiDateController.text) ?? 1,
        'subscriptions': double.tryParse(_subscriptionsController.text) ?? 0.0,
        'subscriptionsDate': int.tryParse(_subscriptionsDateController.text) ?? 1,
        'groceries': double.tryParse(_groceriesController.text) ?? 0.0,
        'tvInternet': double.tryParse(_tvInternetController.text) ?? 0.0,
        'tvInternetDate': int.tryParse(_tvInternetDateController.text) ?? 1,
        'otherBills': double.tryParse(_otherBillsController.text) ?? 0.0,
        'otherBillsDate': int.tryParse(_otherBillsDateController.text) ?? 1,
        'budget': double.tryParse(_budgetController.text) ?? 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        if (_isEditing) {
          Navigator.pop(context); // Go back if editing
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
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
    _nameController.dispose();
    _salaryController.dispose();
    _membersController.dispose();
    _emiController.dispose();
    _emiDateController.dispose();
    _subscriptionsController.dispose();
    _subscriptionsDateController.dispose();
    _groceriesController.dispose();
    _tvInternetController.dispose();
    _tvInternetDateController.dispose();
    _otherBillsController.dispose();
    _otherBillsDateController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Profile' : 'Setup AI Profile', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 32),
            const Text("1. Personal Details & Income", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryGreen)),
            const SizedBox(height: 16),
            _buildInputField(label: 'Full Name', hint: 'e.g., John Doe', controller: _nameController, icon: Icons.person_outline, isText: true),
            const SizedBox(height: 16),
            _buildInputField(label: 'Monthly Salary (Income)', hint: 'e.g., 50000', controller: _salaryController, icon: Icons.account_balance_wallet_outlined),
            const SizedBox(height: 16),
            _buildInputField(label: 'Number of Family Members', hint: 'e.g., 4', controller: _membersController, icon: Icons.people_outline),
            
            const SizedBox(height: 32),
            const Text("2. Fixed Monthly Commitments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryGreen)),
            const SizedBox(height: 16),
            _buildInputField(label: 'Total EMIs / Loan Payments', hint: 'e.g., 12000', controller: _emiController, icon: Icons.credit_score_outlined, dueDateController: _emiDateController),
            const SizedBox(height: 16),
            _buildInputField(label: 'Monthly Subscriptions (Netflix, Gym)', hint: 'e.g., 1500', controller: _subscriptionsController, icon: Icons.subscriptions_outlined, dueDateController: _subscriptionsDateController),

            const SizedBox(height: 32),
            const Text("3. Monthly Living Expenses", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryGreen)),
            const SizedBox(height: 16),
            _buildInputField(label: 'Groceries / Everyday Needs', hint: 'e.g., 8000', controller: _groceriesController, icon: Icons.shopping_cart_outlined),
            const SizedBox(height: 16),
            _buildInputField(label: 'TV / Internet / Cable', hint: 'e.g., 1000', controller: _tvInternetController, icon: Icons.wifi, dueDateController: _tvInternetDateController),
            const SizedBox(height: 16),
            _buildInputField(label: 'Other Fixed Utility Bills', hint: 'e.g., 2000', controller: _otherBillsController, icon: Icons.receipt_long_outlined, dueDateController: _otherBillsDateController),

            const SizedBox(height: 32),
            const Text("4. Your Goals", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryGreen)),
            const SizedBox(height: 16),
            _buildInputField(label: 'Target Monthly Savings', hint: 'e.g., 10000', controller: _budgetController, icon: Icons.track_changes_outlined),
            
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
                    : Text(
                        _isEditing ? 'Save Changes' : 'Complete Setup & Enter Dashboard',
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
    bool isText = false,
    TextEditingController? dueDateController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: controller,
                keyboardType: isText ? TextInputType.name : TextInputType.number,
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
            ),
            if (dueDateController != null) ...[
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: dueDateController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textDark, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Day',
                    hintStyle: TextStyle(color: AppColors.textLight.withOpacity(0.5)),
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
              ),
            ],
          ],
        ),
      ],
    );
  }
}
