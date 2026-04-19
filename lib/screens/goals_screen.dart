import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ai_finance_manager/screens/add_goal_screen.dart';

class GoalsScreen extends StatelessWidget {
  final String photoUrl;
  const GoalsScreen({super.key, required this.photoUrl});

  IconData _getIcon(String name) {
    switch (name) {
      case 'House': return LucideIcons.home;
      case 'Car': return LucideIcons.car;
      case 'Education': return LucideIcons.graduationCap;
      case 'Tech': return LucideIcons.smartphone;
      case 'Travel': return LucideIcons.plane;
      default: return LucideIcons.target;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Center(
            child: CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(photoUrl),
              backgroundColor: Colors.grey.shade200,
            ),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(LucideIcons.bell, color: Colors.black87), onPressed: () {}),
          IconButton(icon: const Icon(LucideIcons.settings, color: Colors.black87), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('MY GOALS', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddGoalScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFFEAF5EE), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: const [
                          Icon(LucideIcons.plus, color: Color(0xFF133b2b), size: 16),
                          SizedBox(width: 6),
                          Text('New Goal', style: TextStyle(color: Color(0xFF133b2b), fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('goals').orderBy('createdAt', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF133b2b)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No goals yet. Add your first goal!", style: TextStyle(color: Colors.grey)));
                    }

                    final docs = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        
                        final title = data['title'] ?? 'Goal';
                        final target = (data['targetAmount'] ?? 1.0) as double;
                        final saved = (data['savedAmount'] ?? 0.0) as double;
                        final daysLeft = data['daysLeft'] ?? 0;
                        final iconName = data['icon'] ?? 'Tech';
                        
                        final progress = (saved / (target == 0 ? 1 : target)).clamp(0.0, 1.0);
                        final percent = (progress * 100).toInt();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(24)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(color: const Color(0xFFEAF5EE), borderRadius: BorderRadius.circular(16)),
                                    child: Icon(_getIcon(iconName), color: Colors.black87, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(title, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text('Target: ₹${target.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Text('₹${saved.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Stack(
                                children: [
                                  Container(width: double.infinity, height: 8, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
                                  FractionallySizedBox(
                                    widthFactor: progress,
                                    child: Container(height: 8, decoration: BoxDecoration(color: const Color(0xFF133b2b), borderRadius: BorderRadius.circular(4))),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('$percent% Completed', style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
                                  Text('$daysLeft days left', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
