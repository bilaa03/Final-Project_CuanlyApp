import 'package:flutter/material.dart';
import 'dart:math';
import '../models/transaction.dart';
import '../models/wallet.dart';

// Helper class for number formatting
class NumberFormat {
  static String format(double number) {
    bool hasDecimal = (number % 1) != 0;
    if (hasDecimal) {
      String str = number.toStringAsFixed(2);
      List<String> parts = str.split('.');
      String integerPart = parts[0];
      String decimalPart = parts[1];
      RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      String formattedInteger = integerPart.replaceAllMapped(reg, (Match match) => '${match[1]}.');
      return '$formattedInteger,$decimalPart';
    } else {
      String str = number.toStringAsFixed(0);
      RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      return str.replaceAllMapped(reg, (Match match) => '${match[1]}.');
    }
  }
}

// Count-up animation for balance
class CountUpText extends StatefulWidget {
  final double value;
  final TextStyle style;
  final Duration duration;

  const CountUpText({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0.0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: oldWidget.value, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          'Rp ${NumberFormat.format(_animation.value)}',
          style: widget.style,
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final double totalSaldo;
  final double totalPemasukan;
  final double totalPengeluaran;
  final double budgetLimit;
  final List<TransactionItem> transactions;
  final List<WalletItem> wallets;
  final VoidCallback onScanClick;
  final Function(int) onNavigateToTab;

  const HomeScreen({
    super.key,
    required this.totalSaldo,
    required this.totalPemasukan,
    required this.totalPengeluaran,
    required this.budgetLimit,
    required this.transactions,
    required this.wallets,
    required this.onScanClick,
    required this.onNavigateToTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedMonthIndex = 2; // 0: April, 1: Mei, 2: Juni
  final List<String> _months = ['April 2026', 'Mei 2026', 'Juni 2026'];

  // Mock data for previous months
  final Map<int, Map<String, double>> _monthlyData = {
    0: {'Makanan': 450000, 'Transport': 120000, 'Belanja': 800000, 'Hiburan': 300000, 'Lainnya': 100000},
    1: {'Makanan': 500000, 'Transport': 180000, 'Belanja': 600000, 'Hiburan': 450000, 'Lainnya': 150000},
    2: {'Makanan': 650000, 'Transport': 320000, 'Belanja': 430000, 'Hiburan': 90000, 'Lainnya': 210000},
  };

  String? _tappedCategory;
  double? _tappedCategoryAmount;

  @override
  Widget build(BuildContext context) {
    final double totalBudgetUsed = widget.totalPengeluaran;
    final double budgetPct = widget.budgetLimit > 0 ? (totalBudgetUsed / widget.budgetLimit) : 0.0;
    
    // Semantic color coding for budget progress bar
    Color budgetColor = const Color(0xFF059669); // Green
    if (budgetPct > 0.9) {
      budgetColor = const Color(0xFFEF4444); // Red
    } else if (budgetPct > 0.7) {
      budgetColor = const Color(0xFFF59E0B); // Yellow/Amber
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Top Bar: Streak + Badge
          _buildStreakHeader(),
          const SizedBox(height: 24),

          // Total Balance count-up Card
          _buildBalanceCard(),
          const SizedBox(height: 24),

          // Budget Progress Section
          _buildBudgetProgress(budgetPct, totalBudgetUsed, budgetColor),
          const SizedBox(height: 28),

          // Interactive Spending Chart
          _buildInteractiveChart(),
          const SizedBox(height: 28),

          // AI Balance Prediction Pace Section
          _buildPredictivePaceSection(),
          const SizedBox(height: 28),

          // Financial Goals Tracker Section
          _buildGoalsTrackerSection(),
          const SizedBox(height: 28),

          // Subscription Auto Detector Section
          _buildSubscriptionDetectorSection(),
          const SizedBox(height: 28),

          // Recent Activity Quick View
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildStreakHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Daily Streak Chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFD85A30).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD85A30).withOpacity(0.2)),
          ),
          child: const Row(
            children: [
              Text('🔥', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text(
                '5 Hari Streak!',
                style: TextStyle(
                  color: Color(0xFFD85A30),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Achievements Badge + Bell
        Row(
          children: [
            _buildBadgeIcon('🏆', 'Hemat Master', 'Berhasil belanja di bawah budget bulan ini!'),
            const SizedBox(width: 6),
            _buildBadgeIcon('⚡', 'AI Learner', 'Sudah mencoba fitur tanya jawab Cuanly.'),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _showNotificationsBottomSheet,
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Icon(Icons.notifications_active, color: Color(0xFF6366F1), size: 16),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildBadgeIcon(String emoji, String title, String description) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              description,
              style: const TextStyle(color: Color(0xFF475569), fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keren!', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.25),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Saldo Cuanly',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: widget.onScanClick,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.camera_alt, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Scan Bon',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CountUpText(
            value: widget.totalSaldo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward, color: Color(0xFF34D399), size: 14),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pemasukan', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        Text(
                          'Rp ${NumberFormat.format(widget.totalPemasukan)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 28, color: Colors.white24),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_downward, color: Color(0xFFF87171), size: 14),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pengeluaran', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        Text(
                          'Rp ${NumberFormat.format(widget.totalPengeluaran)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetProgress(double budgetPct, double totalBudgetUsed, Color budgetColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Batas Anggaran Bulanan',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '${(budgetPct * 100).toStringAsFixed(0)}% Terpakai',
                style: TextStyle(
                  color: budgetColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Animated Progress Bar
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: budgetPct > 1.0 ? 1.0 : budgetPct),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: budgetColor,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: budgetColor.withOpacity(0.2),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terpakai: Rp ${NumberFormat.format(totalBudgetUsed)}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
              ),
              Text(
                'Limit: Rp ${NumberFormat.format(widget.budgetLimit)}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveChart() {
    final Map<String, double> categoriesData = _monthlyData[_selectedMonthIndex]!;
    final double maxVal = categoriesData.values.fold(0, (max, val) => val > max ? val : max);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Selector (Swipe/Tap simulator)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Analisis Kategori',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Color(0xFF475569), size: 20),
                    onPressed: _selectedMonthIndex > 0
                        ? () => setState(() {
                              _selectedMonthIndex--;
                              _tappedCategory = null;
                            })
                        : null,
                  ),
                  Text(
                    _months[_selectedMonthIndex],
                    style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Color(0xFF475569), size: 20),
                    onPressed: _selectedMonthIndex < _months.length - 1
                        ? () => setState(() {
                              _selectedMonthIndex++;
                              _tappedCategory = null;
                            })
                        : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          
          // Graphic Area with Swipe listener
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                // Swipe right -> Previous Month
                if (_selectedMonthIndex > 0) {
                  setState(() {
                    _selectedMonthIndex--;
                    _tappedCategory = null;
                  });
                }
              } else if (details.primaryVelocity! < 0) {
                // Swipe left -> Next Month
                if (_selectedMonthIndex < _months.length - 1) {
                  setState(() {
                    _selectedMonthIndex++;
                    _tappedCategory = null;
                  });
                }
              }
            },
            child: SizedBox(
              height: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: categoriesData.entries.map((entry) {
                  final catName = entry.key;
                  final catAmt = entry.value;
                  final double heightPct = maxVal > 0 ? (catAmt / maxVal) : 0.0;
                  final isSelected = _tappedCategory == catName;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_tappedCategory == catName) {
                            _tappedCategory = null;
                            _tappedCategoryAmount = null;
                          } else {
                            _tappedCategory = catName;
                            _tappedCategoryAmount = catAmt;
                          }
                        });
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Tooltip if selected
                          AnimatedOpacity(
                            opacity: isSelected ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Rp ${NumberFormat.format(catAmt)}',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Chart Bar with animation
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            height: heightPct * 90 + 10,
                            width: isSelected ? 24 : 16,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isSelected
                                    ? [const Color(0xFF059669), const Color(0xFF10B981)]
                                    : [const Color(0xFFC7D2FE), const Color(0xFF818CF8)],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF059669).withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            catName.substring(0, min(3, catName.length)),
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Selection feedback info card
          if (_tappedCategory != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF059669), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Total pengeluaran kategori $_tappedCategory bulan ${_months[_selectedMonthIndex]} adalah Rp ${NumberFormat.format(_tappedCategoryAmount!)}.',
                      style: const TextStyle(color: Color(0xFF334155), fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recent = widget.transactions.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Aktivitas Terakhir',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigateToTab(2), // Route to Transaction screen
              child: const Text(
                'Lihat Semua',
                style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            child: const Text(
              'Belum ada transaksi.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recent.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final tx = recent[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.04)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.01),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    // Category icon wrapper
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (tx.isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        tx.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                        color: tx.isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.title,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${tx.category} • ${tx.wallet}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${tx.isExpense ? "-" : "+"} Rp ${NumberFormat.format(tx.amount)}',
                      style: TextStyle(
                        color: tx.isExpense ? const Color(0xFF0F172A) : const Color(0xFF10B981),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPredictivePaceSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Prediksi Saldo Akhir Bulan',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimasi Saldo Sisa', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${NumberFormat.format(widget.totalSaldo - 450000)}',
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '💡 Pace Aman',
                  style: TextStyle(color: Color(0xFF065F46), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Cuanly: Laju belanjamu stabil. Sisa Rp 1.500.000 dari limit anggaran bulananmu.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.3),
          )
        ],
      ),
    );
  }

  Widget _buildGoalsTrackerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Target Menabung (Goals)',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _buildGoalItem('💻 Beli Laptop Baru', 4500000, 7500000, const Color(0xFF6366F1)),
        const SizedBox(height: 12),
        _buildGoalItem('🛡️ Dana Darurat 2026', 1500000, 3000000, const Color(0xFF059669)),
      ],
    );
  }

  Widget _buildGoalItem(String title, double current, double target, Color progressColor) {
    final double pct = target > 0 ? (current / target) : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13)),
              Text(
                'Rp ${NumberFormat.format(current)} / Rp ${NumberFormat.format(target)}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
              )
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(3)),
              ),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(color: progressColor, borderRadius: BorderRadius.circular(3)),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tercapai ${(pct * 100).toStringAsFixed(0)}% — Nabung Rp 500.000 lagi bulan ini untuk tetap on-track.',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
          )
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetectorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deteksi Langganan Otomatis',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              _buildSubscriptionItem(
                name: 'Spotify Premium',
                price: 'Rp 54.990/bln',
                status: 'Sering digunakan',
                color: const Color(0xFF059669),
                isWarning: false,
              ),
              const Divider(color: Colors.black12, height: 24),
              _buildSubscriptionItem(
                name: 'Netflix Premium',
                price: 'Rp 186.000/bln',
                status: 'Jarang digunakan',
                color: const Color(0xFFEF4444),
                isWarning: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionItem({
    required String name,
    required String price,
    required String status,
    required Color color,
    required bool isWarning,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(price, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
            if (isWarning) ...[
              const SizedBox(height: 4),
              const Text(
                '💡 Hemat: Downgrade aja!',
                style: TextStyle(color: Color(0xFFF59E0B), fontSize: 9, fontWeight: FontWeight.bold),
              )
            ]
          ],
        )
      ],
    );
  }

  void _showNotificationsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active, color: Color(0xFF6366F1)),
                    SizedBox(width: 8),
                    Text(
                      'Pemberitahuan Pintar',
                      style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 16),
            _buildNotificationItem(
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFF59E0B),
              title: 'Limit Anggaran Makanan',
              desc: 'Anggaran Makanan sudah terpakai 85%! Pikir-pikir lagi sebelum ngopi santai ya.',
            ),
            _buildNotificationItem(
              icon: Icons.event_repeat,
              color: const Color(0xFF059669),
              title: 'Tagihan Spotify Premium',
              desc: 'Tagihan Spotify Rp 54.999 jatuh tempo besok. Saldo GoPay terdebit otomatis.',
            ),
            _buildNotificationItem(
              icon: Icons.insights,
              color: const Color(0xFF6366F1),
              title: 'Rangkuman Mingguan',
              desc: 'Hebat! Pengeluaran mingguanmu turun 12% dibanding minggu lalu. Teruskan hematnya!',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 11, height: 1.3),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
