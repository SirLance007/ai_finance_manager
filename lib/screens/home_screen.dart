import 'package:flutter/material.dart';
import 'package:ai_finance_manager/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ai_finance_manager/screens/add_expense_screen.dart';
import 'package:ai_finance_manager/screens/goals_screen.dart';
import 'package:ai_finance_manager/screens/profile_screen.dart';
import 'package:ai_finance_manager/screens/ai_insights_screen.dart';
import 'package:ai_finance_manager/screens/portfolio_screen.dart';
import 'package:ai_finance_manager/screens/onboarding_screen.dart';
import 'package:ai_finance_manager/screens/ai_invest_screen.dart';
String formatINR(double amount) {
  String numStr = amount.abs().toStringAsFixed(2);
  List<String> parts = numStr.split('.');
  String whole = parts[0];
  String decimal = parts.length > 1 ? '.' + parts[1] : '';
  
  if (whole.length <= 3) return (amount < 0 ? '-' : '') + whole + decimal;
  
  String result = whole.substring(whole.length - 3);
  whole = whole.substring(0, whole.length - 3);
  
  while (whole.isNotEmpty) {
    int take = whole.length > 2 ? whole.length - 2 : 0;
    result = '${whole.substring(take)},$result';
    whole = whole.substring(0, take);
  }
  
  return (amount < 0 ? '-' : '') + result + decimal;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _obscured = false;
  int _currentIndex = 0;

  void _toggleObscure() {
    setState(() => _obscured = !_obscured);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.hasError) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.darkGreen)),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final name = data['name'] as String? ?? 'User';
        final photoUrl = data['photoUrl'] as String? ?? 'https://i.pravatar.cc/150';
        
        final salary = (data['salary'] ?? 0.0) is num ? ((data['salary'] ?? 0.0) as num).toDouble() : 0.0;
        final familyMembers = (data['familyMembers'] ?? 1) is num ? ((data['familyMembers'] ?? 1) as num).toInt() : 1;
        final emi = (data['emi'] ?? 0.0) is num ? ((data['emi'] ?? 0.0) as num).toDouble() : 0.0;
        final emiDate = (data['emiDate'] ?? 1) is num ? ((data['emiDate'] ?? 1) as num).toInt() : 1;
        final subscriptions = (data['subscriptions'] ?? 0.0) is num ? ((data['subscriptions'] ?? 0.0) as num).toDouble() : 0.0;
        final subscriptionsDate = (data['subscriptionsDate'] ?? 1) is num ? ((data['subscriptionsDate'] ?? 1) as num).toInt() : 1;
        final groceries = (data['groceries'] ?? 0.0) is num ? ((data['groceries'] ?? 0.0) as num).toDouble() : 0.0;
        final tvInternet = (data['tvInternet'] ?? 0.0) is num ? ((data['tvInternet'] ?? 0.0) as num).toDouble() : 0.0;
        final tvInternetDate = (data['tvInternetDate'] ?? 1) is num ? ((data['tvInternetDate'] ?? 1) as num).toInt() : 1;
        final otherBills = (data['otherBills'] ?? 0.0) is num ? ((data['otherBills'] ?? 0.0) as num).toDouble() : 0.0;
        final otherBillsDate = (data['otherBillsDate'] ?? 1) is num ? ((data['otherBillsDate'] ?? 1) as num).toInt() : 1;
        final budget = (data['budget'] ?? 0.0) is num ? ((data['budget'] ?? 0.0) as num).toDouble() : 0.0;
        
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('transactions').orderBy('date', descending: true).snapshots(),
          builder: (context, txSnapshot) {
            double totalSpent = 0.0;
            if (txSnapshot.hasData) {
              for (var doc in txSnapshot.data!.docs) {
                final docData = doc.data() as Map<String, dynamic>;
                if (docData['type'] == 'expense') {
                  totalSpent += (docData['amount'] ?? 0.0) as double;
                }
              }
            }

            final estimatedSavings = salary - emi - totalSpent;
            final txDocs = txSnapshot.hasData ? txSnapshot.data!.docs : [];

            return Scaffold(
              backgroundColor: AppColors.background,
              body: _currentIndex == 1
                  ? const PortfolioScreen()
                  : _currentIndex == 2 
                      ? GoalsScreen(photoUrl: photoUrl) 
                      : _currentIndex == 3
                          ? const AiInsightsScreen()
                          : _currentIndex == 4 
                              ? const ProfileScreen() 
                              : (_currentIndex == 0 ? SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CustomAppBar(name: name, photoUrl: photoUrl),
                          const SizedBox(height: 24),
                          _BalanceCard(
                            balance: estimatedSavings,
                            obscured: _obscured,
                            onToggleObscure: _toggleObscure,
                          ),
                          const SizedBox(height: 16),
                          _IncomeSpendingRow(
                            income: salary,
                            spending: totalSpent,
                            obscured: _obscured,
                          ),
                          const SizedBox(height: 32),
                          const _SectionHeader(title: 'Quick Actions', actionText: ''),
                          const SizedBox(height: 16),
                          const _QuickActionsRow(),
                          const SizedBox(height: 32),
                          const _SectionHeader(title: 'Upcoming Bills', actionText: ''),
                          const SizedBox(height: 16),
                          _UpcomingBills(
                            emi: emi, emiDate: emiDate,
                            subscriptions: subscriptions, subscriptionsDate: subscriptionsDate,
                            tvInternet: tvInternet, tvInternetDate: tvInternetDate,
                            otherBills: otherBills, otherBillsDate: otherBillsDate,
                          ),
                          const SizedBox(height: 24),
                          const _TipCard(),
                          const SizedBox(height: 32),
                          const _SectionHeader(title: 'Recent Transactions', actionText: 'See All'),
                          const SizedBox(height: 16),
                          _TransactionsList(transactions: txDocs),
                        ],
                      ),
                    ),
                  ) : const Center(child: Text("Coming Soon", style: TextStyle(color: AppColors.textDark)))),
              bottomNavigationBar: _BottomNav(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
              ),
            );
          }
        );
      }
    );
  }
}

