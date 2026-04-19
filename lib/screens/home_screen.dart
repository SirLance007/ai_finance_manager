import 'package:ai_finance_manager/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ai_finance_manager/screens/add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _obscured = false;

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
        
        final salary = (data['salary'] ?? 0.0) as double;
        final emi = (data['emi'] ?? 0.0) as double;
        final budget = (data['budget'] ?? 0.0) as double;
        
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
              body: SafeArea(
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
                      const SizedBox(height: 24),
                      const _TipCard(),
                      const SizedBox(height: 32),
                      const _SectionHeader(title: 'Recent Transactions', actionText: 'See All'),
                      const SizedBox(height: 16),
                      _TransactionsList(transactions: txDocs),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: const _BottomNav(),
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
            obscured ? '******' : '\$${balance.toStringAsFixed(2)}',
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
                      style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600),
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
              // MOCK SPARKLINE (Line using basic container for now to save space, normally uses fl_chart)
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
            amount: obscured ? '****' : '\$${income.toStringAsFixed(2)}',
            icon: LucideIcons.arrowDownCircle,
            iconColor: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Spent this Month',
            amount: obscured ? '****' : '\$${spending.toStringAsFixed(2)}',
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
        const _ActionItem(title: 'Cards\nGuide', icon: LucideIcons.bookOpen, isActive: false),
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

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text("No transactions yet. Add some!", style: TextStyle(color: AppColors.textLight))),
      );
    }

    return Column(
      children: transactions.take(5).map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final isNegative = data['type'] == 'expense';
        return _TransactionTile(
          icon: isNegative ? LucideIcons.shoppingBag : LucideIcons.arrowDownCircle,
          iconBg: isNegative ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
          iconColor: isNegative ? Colors.orange : Colors.green,
          title: data['title'] ?? 'Transaction',
          subtitle: data['category'] ?? 'General',
          amount: '${isNegative ? '-' : '+'}\$${(data['amount'] ?? 0).toStringAsFixed(2)}',
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
  const _BottomNav();

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
        selectedItemColor: AppColors.darkGreen,
        unselectedItemColor: AppColors.textLight,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        items: [
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.pillGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.home, color: AppColors.darkGreen),
            ),
            label: 'Home',
          ),
          const BottomNavigationBarItem(icon: Icon(LucideIcons.pieChart), label: 'Portfolio'),
          const BottomNavigationBarItem(icon: Icon(LucideIcons.target), label: 'Goals'),
          const BottomNavigationBarItem(icon: Icon(LucideIcons.newspaper), label: 'News'),
          const BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profile'),
        ],
      ),
    );
  }
}
