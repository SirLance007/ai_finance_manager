import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ai_finance_manager/screens/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await GoogleSignIn.instance.signOut();
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
    }
  }

  Future<void> _showEditSalaryDialog(BuildContext context, double currentSalary) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final controller = TextEditingController(text: currentSalary.toStringAsFixed(0));
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Edit Monthly Salary', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: const TextStyle(color: Colors.black, fontSize: 16),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    setState(() => isLoading = true);
                    final newSalary = double.tryParse(controller.text) ?? currentSalary;
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                      'salary': newSalary,
                    });
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF133b2b),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save', style: TextStyle(color: Colors.white)),
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF133b2b)));
            }

            final data = snapshot.hasData && snapshot.data!.exists ? snapshot.data!.data() as Map<String, dynamic> : {};
            final name = data['name'] ?? user.displayName ?? 'User';
            final email = data['email'] ?? user.email ?? 'user@example.com';
            final photoUrl = data['photoUrl'] ?? user.photoURL ?? 'https://i.pravatar.cc/150';
            final salary = (data['salary'] ?? 0.0) as double;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: NetworkImage(photoUrl),
                        backgroundColor: Colors.grey.shade200,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(email, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF133b2b),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('MONTHLY SALARY', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                            const SizedBox(height: 8),
                            Text('\$${salary.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => _showEditSalaryDialog(context, salary),
                          child: const Text('Edit', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildListTile(icon: LucideIcons.user, title: 'Personal Information'),
                  const SizedBox(height: 8),
                  _buildListTile(icon: LucideIcons.landmark, title: 'Bank Accounts'),
                  const SizedBox(height: 8),
                  _buildListTile(icon: LucideIcons.bell, title: 'Notifications'),
                  const SizedBox(height: 8),
                  _buildListTile(icon: LucideIcons.shieldCheck, title: 'Security'),
                  const SizedBox(height: 8),
                  _buildListTile(icon: LucideIcons.helpCircle, title: 'Help & Support'),
                  const SizedBox(height: 8),
                  _buildListTile(icon: LucideIcons.logOut, title: 'Log Out', onTap: () => _logout(context)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildListTile({required IconData icon, required String title, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.black87, size: 24),
      title: Text(title, style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
      trailing: const Icon(LucideIcons.chevronRight, color: Colors.black54, size: 20),
      onTap: onTap ?? () {},
    );
  }
}
