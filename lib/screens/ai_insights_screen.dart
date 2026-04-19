import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ai_finance_manager/services/ai_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AiInsightsScreen extends StatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> {
  late Future<String> _insightsFuture;
  int _selectedTabIndex = 0;
  final List<String> _tabs = ["🍔 Food", "🛍️ Shopping", "⛽ Fuel"];

  @override
  void initState() {
    super.initState();
    _insightsFuture = AIService.getFinancialInsights();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3), // Light grey background like screenshot
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F3F3),
        elevation: 0,
        title: const Text('Smart Savings', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: FutureBuilder<String>(
        future: _insightsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(LucideIcons.sparkles, color: Color(0xFF133b2b), size: 48),
                   const SizedBox(height: 24),
                   const Text("Scanning global card networks...", style: TextStyle(color: Colors.black54, fontSize: 16)),
                   const SizedBox(height: 16),
                   const CircularProgressIndicator(color: Color(0xFF133b2b)),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
              ),
            );
          }

          var rawData = snapshot.data ?? "[]";
          // Clean JSON from possible markdown wrappers
          rawData = rawData.replaceAll(RegExp(r'```json\n?'), '').replaceAll(RegExp(r'```\n?'), '').trim();
          
          Map<String, dynamic> dataMap = {};
          try {
            dataMap = jsonDecode(rawData);
          } catch(e) {
            return Center(child: Text('AI returned non-standard data: $rawData'));
          }

          List<dynamic> foodCards = dataMap['foodCards'] ?? [];
          List<dynamic> shoppingCards = dataMap['shoppingCards'] ?? [];
          List<dynamic> fuelCards = dataMap['fuelCards'] ?? [];
          
          List<List<dynamic>> allCategories = [foodCards, shoppingCards, fuelCards];
          List<dynamic> currentCards = _selectedTabIndex < allCategories.length ? allCategories[_selectedTabIndex] : [];

          if (foodCards.isEmpty && shoppingCards.isEmpty && fuelCards.isEmpty) {
            return const Center(child: Text('No suitable cards found.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Curated for You", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // TAB BAR
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    scrollDirection: Axis.horizontal,
                    itemCount: _tabs.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      bool isSelected = _selectedTabIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.black : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300),
                          ),
                          child: Center(
                            child: Text(
                              _tabs[index],
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                
                // VERTICAL CARD LIST
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: List.generate(currentCards.length, (index) {
                      final cardData = currentCards[index] as Map<String, dynamic>;
                      bool isBlack = index == 0; // Top is black
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: _buildPhysicalCard(cardData, isBlack, index),
                      );
                    }),
                  ),
                ),
                
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _insightsFuture = AIService.getFinancialInsights();
                        });
                      },
                      icon: const Icon(LucideIcons.refreshCw, size: 18, color: Colors.white),
                      label: const Text('Rescan Networks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF133b2b),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhysicalCard(Map<String, dynamic> data, bool isBlack, int index) {
    Color bgColor = isBlack ? const Color(0xFF1A1A1A) : Colors.white;
    Color textColor = isBlack ? Colors.white : Colors.black;
    Color subTextColor = isBlack ? Colors.white70 : Colors.black54;
    
    final user = FirebaseAuth.instance.currentUser;
    String name = user?.displayName ?? "VALUED MEMBER";
    
    String randNum = "834${5+index}";
    
    double estSaving = double.tryParse(data['estimatedSavings']?.toString() ?? '0') ?? 0;
    double annFee = double.tryParse(data['annualFee']?.toString() ?? '0') ?? 0;
    double netSaving = estSaving - (annFee / 12.0);
    
    String sign = netSaving >= 0 ? '+' : '-';
    String formattedNet = '$sign₹${netSaving.abs().toStringAsFixed(0)}';
    
    return GestureDetector(
      onTap: () => _showCardDetails(context, data, isBlack, annFee, netSaving),
      child: Container(
        height: 240, // Increased to fit the highlight bubble
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isBlack ? 0.2 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.cpu, color: textColor.withOpacity(0.8), size: 28),
                    const SizedBox(width: 8),
                    Icon(LucideIcons.wifi, color: textColor.withOpacity(0.8), size: 18),
                  ],
                ),
                Text('**** **** **** $randNum', style: TextStyle(color: subTextColor, fontFamily: 'monospace', fontSize: 14)),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isBlack ? Colors.white.withOpacity(0.15) : const Color(0xFFEAF5EE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(data['highlight'] ?? 'High Savings', style: TextStyle(color: isBlack ? Colors.white : const Color(0xFF133b2b), fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                 Text('$formattedNet /mo', style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1.0)),
                 const SizedBox(width: 6),
                 Padding(
                   padding: const EdgeInsets.only(bottom: 6.0),
                   child: Text('(Net)', style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
                 )
              ]
            ),
            const SizedBox(height: 4),
            Text('${data['cardName']}', style: TextStyle(color: subTextColor, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.toUpperCase(), style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('Fee: ₹${annFee.toStringAsFixed(0)} /yr', style: TextStyle(color: subTextColor, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        (data['network'] ?? 'VISA').toString().toUpperCase(), 
                        style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showCardDetails(BuildContext context, Map<String, dynamic> data, bool isBlack, double annFee, double netSaving) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        List<dynamic> benefits = data['keyBenefits'] ?? ["Personalized savings based on your spend habits.", "Optimized for your specific expense categories."];
        String sign = netSaving >= 0 ? '+' : '-';
        Color netColor = netSaving >= 0 ? Colors.green.shade700 : Colors.red.shade700;
        
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 24),
              Text(data['cardName'] ?? 'Card Details', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFEAF5EE), borderRadius: BorderRadius.circular(20)),
                child: Text(data['highlight'] ?? 'High Savings', style: const TextStyle(color: Color(0xFF133b2b), fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(height: 32),
              const Text("Key Benefits ✨", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              ...benefits.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(b.toString(), style: TextStyle(color: Colors.grey.shade800, fontSize: 16, height: 1.4))),
                  ],
                ),
              )).toList(),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Annual Fee", style: TextStyle(color: Colors.grey, fontSize: 14)),
                        Text("₹${annFee.toStringAsFixed(0)}", style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Net Est. Saving", style: TextStyle(color: Colors.grey, fontSize: 14)),
                        Text("$sign₹${netSaving.abs().toStringAsFixed(0)}/mo", style: TextStyle(color: netColor, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Got it', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      }
    );
  }
}
