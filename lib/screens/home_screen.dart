import 'package:ai_finance_manager/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _CustomAppBar(),
              SizedBox(height: 24),
              _BalanceCard(),
              SizedBox(height: 16),
              _IncomeSpendingRow(),
              SizedBox(height: 32),
              _SectionHeader(title: 'Quick Actions', actionText: 'See All'),
              SizedBox(height: 16),
              _QuickActionsRow(),
              SizedBox(height: 24),
              _TipCard(),
              SizedBox(height: 32),
              _SectionHeader(title: 'Recent Transactions', actionText: 'See All'),
              SizedBox(height: 16),
              _TransactionsList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(),
    );
  }
}

class _CustomAppBar extends StatelessWidget {
  const _CustomAppBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(
            'https://i.pravatar.cc/150?u=michael', // Mock avatar
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Good Morning,',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 13,
              ),
            ),
            Text(
              'Prankur Sharma',
              style: TextStyle(
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
  const _BalanceCard();

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
                'Total Balance',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Icon(LucideIcons.eye, color: Colors.white.withOpacity(0.7), size: 20),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '\$98,123.40',
            style: TextStyle(
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
  const _IncomeSpendingRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Monthly Income',
            amount: '\$3,422.00',
            icon: LucideIcons.arrowDownCircle,
            iconColor: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Monthly Spending',
            amount: '\$1,433.20',
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
      children: const [
        _ActionItem(title: 'Add\nExpense', icon: LucideIcons.plus, isActive: false),
        _ActionItem(title: 'Portfolio', icon: LucideIcons.pieChart, isActive: false),
        _ActionItem(title: 'Goals', icon: LucideIcons.target, isActive: false),
        _ActionItem(title: 'Cards\nGuide', icon: LucideIcons.bookOpen, isActive: true),
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
  const _TransactionsList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TransactionTile(
          icon: LucideIcons.utensils,
          iconBg: Colors.orange.withOpacity(0.1),
          iconColor: Colors.orange,
          title: 'Swiggy Food',
          subtitle: 'Today, 12:30 PM',
          amount: '-\$24.50',
          isNegative: true,
        ),
        _TransactionTile(
          icon: LucideIcons.calendarDays,
          iconBg: Colors.green.withOpacity(0.1),
          iconColor: Colors.green,
          title: 'Salary Credit',
          subtitle: 'Yesterday, 09:00 AM',
          amount: '+\$3,422.00',
          isNegative: false,
        ),
        _TransactionTile(
          icon: LucideIcons.music,
          iconBg: Colors.blue.withOpacity(0.1),
          iconColor: Colors.blue,
          title: 'Spotify Subscription',
          subtitle: '20 Jan 2024',
          amount: '-\$11.99',
          isNegative: true,
        ),
      ],
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