class _CustomAppBar extends StatelessWidget {
  final String name;
  final String photoUrl;

  const _CustomAppBar({required this.name, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(photoUrl),
          backgroundColor: Colors.grey.shade300,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good Morning,',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 13,
              ),
            ),
            Text(
              name,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(LucideIcons.bell, color: AppColors.textDark),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(LucideIcons.search, color: AppColors.textDark),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final bool obscured;
  final VoidCallback onToggleObscure;

  const _BalanceCard({
    required this.balance,
    required this.obscured,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimated Savings / Month',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              GestureDetector(
                onTap: onToggleObscure,
                child: Icon(
                  obscured ? LucideIcons.eyeOff : LucideIcons.eye, 
                  color: Colors.white.withOpacity(0.7), 
                  size: 20
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            obscured ? '******' : '₹${formatINR(balance)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(LucideIcons.arrowUp, color: Colors.greenAccent, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '2.60%',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'vs. last week',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const Spacer(),
              SizedBox(
                width: 80,
                height: 30,
                child: CustomPaint(
                  painter: _SparklinePainter(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.8, size.width * 0.4, size.height * 0.9);
    path.quadraticBezierTo(size.width * 0.6, size.height * 1.0, size.width * 0.7, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.85, size.height * 0.6, size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IncomeSpendingRow extends StatelessWidget {
  final double income;
  final double spending;
  final bool obscured;

  const _IncomeSpendingRow({
    required this.income, 
    required this.spending,
    required this.obscured,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Monthly Income',
            amount: obscured ? '****' : '₹${formatINR(income)}',
            icon: LucideIcons.arrowDownCircle,
            iconColor: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Spent this Month',
            amount: obscured ? '****' : '₹${formatINR(spending)}',
            icon: LucideIcons.arrowUpRightSquare,
            iconColor: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color iconColor;

  const _StatCard({required this.title, required this.amount, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(amount, style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;

  const _SectionHeader({required this.title, required this.actionText});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Text(actionText, style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
            const Icon(Icons.chevron_right, color: AppColors.textLight, size: 18),
          ],
        )
      ],
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
          child: const _ActionItem(title: 'Add\nExpense', icon: LucideIcons.plus, isActive: true),
        ),
        const _ActionItem(title: 'Portfolio', icon: LucideIcons.pieChart, isActive: false),
        const _ActionItem(title: 'Goals', icon: LucideIcons.target, isActive: false),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiInvestScreen())),
          child: const _ActionItem(title: 'AI\nInvest', icon: LucideIcons.trendingUp, isActive: true),
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;

  const _ActionItem({required this.title, required this.icon, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 75,
      height: 100,
      decoration: BoxDecoration(
        color: isActive ? AppColors.pillGreen : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textDark, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w600, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.lightbulb, color: AppColors.textDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Tip', style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold)),
                Text("You're doing great! Keep tracking consistently.", style: TextStyle(color: AppColors.textDark, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _TransactionsList extends StatelessWidget {
  final List<dynamic> transactions;
  const _TransactionsList({required this.transactions});

  IconData _getIconForCategory(String category, bool isNegative) {
    if (!isNegative) return LucideIcons.arrowDownCircle;
    switch (category) {
      case 'Food': return LucideIcons.utensils;
      case 'Transportation': return LucideIcons.car;
      case 'Entertainment': return LucideIcons.tv;
      case 'Shopping': return LucideIcons.shoppingBag;
      case 'Utilities': return LucideIcons.zap;
      default: return LucideIcons.receipt;
    }
  }

  Color _getColorForCategory(String category, bool isNegative) {
    if (!isNegative) return Colors.green;
    switch (category) {
      case 'Food': return Colors.orange;
      case 'Transportation': return Colors.blue;
      case 'Entertainment': return Colors.purple;
      case 'Shopping': return Colors.pink;
      case 'Utilities': return Colors.amber;
      default: return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text("No transactions yet. Add some!", style: TextStyle(color: AppColors.textLight))),
      );
    }

    return Column(
      children: transactions.take(10).map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final isNegative = data['type'] == 'expense';
        final category = data['category'] ?? 'Other';
        
        final icon = _getIconForCategory(category, isNegative);
        final color = _getColorForCategory(category, isNegative);

        return _TransactionTile(
          icon: icon,
          iconBg: color.withOpacity(0.1),
          iconColor: color,
          title: data['title'] ?? 'Transaction',
          subtitle: category,
          amount: '${isNegative ? '-' : '+'}₹${(data['amount'] ?? 0).toStringAsFixed(2)}',
          isNegative: isNegative,
        );
      }).toList(),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String amount;
  final bool isNegative;

  const _TransactionTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isNegative,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isNegative ? AppColors.textDark : Colors.green,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: onTap,
        selectedItemColor: AppColors.darkGreen,
        unselectedItemColor: AppColors.textLight,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.pieChart), label: 'Portfolio'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.target), label: 'Goals'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.sparkles), label: 'Smart Savings'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profile'),
        ],
      ),
    );
  }
}

class _UpcomingBills extends StatelessWidget {
  final double emi;
  final int emiDate;
  final double subscriptions;
  final int subscriptionsDate;
  final double tvInternet;
  final int tvInternetDate;
  final double otherBills;
  final int otherBillsDate;

  const _UpcomingBills({
    required this.emi,
    required this.emiDate,
    required this.subscriptions,
    required this.subscriptionsDate,
    required this.tvInternet,
    required this.tvInternetDate,
    required this.otherBills,
    required this.otherBillsDate,
  });

  String _formatDate(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1: return '${day}st';
      case 2: return '${day}nd';
      case 3: return '${day}rd';
      default: return '${day}th';
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> billWidgets = [];

    Widget buildBillItem(String title, double amount, int day, IconData icon, Color color) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text('Due on ${_formatDate(day)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
          ],
        ),
      );
    }

    if (emi > 0) billWidgets.add(buildBillItem('EMIs / Loans', emi, emiDate, LucideIcons.creditCard, Colors.redAccent));
    if (subscriptions > 0) billWidgets.add(buildBillItem('Subscriptions', subscriptions, subscriptionsDate, LucideIcons.youtube, Colors.orangeAccent));
    if (tvInternet > 0) billWidgets.add(buildBillItem('TV & Internet', tvInternet, tvInternetDate, LucideIcons.wifi, Colors.blueAccent));
    if (otherBills > 0) billWidgets.add(buildBillItem('Other Utility Bills', otherBills, otherBillsDate, LucideIcons.fileText, Colors.purpleAccent));

    if (billWidgets.isEmpty) {
      return Center(
        child: Text("No upcoming bills tracked.", style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    return Column(children: billWidgets);
  }
}
