import 'package:flutter/material.dart';
import 'dart:async';
import '../models/transaction.dart';
import '../models/wallet.dart';
import 'home_screen.dart'; // import format helper

class TransactionScreen extends StatefulWidget {
  final List<TransactionItem> transactions;
  final List<WalletItem> wallets;
  final String currentAccent;
  final Function(String, double, String, bool, String) onAddTransaction;

  const TransactionScreen({
    super.key,
    required this.transactions,
    required this.wallets,
    required this.currentAccent,
    required this.onAddTransaction,
  });

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Form input controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _category = 'Makanan';
  bool _isExpense = true;
  late String _wallet;
  bool _useRoundUp = false;

  // Voice recording mock state
  bool _isListening = false;
  String _voiceStatus = 'Klik untuk bicara';

  // Split bill states
  final _splitBillController = TextEditingController();
  int _peopleCount = 2;
  double _splitResult = 0.0;
  final List<String> _friends = ['Andi', 'Siti', 'Budi'];

  final List<String> _categories = [
    'Makanan',
    'Transport',
    'Belanja',
    'Hiburan',
    'Lainnya',
    'Pemasukan'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _wallet = widget.wallets.isNotEmpty ? widget.wallets[0].name : 'Cash';

    // Set up smart category suggestion listener
    _titleController.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _amountController.dispose();
    _splitBillController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Smart suggestions category matching logic
  void _onTitleChanged() {
    final title = _titleController.text.toLowerCase();
    String? matchedCategory;

    if (title.contains('kopi') || title.contains('makan') || title.contains('cafe') || title.contains('starbucks') || title.contains('resto')) {
      matchedCategory = 'Makanan';
    } else if (title.contains('grab') || title.contains('gojek') || title.contains('ride') || title.contains('bensin') || title.contains('tol')) {
      matchedCategory = 'Transport';
    } else if (title.contains('indomaret') || title.contains('alfamart') || title.contains('belanja') || title.contains('baju') || title.contains('sepatu')) {
      matchedCategory = 'Belanja';
    } else if (title.contains('nonton') || title.contains('bioskop') || title.contains('cinema') || title.contains('netflix') || title.contains('game')) {
      matchedCategory = 'Hiburan';
    } else if (title.contains('gaji') || title.contains('bonus') || title.contains('transfer masuk')) {
      matchedCategory = 'Pemasukan';
    }

    if (matchedCategory != null && matchedCategory != _category) {
      setState(() {
        _category = matchedCategory!;
        if (_category == 'Pemasukan') {
          _isExpense = false;
        } else {
          _isExpense = true;
        }
      });
    }
  }

  Color _getPrimaryColor() {
    switch (widget.currentAccent) {
      case 'emerald':
        return const Color(0xFF10B981);
      case 'sapphire':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFCCA352);
    }
  }

  // Voice recording mock simulation
  void _startVoiceMock() {
    setState(() {
      _isListening = true;
      _voiceStatus = 'Mendengarkan suara Anda...';
    });

    Timer(const Duration(milliseconds: 2500), () {
      setState(() {
        _isListening = false;
        _voiceStatus = 'Klik untuk bicara';
        _titleController.text = 'Kopi Starbucks Caramel';
        _amountController.text = '55000';
        _category = 'Makanan';
        _isExpense = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Voice Input Terdeteksi: "Membeli Kopi Starbucks Caramel senilai 55 ribu rupiah"',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: _getPrimaryColor(),
        ),
      );
    });
  }

