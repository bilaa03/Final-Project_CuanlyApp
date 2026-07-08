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
        return const Color(0xFF10B981);
      case 'sapphire':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFCCA352);
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
      backgroundColor: const Color(0xFF0F0F14),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Analisis Pengeluaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 18),
          
          if (expenses.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: const Text('Belum ada transaksi pengeluaran dicatat.', style: TextStyle(color: Color(0xFF8B8A88))),
            )
          else ...[
            // Total Expenses summary card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C24),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Belanja Bulan Ini', style: TextStyle(color: Color(0xFF8B8A88), fontSize: 11)),
                  const SizedBox(height: 6),
                  Text(
                    'Rp ${NumberFormat.format(totalExpenses)}',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            const Text('Pembagian Kategori', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
                  color: const Color(0xFF1C1C24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cat, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(3)),
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
          ],
        ],
      ),
    );
  }

  String formatIDR(double amount) {
    return 'Rp ${NumberFormat.format(amount)}';
  }
}
