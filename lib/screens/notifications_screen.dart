import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_finance_manager/theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<List<Map<String, dynamic>>> _getNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = userDoc.data() ?? {};
    final salary = (data['salary'] ?? 0.0 as num).toDouble();
    final emi = (data['emi'] ?? 0.0 as num).toDouble();

    final txSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .where('type', isEqualTo: 'expense')
        .get();

    double totalSpent = 0;
    Map<String, double> categoryTotals = {};
    for (var doc in txSnapshot.docs) {
      final d = doc.data();
      final amt = (d['amount'] as num).toDouble();
      final cat = d['category'] ?? 'Other';
      totalSpent += amt;
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + amt;
    }

    List<Map<String, dynamic>> notifications = [];

    // Bill reminders
    final emiDate = (data['emiDate'] ?? 1) as int;
    final today = DateTime.now().day;
    if (emi > 0 && emiDate - today <= 5 && emiDate >= today) {
      notifications.add({
        'title': 'EMI Due Soon',
        'body': 'Your EMI of ₹${emi.toStringAsFixed(0)} is due on the ${emiDate}th.',
        'icon': LucideIcons.creditCard,
        'color': Colors.redAccent,
        'badge': 'Reminder',
        'badgeColor': Colors.redAccent,
        'time': 'Today',
        'isUnread': true,
      });
    }

    // Overspending alert
    if (salary > 0 && totalSpent > salary * 0.7) {
      notifications.add({
        'title': 'Spending Alert 🚨',
        'body': 'You have spent ${((totalSpent / salary) * 100).toStringAsFixed(0)}% of your income this month.',
        'icon': LucideIcons.alertTriangle,
        'color': Colors.orange,
        'badge': 'Warning',
        'badgeColor': Colors.orange,
        'time': '2h ago',
        'isUnread': true,
      });
    }

    // Top category tip
    if (categoryTotals.isNotEmpty) {
      final top = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      notifications.add({
        'title': 'AI Insight: ${top.first.key}',
        'body': 'Your top expense this month is ${top.first.key} at ₹${top.first.value.toStringAsFixed(0)}. Check your AI tips!',
        'icon': LucideIcons.sparkles,
        'color': AppColors.darkGreen,
        'badge': 'AI Tip',
        'badgeColor': AppColors.darkGreen,
        'time': '5h ago',
        'isUnread': false,
      });
    }

    // Savings nudge
    notifications.add({
      'title': 'Weekly Savings Summary',
      'body': 'Review your spending patterns and update your savings goals for better results.',
      'icon': LucideIcons.piggyBank,
      'color': Colors.teal,
      'badge': 'Weekly',
      'badgeColor': Colors.teal,
      'time': 'Yesterday',
      'isUnread': false,
    });

    // Goal reminder
    notifications.add({
      'title': 'Check Your Goals',
      'body': 'You haven\'t updated your savings goals this week. Stay on track!',
      'icon': LucideIcons.target,
      'color': Colors.blueAccent,
      'badge': 'Goals',
      'badgeColor': Colors.blueAccent,
      'time': '2 days ago',
      'isUnread': false,
    });

    return notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Mark all read',
              style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.darkGreen));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.bellOff, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final n = notifications[index];
              final isUnread = n['isUnread'] as bool;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isUnread ? (n['color'] as Color).withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isUnread ? (n['color'] as Color).withOpacity(0.2) : Colors.transparent,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (n['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(n['icon'] as IconData, color: n['color'] as Color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (n['badgeColor'] as Color).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  n['badge'] as String,
                                  style: TextStyle(
                                    color: n['badgeColor'] as Color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                n['time'] as String,
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                              ),
                              if (isUnread) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: n['color'] as Color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            n['title'] as String,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n['body'] as String,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