  void _calculateSplit() {
    final amt = double.tryParse(_splitBillController.text) ?? 0.0;
    if (amt > 0 && _peopleCount > 0) {
      setState(() {
        _splitResult = amt / _peopleCount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getPrimaryColor();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C24),
        title: const Text('Transaksi & Sosial', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: const Color(0xFF8B8A88),
          tabs: const [
            Tab(text: 'Catat Transaksi'),
            Tab(text: 'Sosial (Split Bill)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Input Transaksi + History
          _buildInputTab(primaryColor),

          // Tab 2: Split Bill & Savings
          _buildSocialTab(primaryColor),
        ],
      ),
    );
  }

  Widget _buildInputTab(Color primaryColor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Form Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catat Transaksi Baru',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 16),
                
                // Title input + Voice simulator button
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Nama Transaksi',
                          labelStyle: const TextStyle(color: Color(0xFF8B8A88), fontSize: 12),
                          hintText: 'e.g. Starbucks, Gaji, Grab',
                          hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Mohon isi nama transaksi.' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Voice Mock Recording Button
                    GestureDetector(
                      onTap: _isListening ? null : _startVoiceMock,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isListening ? const Color(0xFFD85A30) : const Color(0xFF534AB7).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: _isListening ? const Color(0xFFD85A30) : const Color(0xFF534AB7).withValues(alpha: 0.3)),
                        ),
                        child: Icon(
                          _isListening ? Icons.graphic_eq : Icons.mic,
                          color: _isListening ? Colors.white : const Color(0xFF7F77DD),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isListening) ...[
                  const SizedBox(height: 8),
                  Text(_voiceStatus, style: const TextStyle(color: Color(0xFFD85A30), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 14),

                // Amount
                TextFormField(
                  controller: _amountController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Jumlah Uang (Rupiah)',
                    labelStyle: const TextStyle(color: Color(0xFF8B8A88), fontSize: 12),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Mohon isi jumlah uang.';
                    if (double.tryParse(value) == null) return 'Mohon isi angka yang valid.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Category selection dropdown
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        dropdownColor: const Color(0xFF1C1C24),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          labelStyle: const TextStyle(color: Color(0xFF8B8A88), fontSize: 12),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _categories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _category = val;
                              _isExpense = val != 'Pemasukan';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Wallet Selection dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _wallet,
                        dropdownColor: const Color(0xFF1C1C24),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Dompet/Sumber',
                          labelStyle: const TextStyle(color: Color(0xFF8B8A88), fontSize: 12),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: widget.wallets.map((w) {
                          return DropdownMenuItem(value: w.name, child: Text(w.name));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _wallet = val;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Saving features: Round-Up Toggle option
                if (_isExpense) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.savings, color: Color(0xFF1D9E75), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Aktifkan Round-up Saving',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Switch(
                        value: _useRoundUp,
                        onChanged: (val) {
                          setState(() {
                            _useRoundUp = val;
                          });
                        },
                        activeThumbColor: const Color(0xFF1D9E75),
                      ),
                    ],
                  ),
                  if (_useRoundUp) ...[
                    const SizedBox(height: 4),
                    const Text(
                      '*Transaksi akan dibulatkan ke kelipatan Rp 10.000 terdekat. Selisih pembulatan otomatis ditabung.',
                      style: TextStyle(color: Color(0xFF1D9E75), fontSize: 10, fontStyle: FontStyle.italic),
                    ),
                  ],
                  const SizedBox(height: 14),
                ],

                // Submit Button with micro-interaction feedback
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final title = _titleController.text.trim();
                        final amount = double.parse(_amountController.text);
                        
                        // Handle round up logic
                        double finalAmount = amount;
                        if (_useRoundUp && _isExpense) {
                          final double rounded = ((amount / 10000).ceil() * 10000).toDouble();
                          final double diff = rounded - amount;
                          finalAmount = rounded;

                          if (diff > 0) {
                            // Show positive feedback
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Round-up Sukses! Rp ${NumberFormat.format(diff)} berhasil dimasukkan ke tabungan Anda.'),
                                backgroundColor: const Color(0xFF1D9E75),
                              ),
                            );
                          }
                        }

                        widget.onAddTransaction(title, finalAmount, _category, _isExpense, _wallet);
                        
                        _titleController.clear();
                        _amountController.clear();
                        setState(() {
                          _useRoundUp = false;
                        });
                      }
                    },
                    child: const Text(
                      'Simpan Transaksi',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Simple Transaction list below
        const SizedBox(height: 24),
        const Text('Daftar Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        _buildTransactionList(),
      ],
    );
  }

  Widget _buildTransactionList() {
    if (widget.transactions.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Belum ada transaksi.', style: TextStyle(color: Color(0xFF8B8A88)))));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.transactions.length,
      separatorBuilder: (context, idx) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final tx = widget.transactions[idx];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C24),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (tx.isExpense ? const Color(0xFFD85A30) : const Color(0xFF1D9E75)).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      tx.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                      color: tx.isExpense ? const Color(0xFFD85A30) : const Color(0xFF1D9E75),
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${tx.category} • ${tx.wallet}', style: const TextStyle(color: Color(0xFF8B8A88), fontSize: 10)),
                    ],
                  ),
                ],
              ),
              Text(
                '${tx.isExpense ? "-" : "+"} Rp ${NumberFormat.format(tx.amount)}',
                style: TextStyle(
                  color: tx.isExpense ? Colors.white : const Color(0xFF1D9E75),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSocialTab(Color primaryColor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Split Bill Card
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
              const Row(
                children: [
                  Icon(Icons.groups, color: Color(0xFF7F77DD), size: 20),
                  SizedBox(width: 8),
                  Text('Kalkulator Patungan (Split Bill)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _splitBillController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Total Tagihan Gabungan (Rupiah)',
                  labelStyle: const TextStyle(color: Color(0xFF8B8A88), fontSize: 12),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => _calculateSplit(),
              ),
              const SizedBox(height: 14),

              // People count picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Jumlah Anggota Kelompok', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF8B8A88)),
                        onPressed: _peopleCount > 1
                            ? () {
                                setState(() {
                                  _peopleCount--;
                                  _calculateSplit();
                                });
                              }
                            : null,
                      ),
                      Text('$_peopleCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF8B8A88)),
                        onPressed: () {
                          setState(() {
                            _peopleCount++;
                            _calculateSplit();
                          });
                        },
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 14),

              // Split Result Panel
              if (_splitResult > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      const Text('Setiap orang membayar:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 6),
                      Text(
                        'Rp ${NumberFormat.format(_splitResult)}',
                        style: TextStyle(color: primaryColor, fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      // Friends brief
                      Text(
                        'Anggota kelompok: Anda, ${_friends.take(_peopleCount - 1).join(", ")}',
                        style: const TextStyle(color: Color(0xFF8B8A88), fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7F77DD),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tagihan patungan berhasil dikirim ke grup teman Anda!'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                    child: const Text('Kirim Tagihan Patungan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
