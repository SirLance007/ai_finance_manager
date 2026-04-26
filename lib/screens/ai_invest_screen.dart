import 'package:flutter/material.dart';
import 'package:ai_finance_manager/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math';

String formatINR(double amount) {
  String numStr = amount.abs().toStringAsFixed(0);
  if (numStr.length <= 3) return (amount < 0 ? '-' : '') + numStr;

  String result = numStr.substring(numStr.length - 3);
  String whole = numStr.substring(0, numStr.length - 3);

  while (whole.isNotEmpty) {
    int take = whole.length > 2 ? whole.length - 2 : whole.length;
    result = '${whole.substring(whole.length - take)},$result';
    whole = whole.substring(0, whole.length - take);
  }

  return (amount < 0 ? '-' : '') + result;
}

class AiInvestScreen extends StatefulWidget {
  const AiInvestScreen({super.key});

  @override
  State<AiInvestScreen> createState() => _AiInvestScreenState();
}

class _AiInvestScreenState extends State<AiInvestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedRisk; // 'High Risk', 'Medium Risk', 'Low Risk', or null for all

  final List<InvestmentOption> stocks = [
    InvestmentOption(
      name: 'Zomato Ltd',
      symbol: 'ZOMATO.NS',
      type: 'SIP',
      risk: 'High Risk',
      expectedAnnualReturn: 0.22,
      description: 'High-growth tech-enabled food delivery with expanding quick commerce.',
      suggestedAmount: 1500,
    ),
    InvestmentOption(
      name: 'Suzlon Energy',
      symbol: 'SUZLON.NS',
      type: 'SIP',
      risk: 'High Risk',
      expectedAnnualReturn: 0.25,
      description: 'Green energy momentum with strong order book.',
      suggestedAmount: 1000,
    ),
    InvestmentOption(
      name: 'IRFC',
      symbol: 'IRFC.NS',
      type: 'SIP',
      risk: 'Medium Risk',
      expectedAnnualReturn: 0.18,
      description: 'Railway financing with consistent dividend yield.',
      suggestedAmount: 1500,
    ),
    InvestmentOption(
      name: 'Reliance Industries',
      symbol: 'RELIANCE.NS',
      type: 'SIP',
      risk: 'Low Risk',
      expectedAnnualReturn: 0.15,
      description: 'Diversified conglomerate with strong retail and telecom growth.',
      suggestedAmount: 2000,
    ),
    InvestmentOption(
      name: 'HDFC Bank',
      symbol: 'HDFCBANK.NS',
      type: 'SIP',
      risk: 'Low Risk',
      expectedAnnualReturn: 0.12,
      description: 'Leading private bank with stable growth and asset quality.',
      suggestedAmount: 2500,
    ),
  ];

  final List<InvestmentOption> sips = [
    InvestmentOption(
      name: 'Quant Small Cap',
      symbol: 'QUANTSMALL',
      type: 'SIP',
      risk: 'High Risk',
      expectedAnnualReturn: 0.24,
      description: 'Aggressive small-cap fund with high growth potential.',
      suggestedAmount: 2000,
    ),
    InvestmentOption(
      name: 'Nippon India Multi Cap',
      symbol: 'NIPPONMULTI',
      type: 'SIP',
      risk: 'High Risk',
      expectedAnnualReturn: 0.20,
      description: 'Dynamic allocation across large, mid, and small-cap stocks.',
      suggestedAmount: 1500,
    ),
    InvestmentOption(
      name: 'Parag Parikh Flexi Cap',
      symbol: 'PPFAS',
      type: 'SIP',
      risk: 'Medium Risk',
      expectedAnnualReturn: 0.18,
      description: 'Diversified equity fund with international exposure.',
      suggestedAmount: 2500,
    ),
    InvestmentOption(
      name: 'SBI Bluechip',
      symbol: 'SBIBLUE',
      type: 'SIP',
      risk: 'Low Risk',
      expectedAnnualReturn: 0.14,
      description: 'Large-cap fund focusing on stable, established companies.',
      suggestedAmount: 3000,
    ),
    InvestmentOption(
      name: 'Mirae Asset Large Cap',
      symbol: 'MIRAE',
      type: 'SIP',
      risk: 'Low Risk',
      expectedAnnualReturn: 0.13,
      description: 'Consistent performer in the large-cap equity segment.',
      suggestedAmount: 2000,
    ),
  ];

  final List<InvestmentOption> etfs = [
    InvestmentOption(
      name: 'IT BeES',
      symbol: 'ITBEES',
      type: 'SIP',
      risk: 'High Risk',
      expectedAnnualReturn: 0.18,
      description: 'Invests in the rapidly growing IT sector.',
      suggestedAmount: 1500,
    ),
    InvestmentOption(
      name: 'MON100',
      symbol: 'MON100',
      type: 'SIP',
      risk: 'High Risk',
      expectedAnnualReturn: 0.20,
      description: 'Tracks the NASDAQ-100 index for US tech exposure.',
      suggestedAmount: 2000,
    ),
    InvestmentOption(
      name: 'Bank BeES',
      symbol: 'BANKBEES',
      type: 'SIP',
      risk: 'Medium Risk',
      expectedAnnualReturn: 0.15,
      description: 'Exposure to the top banking stocks in India.',
      suggestedAmount: 2500,
    ),
    InvestmentOption(
      name: 'Nifty 50 BeES',
      symbol: 'NIFTYBEES',
      type: 'SIP',
      risk: 'Low Risk',
      expectedAnnualReturn: 0.12,
      description: 'Tracks the Nifty 50 index for stable market returns.',
      suggestedAmount: 3000,
    ),
    InvestmentOption(
      name: 'Gold BeES',
      symbol: 'GOLDBEES',
      type: 'SIP',
      risk: 'Low Risk',
      expectedAnnualReturn: 0.08,
      description: 'Safe-haven asset tracking domestic gold prices.',
      suggestedAmount: 1000,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double _calculateReturn(double principal, double rate, int years, String type) {
    if (type == 'SIP') {
      double monthlyRate = rate / 12;
      int months = years * 12;
      return principal * ((pow(1 + monthlyRate, months) - 1) / monthlyRate) * (1 + monthlyRate);
    } else {
      return principal * pow((1 + rate), years);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

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
          'AI Invest Plan',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.hasError) {
            return const Center(child: CircularProgressIndicator(color: AppColors.darkGreen));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final salary = (data['salary'] ?? 0.0) is num ? ((data['salary'] ?? 0.0) as num).toDouble() : 0.0;
          final emi = (data['emi'] ?? 0.0) is num ? ((data['emi'] ?? 0.0) as num).toDouble() : 0.0;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('transactions')
                .snapshots(),
            builder: (context, txSnapshot) {
              double totalExpenses = 0.0;
              if (txSnapshot.hasData) {
                for (var doc in txSnapshot.data!.docs) {
                  final docData = doc.data() as Map<String, dynamic>;
                  if (docData['type'] == 'expense') {
                    totalExpenses += (docData['amount'] ?? 0.0) as double;
                  }
                }
              }

              final totalLoad = emi + totalExpenses;
              final netSavings = salary - totalLoad;
              final toInvest = netSavings > 0 ? netSavings * 0.3 : 0.0;
              final loadPercentage = salary > 0 ? (totalLoad / salary) * 100 : 0.0;

              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          TabBar(
                            controller: _tabController,
                            labelColor: AppColors.darkGreen,
                            unselectedLabelColor: AppColors.textLight,
                            indicatorColor: AppColors.darkGreen,
                            indicatorWeight: 3,
                            tabs: [
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(LucideIcons.lineChart, size: 16, color: Colors.redAccent),
                                    SizedBox(width: 8),
                                    Text('Stocks'),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(LucideIcons.coins, size: 16, color: Colors.amber),
                                    SizedBox(width: 8),
                                    Text('SIP'),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(LucideIcons.landmark, size: 16, color: Colors.blueAccent),
                                    SizedBox(width: 8),
                                    Text('ETF'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _buildFinancialAnalysisCard(
                              salary: salary,
                              fixedBills: emi,
                              spending: totalExpenses,
                              totalLoad: totalLoad,
                              netSavings: netSavings,
                              toInvest: toInvest,
                              loadPercentage: loadPercentage,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: _buildRiskFilterChips(),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInvestmentList(stocks, toInvest),
                    _buildInvestmentList(sips, toInvest),
                    _buildInvestmentList(etfs, toInvest),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFinancialAnalysisCard({
    required double salary,
    required double fixedBills,
    required double spending,
    required double totalLoad,
    required double netSavings,
    required double toInvest,
    required double loadPercentage,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A5A41), // Deep green background matching image
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.barChart2, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'YOUR FINANCIAL ANALYSIS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Load: ${loadPercentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn('Salary', salary, Colors.white),
              _buildStatColumn('Fixed Bills', fixedBills, Colors.redAccent),
              _buildStatColumn('Spending', spending, Colors.orangeAccent),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn('Total Load', totalLoad, Colors.redAccent),
              _buildStatColumn('Net Savings', netSavings, Colors.greenAccent),
              _buildStatColumn('To Invest', toInvest, Colors.amber),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.sparkles, color: Colors.amber, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invest ₹${formatINR(toInvest)}/mo (30% of savings)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Moderate savings. Start SIPs in index funds, keep investments conservative.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, double value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${formatINR(value)}',
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRiskFilterChips() {
    return Row(
      children: [
        Expanded(child: _buildRiskChip('High Risk', Colors.redAccent)),
        const SizedBox(width: 8),
        Expanded(child: _buildRiskChip('Medium Risk', Colors.amber)),
        const SizedBox(width: 8),
        Expanded(child: _buildRiskChip('Low Risk', Colors.green)),
      ],
    );
  }

  Widget _buildRiskChip(String risk, Color color) {
    bool isSelected = _selectedRisk == risk;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedRisk == risk) {
            _selectedRisk = null; // deselect
          } else {
            _selectedRisk = risk;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? null : Border.all(color: Colors.grey.shade200),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              risk == 'Medium Risk' ? 'Med Risk' : risk,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentList(List<InvestmentOption> options, double recommendedAmount) {
    List<InvestmentOption> filteredOptions = options;
    if (_selectedRisk != null) {
      filteredOptions = options.where((o) => o.risk == _selectedRisk).toList();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 40),
      itemCount: filteredOptions.length,
      itemBuilder: (context, index) {
        final option = filteredOptions[index];
        return _buildInvestmentCard(option, recommendedAmount);
      },
    );
  }

  Widget _buildInvestmentCard(InvestmentOption option, double recommendedAmount) {
    // Generate projection values based on suggested amount
    double v1y = _calculateReturn(option.suggestedAmount, option.expectedAnnualReturn, 1, option.type);
    double v2y = _calculateReturn(option.suggestedAmount, option.expectedAnnualReturn, 2, option.type);
    double v5y = _calculateReturn(option.suggestedAmount, option.expectedAnnualReturn, 5, option.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.trendingUp, color: Colors.redAccent, size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.name,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.symbol,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'SIP ₹${formatINR(option.suggestedAmount)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(option.expectedAnnualReturn * 100).toStringAsFixed(0)}%/yr',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              option.description,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFBF9),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildProjectionCol('1 Year', v1y, Colors.blueAccent),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                _buildProjectionCol('2 Years', v2y, Colors.orangeAccent),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                _buildProjectionCol('5 Years', v5y, Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectionCol(String label, double value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${formatINR(value)}',
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class InvestmentOption {
  final String name;
  final String symbol;
  final String type;
  final String risk;
  final double expectedAnnualReturn;
  final String description;
  final double suggestedAmount;

  InvestmentOption({
    required this.name,
    required this.symbol,
    required this.type,
    required this.risk,
    required this.expectedAnnualReturn,
    required this.description,
    required this.suggestedAmount,
  });
}
