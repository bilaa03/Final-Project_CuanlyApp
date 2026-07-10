import 'package:flutter/material.dart';
import '../models/transaction.dart';
import 'home_screen.dart'; // import format helper

class AnalysisScreen extends StatelessWidget {
  final List<TransactionItem> transactions;
  final String currentAccent;

  const AnalysisScreen({
    super.key,
    required this.transactions,
    required this.currentAccent,
  });

  Color _getPrimaryColor() {
    switch (currentAccent) {
      case 'emerald':
        return const Color(0xFF059669);
      case 'sapphire':
        return const Color(0xFF1D4ED8);
      default:
        return const Color(0xFFD97706);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getPrimaryColor();
    
    // Group expenditures
    final expenses = transactions.where((t) => t.isExpense).toList();
    final double totalExpenses = expenses.fold(0, (sum, t) => sum + t.amount);
    
    final Map<String, double> categorySums = {};
    for (var tx in expenses) {
      categorySums[tx.category] = (categorySums[tx.category] ?? 0) + tx.amount;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Analisis Pengeluaran', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 18),
          
          if (expenses.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: const Text('Belum ada transaksi pengeluaran dicatat.', style: TextStyle(color: Color(0xFF64748B))),
            )
          else ...[
            // Total Expenses summary card with brand gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Belanja Bulan Ini', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 6),
                  Text(
                    'Rp ${NumberFormat.format(totalExpenses)}',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            const Text('Pembagian Kategori', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),

            // Category percentages lists
            ...categorySums.entries.map((entry) {
              final cat = entry.key;
              final amt = entry.value;
              final double pct = totalExpenses > 0 ? (amt / totalExpenses) : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cat, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(
                          '${(pct * 100).toStringAsFixed(0)}% (${formatIDR(amt)})',
                          style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress Line
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
                            decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(3)),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            
            const Text('Statistik Belanja', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Rata-rata Harian', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                            Text('📅', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rp ${NumberFormat.format(totalExpenses / 30)}',
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Frekuensi Belanja', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                            Text('🛍️', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${expenses.length} Kali',
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // AI Smart Tip Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryColor.withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        'Rekomendasi Cerdas Cuanly',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getAiTip(categorySums, totalExpenses),
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getAiTip(Map<String, double> categorySums, double totalExpenses) {
    if (totalExpenses == 0) return 'Pertahankan pola hemat Anda untuk bulan ini!';
    
    String highestCategory = '';
    double highestAmount = 0;
    for (var entry in categorySums.entries) {
      if (entry.value > highestAmount) {
        highestAmount = entry.value;
        highestCategory = entry.key;
      }
    }
    if (highestCategory == 'Makanan') {
      return 'Pengeluaran Makanan Anda paling dominan (${(highestAmount / totalExpenses * 100).toStringAsFixed(0)}%). Cobalah batasi frekuensi makan di luar atau mulai bawa bekal makan siang untuk menghemat hingga 20% anggaran!';
    } else if (highestCategory == 'Transport') {
      return 'Biaya transportasi Anda bulan ini cukup tinggi. Manfaatkan promo langganan ojek online atau beralih ke transportasi umum jika memungkinkan.';
    } else if (highestCategory == 'Belanja') {
      return 'Pengeluaran belanja bulanan Anda cukup besar. Pastikan membuat daftar belanjaan yang mendetail terlebih dahulu untuk menghindari pembelian impulsif.';
    } else if (highestCategory.isNotEmpty) {
      return 'Kategori $highestCategory menyerap porsi anggaran terbesar. Tetapkan limit pengeluaran yang lebih ketat agar tabungan Anda meningkat.';
    }
    return 'Pertahankan pola keuangan sehat Anda untuk meningkatkan rasio tabungan bulan ini!';
  }

  String formatIDR(double amount) {
    return 'Rp ${NumberFormat.format(amount)}';
  }
}
