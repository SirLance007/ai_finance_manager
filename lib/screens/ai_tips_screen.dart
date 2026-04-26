import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ai_finance_manager/theme/app_colors.dart';
import 'package:ai_finance_manager/services/ai_service.dart';

class AiTipsScreen extends StatefulWidget {
  const AiTipsScreen({super.key});

  @override
  State<AiTipsScreen> createState() => _AiTipsScreenState();
}

class _AiTipsScreenState extends State<AiTipsScreen> {
  late Future<String> _tipsFuture;
  final int _streakDays = 3;

  @override
  void initState() {
    super.initState();
    _tipsFuture = AIService.getSmartTips();
  }

  void _refresh() {
    setState(() {
      _tipsFuture = AIService.getSmartTips();
    });
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'warning': return LucideIcons.car;
      case 'opportunity': return LucideIcons.piggyBank;
      default: return LucideIcons.pieChart;
    }
  }

  Color _badgeColor(String badge) {
    switch (badge) {
      case 'Needs Attention': return Colors.redAccent;
      case 'Great Opportunity': return AppColors.darkGreen;
      default: return AppColors.darkGreen;
    }
  }

  IconData _badgeIcon(String badge) {
    switch (badge) {
      case 'Needs Attention': return LucideIcons.alertTriangle;
      default: return LucideIcons.sparkles;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textDark, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Smart Insights for You',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: AppColors.darkGreen, size: 20),
            onPressed: _refresh,
            tooltip: 'Refresh Tips',
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _tipsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.darkGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.sparkles, color: AppColors.darkGreen, size: 40),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Gemini AI is analyzing\nyour finances...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(color: AppColors.darkGreen),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
            );
          }

          final raw = (snapshot.data ?? '[]')
              .replaceAll(RegExp(r'```json\n?'), '')
              .replaceAll(RegExp(r'```\n?'), '')
              .trim();

          List<dynamic> tips = [];
          try {
            tips = jsonDecode(raw) as List<dynamic>;
          } catch (_) {
            tips = [];
          }

          if (tips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.lightbulb, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Add some expenses first to get\npersonalized AI tips!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textLight, fontSize: 15)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(LucideIcons.refreshCw, size: 16, color: Colors.white),
                    label: const Text('Try Again', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  )
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Personalized AI tips to help you save more',
                    style: TextStyle(color: AppColors.textLight, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 24),

                // AI-generated tip cards
                ...tips.map((tip) {
                  final t = tip as Map<String, dynamic>;
                  return _buildTipCard(t);
                }),

                const SizedBox(height: 8),

                // Streak card
                _buildStreakCard(),

                const SizedBox(height: 20),

                // Privacy footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.shieldCheck, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 6),
                    Text(
                      'All insights are 100% private and secure.\nOnly you can see your data.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTipCard(Map<String, dynamic> tip) {
    final badge = tip['badge'] as String? ?? 'Recommended';
    final title = tip['title'] as String? ?? '';
    final description = tip['description'] as String? ?? '';
    final actionLabel = tip['actionLabel'] as String? ?? '';
    final type = tip['type'] as String? ?? 'recommended';
    final hasProgressBar = tip['hasProgressBar'] as bool? ?? false;
    final currentAmount = (tip['currentAmount'] as num?)?.toDouble() ?? 0;
    final previousAmount = (tip['previousAmount'] as num?)?.toDouble() ?? 0;
    final percentChange = (tip['percentChange'] as num?)?.toDouble() ?? 0;

    final badgeColor = _badgeColor(badge);
    final icon = _iconForType(type);
    final badgeIc = _badgeIcon(badge);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.darkGreen, size: 26),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIc, size: 11, color: badgeColor),
                          const SizedBox(width: 4),
                          Text(
                            badge,
                            style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    // Amount row for Needs Attention
                    if (hasProgressBar && currentAmount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '₹${currentAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('this month', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                          const SizedBox(width: 6),
                          const Icon(LucideIcons.arrowUp, color: Colors.redAccent, size: 14),
                          Text(
                            '${percentChange.abs().toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: AppColors.textLight, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
          ),
          // Progress bar
          if (hasProgressBar && currentAmount > 0 && previousAmount > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text('vs last month', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (previousAmount / currentAmount).clamp(0.0, 1.0),
                      backgroundColor: Colors.redAccent.withOpacity(0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('₹${previousAmount.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ],
          // Action button
          if (actionLabel.isNotEmpty) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.darkGreen.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type == 'recommended' ? LucideIcons.barChart2 : LucideIcons.chevronRight,
                      size: 14,
                      color: AppColors.darkGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      actionLabel,
                      style: const TextStyle(
                        color: AppColors.darkGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: Colors.white70, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Tipstreak',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Keep following tips to build better habits!',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '$_streakDays 🔥',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Text('days streak', style: TextStyle(color: Colors.white60, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(7, (i) {
              final active = i < _streakDays;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? Colors.greenAccent : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
