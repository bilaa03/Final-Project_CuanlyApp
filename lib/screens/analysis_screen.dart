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
          ],
        ],
      ),
    );
  }

  String formatIDR(double amount) {
    return 'Rp ${NumberFormat.format(amount)}';
  }
}
