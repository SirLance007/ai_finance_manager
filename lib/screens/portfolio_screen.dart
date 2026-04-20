import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ai_finance_manager/theme/app_colors.dart';
import 'package:ai_finance_manager/services/finance_api_service.dart';
import 'package:ai_finance_manager/screens/add_asset_screen.dart';

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

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final user = FirebaseAuth.instance.currentUser;
  
  Map<String, Map<String, double>> liveDataCache = {};
  bool _isRefreshing = false;
  Timer? _pollingTimer;
  List<DocumentSnapshot>? _currentDocs;
  String _selectedFilter = 'All Stocks';

  int _apiCounter = 0;

  @override
  void initState() {
    super.initState();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (liveDataCache.isNotEmpty && mounted) {
        setState(() {
          liveDataCache.forEach((key, data) {
            final price = data['currentPrice'] ?? 0.0;
            if (price > 0) {
              // +- 0.05% jitter every 2 seconds
              final randomJitter = 1.0 + ((DateTime.now().millisecond % 50) - 25) / 100000;
              data['currentPrice'] = price * randomJitter;
            }
          });
        });
      }

      _apiCounter++;
      if (_apiCounter >= 5) {
        _apiCounter = 0;
        if (_currentDocs != null && _currentDocs!.isNotEmpty) {
          _fetchLivePrices(_currentDocs!);
        }
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLivePrices(List<DocumentSnapshot> docs) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    
    for (var doc in docs) {
      final ticker = doc['ticker'].toString();
      final data = await FinanceApiService.getLivePrice(ticker);
      if (data != null) {
        liveDataCache[ticker] = data;
      }
    }
    
    if (mounted) setState(() => _isRefreshing = false);
  }

  String _getDomainFromTicker(String ticker) {
    String base = ticker.split('.').first.toLowerCase();
    if (base == 'reliance') return 'ril.com';
    if (base == 'tcs') return 'tcs.com';
    if (base == 'infy') return 'infosys.com';
    if (base == 'swiggy') return 'swiggy.com';
    if (base == 'zomato') return 'zomato.com';
    if (base == 'paytm') return 'paytm.com';
    if (base == 'hdfcbank') return 'hdfcbank.com';
    if (ticker.contains('BTC')) return 'bitcoin.org';
    if (ticker.contains('ETH')) return 'ethereum.org';
    return '$base.com';
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Center(child: Text("Please log in."));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .collection('portfolio')
              .orderBy('dateAdded', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final docs = snapshot.data!.docs;
            _currentDocs = docs;
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchLivePrices(docs);
            });

            double totalInvested = 0;
            double currentValue = 0;
            
            List<Map<String, dynamic>> holdingList = [];

            for (var doc in docs) {
              final ticker = doc['ticker'].toString();
              final qty = (doc['quantity'] as num).toDouble();
              final buyPrice = (doc['buyPrice'] as num).toDouble();
              
              final liveData = liveDataCache[ticker];
              final cp = liveData?['currentPrice'] ?? buyPrice;
              final prevClose = liveData?['previousClose'] ?? buyPrice;
              
              final invVal = qty * buyPrice;
              final curVal = qty * cp;
              
              totalInvested += invVal;
              currentValue += curVal;
              
              final pnl = curVal - invVal;
              final dailyPnl = curVal - (qty * prevClose);
              final itemPnlPercent = buyPrice > 0 ? ((cp - buyPrice) / buyPrice) * 100 : 0.0;
              
              holdingList.add({
                'id': doc.id,
                'ticker': ticker,
                'domain': _getDomainFromTicker(ticker),
                'qty': qty,
                'buyPrice': buyPrice,
                'currentPrice': cp,
                'invested': invVal,
                'currentValue': curVal,
                'pnl': pnl,
                'dailyPnl': dailyPnl,
                'pnlPercent': itemPnlPercent,
              });
            }

            final totalPnl = currentValue - totalInvested;
            final double pnlPercent = totalInvested > 0 ? (totalPnl / totalInvested) * 100 : 0.0;
            
            // Filter list logic
            if (_selectedFilter == 'Gainers') {
              holdingList = holdingList.where((i) => i['pnl'] >= 0).toList();
            } else if (_selectedFilter == 'Losers') {
              holdingList = holdingList.where((i) => i['pnl'] < 0).toList();
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(child: _buildTopCard(totalInvested, currentValue, totalPnl, pnlPercent)),
                SliverToBoxAdapter(child: const SizedBox(height: 32)),
                SliverToBoxAdapter(child: _buildSectionHeader()),
                SliverToBoxAdapter(child: _buildFilterChips()),
                SliverToBoxAdapter(child: const SizedBox(height: 16)),
                holdingList.isEmpty 
                  ? SliverToBoxAdapter(child: _buildEmptyState())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == holdingList.length) {
                             return _buildInsightCard(pnlPercent);
                          }
                          return _buildHoldingItem(holdingList[index]);
                        },
                        childCount: holdingList.length + 1,
                      ),
                    ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Portfolio', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text('Track. Grow. Succeed.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            ],
          ),
          Row(
            children: [
              Stack(
                children: [
                  const Icon(LucideIcons.bell, color: AppColors.textDark, size: 28),
                  Positioned(
                    right: 4, top: 4,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    ),
                  )
                ],
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAssetScreen())),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: AppColors.darkGreen, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.plus, color: Colors.white, size: 24),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTopCard(double invested, double current, double pnl, double pnlPercent) {
    bool isPositive = pnl >= 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primaryGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text("CURRENT VALUE", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(width: 8),
                  Icon(LucideIcons.eye, color: Colors.white.withOpacity(0.7), size: 14),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text("All Time", style: TextStyle(color: Colors.white, fontSize: 12)),
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.chevronDown, color: Colors.white, size: 14),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text("₹${formatINR(current)}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -1)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(isPositive ? LucideIcons.arrowUp : LucideIcons.arrowDown, color: isPositive ? Colors.greenAccent : Colors.redAccent, size: 16),
              const SizedBox(width: 4),
              Text("${pnlPercent.toStringAsFixed(2)}%", style: TextStyle(color: isPositive ? Colors.greenAccent : Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600)),
              Text("  |  ${isPositive ? '+' : '-'}₹${formatINR(pnl.abs())} today", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Dummy Sparkline Chart
          SizedBox(
            height: 60,
            width: double.infinity,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1), FlSpot(1, 1.2), FlSpot(2, 1.1), FlSpot(3, 1.8),
                      FlSpot(4, 1.5), FlSpot(5, 2.2), FlSpot(6, 2.0), FlSpot(7, 2.8),
                      FlSpot(8, 2.6), FlSpot(9, 3.4), FlSpot(10, 3.2), FlSpot(11, 4.0),
                    ],
                    isCurved: true,
                    color: Colors.greenAccent,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [Colors.greenAccent.withOpacity(0.15), Colors.greenAccent.withOpacity(0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TOTAL INVESTED", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text("₹${formatINR(invested)}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TOTAL RETURNS", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text("${isPositive ? '+' : '-'}₹${formatINR(pnl.abs())}", style: TextStyle(color: isPositive ? Colors.greenAccent : Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('Holdings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ],
          ),
          Row(
            children: [
              Text('View All', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryGreen)),
              const SizedBox(width: 2),
              const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.primaryGreen),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All Stocks', 'Gainers', 'Losers', 'Watchlist'];
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedFilter == filters[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filters[index]),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.darkGreen : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppColors.darkGreen : Colors.grey.shade300)
              ),
              child: Center(
                child: Text(
                  filters[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHoldingItem(Map<String, dynamic> item) {
    bool isPos = item['pnl'] >= 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.network(
                'https://www.google.com/s2/favicons?domain=${item['domain']}&sz=128',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.network(
                    'https://www.google.com/s2/favicons?domain=${item['ticker'].split('.').first.toLowerCase()}.in&sz=128',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.network(
                        'https://www.google.com/s2/favicons?domain=${item['ticker'].split('.').first.toLowerCase()}.co.in&sz=128',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(LucideIcons.candlestickChart, color: AppColors.primaryGreen, size: 24),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['ticker'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text("${item['qty']} Qty • Avg ₹${formatINR(item['buyPrice'])}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPos ? AppColors.pillGreen.withOpacity(0.6) : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6)
                  ),
                  child: Text(
                    "${isPos ? '+' : ''}${item['pnlPercent'].toStringAsFixed(2)}%",
                    style: TextStyle(color: isPos ? AppColors.primaryGreen : Colors.red, fontSize: 11, fontWeight: FontWeight.bold)
                  ),
                )
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("₹${formatINR(item['currentValue'])}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textDark)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(isPos ? LucideIcons.trendingUp : LucideIcons.trendingDown, color: isPos ? AppColors.primaryGreen : Colors.red, size: 14),
                  const SizedBox(width: 4),
                  Text("₹${item['currentPrice'].toStringAsFixed(2)}", style: TextStyle(color: isPos ? AppColors.primaryGreen : Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInsightCard(double pnlPercent) {
    bool isPos = pnlPercent >= 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkGreen.withOpacity(0.1))
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(LucideIcons.pieChart, color: AppColors.darkGreen, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Your portfolio is ${isPos ? 'up' : 'down'} by ${pnlPercent.abs().toStringAsFixed(2)}% today.", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(isPos ? "Keep it up! You're making great progress." : "Don't panic! Markets fluctuate often.", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              Text("Analyze", style: TextStyle(color: AppColors.darkGreen, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Icon(LucideIcons.arrowRight, size: 16, color: AppColors.darkGreen),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(LucideIcons.briefcase, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No assets in portfolio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text("Add your stocks or crypto below to\ntrack live gains.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.5)),
        ],
      )
    );
  }
}
