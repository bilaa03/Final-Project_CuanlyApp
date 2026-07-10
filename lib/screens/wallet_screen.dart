import 'package:flutter/material.dart';
import '../models/wallet.dart';
import '../models/transaction.dart';
import 'home_screen.dart'; // import format helper

class WalletScreen extends StatefulWidget {
  final List<WalletItem> wallets;
  final List<TransactionItem> transactions;
  final String currentAccent;
  final Function(String, String, double) onTransfer;
  final Function(String, double, String, String) onAddWallet;

  const WalletScreen({
    super.key,
    required this.wallets,
    required this.transactions,
    required this.currentAccent,
    required this.onTransfer,
    required this.onAddWallet,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  late String _fromWallet;
  late String _toWallet;

  @override
  void initState() {
    super.initState();
    if (widget.wallets.isNotEmpty) {
      _fromWallet = widget.wallets[0].name;
      _toWallet = widget.wallets.length > 1 ? widget.wallets[1].name : widget.wallets[0].name;
    } else {
      _fromWallet = '';
      _toWallet = '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Color _getPrimaryColor() {
    switch (widget.currentAccent) {
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Dompet Cuanly Anda', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          
          // Wallets cards list
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.wallets.length + 1,
              separatorBuilder: (context, idx) => const SizedBox(width: 14),
              itemBuilder: (context, idx) {
                if (idx == widget.wallets.length) {
                  return _buildAddWalletCard();
                }
                final w = widget.wallets[idx];
                return _buildCardItem(w);
              },
            ),
          ),

          const SizedBox(height: 28),
          
          // Transfer Balance Form Card
          widget.wallets.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
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
                  child: const Column(
                    children: [
                      Text('Pindahkan Saldo (Transfer)', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(height: 20),
                      Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Anda belum memiliki dompet.\nTambahkan dompet baru untuk mengaktifkan fitur transfer.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                )
              : Container(
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pindahkan Saldo (Transfer)', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 16),
                        
                        // From and To dropdowns
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _fromWallet,
                                dropdownColor: Colors.white,
                                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                                decoration: const InputDecoration(
                                  labelText: 'Dari Dompet',
                                  labelStyle: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                                ),
                                items: widget.wallets.map((w) {
                                  return DropdownMenuItem(value: w.name, child: Text(w.name));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _fromWallet = val;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _toWallet,
                                dropdownColor: Colors.white,
                                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                                decoration: const InputDecoration(
                                  labelText: 'Ke Dompet',
                                  labelStyle: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                                ),
                                items: widget.wallets.map((w) {
                                  return DropdownMenuItem(value: w.name, child: Text(w.name));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _toWallet = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Amount text field
                        TextFormField(
                          controller: _amountController,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Jumlah Transfer (Rupiah)',
                            labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.black12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Mohon isi jumlah transfer.';
                            if (double.tryParse(val) == null) return 'Mohon isi angka yang valid.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                if (_fromWallet == _toWallet) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Dompet asal dan tujuan tidak boleh sama!'),
                                      backgroundColor: Color(0xFFE24B4A),
                                    ),
                                  );
                                  return;
                                }
                                final amt = double.parse(_amountController.text);
                                final sourceWallet = widget.wallets.firstWhere((w) => w.name == _fromWallet);
                                if (amt > sourceWallet.balance) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Saldo dompet asal tidak mencukupi!'),
                                      backgroundColor: Color(0xFFE24B4A),
                                    ),
                                  );
                                  return;
                                }
                                
                                // Show confirmation dialog
                                showDialog(
                                  context: context,
                                  builder: (BuildContext dialogContext) {
                                    return AlertDialog(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: const Row(
                                        children: [
                                          Icon(Icons.swap_horiz, color: Color(0xFF6366F1)),
                                          SizedBox(width: 8),
                                          Text(
                                            'Konfirmasi Transfer',
                                            style: TextStyle(
                                              color: Color(0xFF0F172A),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: Text(
                                        'Apakah Anda yakin ingin memindahkan saldo sebesar Rp ${NumberFormat.format(amt)} dari $_fromWallet ke $_toWallet?',
                                        style: const TextStyle(
                                          color: Color(0xFF475569),
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogContext),
                                          child: const Text(
                                            'Batal',
                                            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.pop(dialogContext); // Close dialog
                                            widget.onTransfer(_fromWallet, _toWallet, amt);
                                            _amountController.clear();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Kirim saldo sukses!'),
                                                backgroundColor: Color(0xFF10B981),
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            'Ya, Kirim',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            },
                            child: const Text('Kirim Saldo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
          if (widget.wallets.isNotEmpty) ...[
            const SizedBox(height: 28),
            _buildBalanceDistributionSection(primaryColor),
            const SizedBox(height: 28),
            _buildRecentWalletTransactionsSection(primaryColor),
          ]
        ],
      ),
    );
  }

  Widget _buildBalanceDistributionSection(Color primaryColor) {
    double totalBalance = widget.wallets.fold(0.0, (sum, w) => sum + w.balance);
    if (totalBalance <= 0) totalBalance = 1.0;

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
          const Text(
            'Distribusi Saldo Aset',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.wallets.map((w) {
            final percentage = (w.balance / totalBalance) * 100;
            
            Color wColor = const Color(0xFF2563EB);
            if (w.designType == 'teal') {
              wColor = const Color(0xFF0D9488);
            } else if (w.designType == 'purple') {
              wColor = const Color(0xFF7C3AED);
            } else if (w.designType == 'slate') {
              wColor = const Color(0xFF475569);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        w.name,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}% (${rupiahFormat(w.balance)})',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: w.balance <= 0 ? 0.0 : w.balance / totalBalance,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(wColor),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentWalletTransactionsSection(Color primaryColor) {
    final walletNames = widget.wallets.map((w) => w.name).toSet();
    final walletTxs = widget.transactions.where((tx) => walletNames.contains(tx.wallet)).toList();

    walletTxs.sort((a, b) => b.date.compareTo(a.date));
    final displayTxs = walletTxs.take(4).toList();

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
          const Text(
            'Riwayat Aktivitas Dompet',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          if (displayTxs.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'Belum ada transaksi di dompet ini.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayTxs.length,
              separatorBuilder: (context, idx) => const Divider(color: Color(0xFFF1F5F9), height: 24),
              itemBuilder: (context, idx) {
                final tx = displayTxs[idx];
                final isExp = tx.isExpense;

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isExp ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isExp ? Icons.arrow_downward : Icons.arrow_upward,
                        size: 16,
                        color: isExp ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.title,
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${tx.wallet} • ${tx.category}',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isExp ? "-" : "+"} Rp ${NumberFormat.format(tx.amount)}',
                      style: TextStyle(
                        color: isExp ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  String rupiahFormat(double val) {
    return 'Rp ${NumberFormat.format(val)}';
  }

  Widget _buildCardItem(WalletItem w) {
    // Card styles mapping with premium bright gradients
    Color startColor = const Color(0xFF2563EB); // Blue Mandiri
    Color endColor = const Color(0xFF60A5FA);
    if (w.designType == 'teal') {
      startColor = const Color(0xFF0D9488);
      endColor = const Color(0xFF2DD4BF);
    } else if (w.designType == 'purple') {
      startColor = const Color(0xFF7C3AED);
      endColor = const Color(0xFFA78BFA);
    } else if (w.designType == 'slate') {
      startColor = const Color(0xFF475569);
      endColor = const Color(0xFF94A3B8);
    }

    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: startColor.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                w.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              _getWalletLogo(w.name),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Rp ${NumberFormat.format(w.balance)}',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          Text(
            w.cardNumber,
            style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace', letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _getWalletLogo(String name, {bool whiteTheme = false}) {
    final lower = name.toLowerCase();
    
    if (lower.contains('gopay')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: whiteTheme ? const Color(0xFF00AED6) : Colors.white24,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'go pay',
          style: TextStyle(
            color: whiteTheme ? Colors.white : Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    if (lower.contains('ovo')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: whiteTheme ? const Color(0xFF4C2A86) : Colors.white24,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'OVO',
          style: TextStyle(
            color: whiteTheme ? Colors.white : Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    if (lower.contains('dana')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: whiteTheme ? const Color(0xFF118EEA) : Colors.white24,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'DANA',
          style: TextStyle(
            color: whiteTheme ? Colors.white : Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    if (lower.contains('shopee')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: whiteTheme ? const Color(0xFFEE4D2D) : Colors.white24,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'S Pay',
          style: TextStyle(
            color: whiteTheme ? Colors.white : Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (lower.contains('linkaja') || lower.contains('link aja')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: whiteTheme ? const Color(0xFFE21F26) : Colors.white24,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'LinkAja!',
          style: TextStyle(
            color: whiteTheme ? Colors.white : Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (lower.contains('mandiri')) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'mandıri',
            style: TextStyle(
              color: whiteTheme ? const Color(0xFF1C3F94) : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 2),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFFDB813),
              shape: BoxShape.circle,
            ),
          ),
        ],
      );
    }

    if (lower.contains('bca')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: whiteTheme ? const Color(0xFF005EAC) : Colors.white24,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'BCA',
          style: TextStyle(
            color: whiteTheme ? Colors.white : Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (lower.contains('bri')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: whiteTheme ? const Color(0xFF0F4C81) : Colors.white24,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'BRI',
          style: TextStyle(
            color: whiteTheme ? Colors.white : Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (lower.contains('bni')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: whiteTheme ? const Color(0xFFE55300) : Colors.white24,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'BNI',
          style: TextStyle(
            color: whiteTheme ? Colors.white : Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Icon(Icons.credit_card, color: whiteTheme ? Colors.grey : Colors.white70, size: 20);
  }

  Widget _buildAddWalletCard() {
    return GestureDetector(
      onTap: _showAddWalletDialog,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 2, style: BorderStyle.solid),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_card_rounded, color: Color(0xFF64748B), size: 36),
            SizedBox(height: 10),
            Text(
              'Tambah Dompet Baru',
              style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 4),
            Text(
              'Bank atau E-Wallet',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWalletDialog() {
    String walletType = 'E-Wallet';
    String selectedEWallet = 'GoPay';
    String selectedBank = 'Bank Mandiri';
    final customBankController = TextEditingController();
    final balanceController = TextEditingController();
    final cardNumberController = TextEditingController();
    String designType = 'teal';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Tambah Dompet Baru',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: walletType == 'E-Wallet' ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              foregroundColor: walletType == 'E-Wallet' ? Colors.white : const Color(0xFF475569),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => setDialogState(() => walletType = 'E-Wallet'),
                            child: const Text('E-Wallet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: walletType == 'Bank' ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              foregroundColor: walletType == 'Bank' ? Colors.white : const Color(0xFF475569),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => setDialogState(() => walletType = 'Bank'),
                            child: const Text('Bank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (walletType == 'E-Wallet') ...[
                      DropdownButtonFormField<String>(
                        value: selectedEWallet,
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Pilih E-Wallet',
                          labelStyle: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        ),
                        items: ['GoPay', 'OVO', 'DANA', 'ShopeePay', 'LinkAja'].map((e) {
                          return DropdownMenuItem(
                            value: e,
                            child: Row(
                              children: [
                                _getWalletLogo(e, whiteTheme: true),
                                const SizedBox(width: 10),
                                Text(e),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedEWallet = val;
                              if (val == 'GoPay' || val == 'DANA' || val == 'ShopeePay') designType = 'teal';
                              if (val == 'OVO') designType = 'purple';
                              if (val == 'LinkAja') designType = 'teal';
                            });
                          }
                        },
                      ),
                    ] else ...[
                      DropdownButtonFormField<String>(
                        value: selectedBank,
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Pilih Bank',
                          labelStyle: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        ),
                        items: ['Bank Mandiri', 'Bank BCA', 'Bank BRI', 'Bank BNI', 'Bank Lainnya (Tulis Sendiri)'].map((b) {
                          return DropdownMenuItem(
                            value: b,
                            child: Row(
                              children: [
                                _getWalletLogo(b, whiteTheme: true),
                                const SizedBox(width: 10),
                                Text(b),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedBank = val;
                              if (val == 'Bank Mandiri' || val == 'Bank BCA' || val == 'Bank BRI') designType = 'slate';
                              if (val == 'Bank BNI') designType = 'purple';
                            });
                          }
                        },
                      ),
                      if (selectedBank == 'Bank Lainnya (Tulis Sendiri)') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: customBankController,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Nama Bank Lainnya',
                            labelStyle: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: balanceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Saldo Awal (Rupiah)',
                        labelStyle: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cardNumberController,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: walletType == 'E-Wallet' ? 'Nomor HP Akun E-Wallet' : 'Nomor Kartu / Rekening',
                        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Desain & Warna Kartu:', style: TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDesignSelector('teal', designType, const Color(0xFF0D9488), (d) => setDialogState(() => designType = d)),
                        _buildDesignSelector('purple', designType, const Color(0xFF7C3AED), (d) => setDialogState(() => designType = d)),
                        _buildDesignSelector('slate', designType, const Color(0xFF475569), (d) => setDialogState(() => designType = d)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getPrimaryColor(),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    String finalWalletName = '';
                    if (walletType == 'E-Wallet') {
                      finalWalletName = selectedEWallet;
                    } else {
                      if (selectedBank == 'Bank Lainnya (Tulis Sendiri)') {
                        finalWalletName = customBankController.text.trim();
                      } else {
                        finalWalletName = selectedBank;
                      }
                    }

                    final balance = double.tryParse(balanceController.text) ?? 0.0;
                    String cardNo = cardNumberController.text.trim();

                    if (finalWalletName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nama dompet / bank tidak boleh kosong.'), backgroundColor: Color(0xFFE24B4A)),
                      );
                      return;
                    }

                    if (cardNo.isEmpty) {
                      cardNo = walletType == 'E-Wallet' ? '0812 •••• ••••' : '•••• •••• •••• 8821';
                    }

                    widget.onAddWallet(finalWalletName, balance, cardNo, designType);
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Dompet $finalWalletName berhasil ditambahkan!'), backgroundColor: const Color(0xFF10B981)),
                    );
                  },
                  child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDesignSelector(String val, String selectedVal, Color color, Function(String) onSelect) {
    final isSelected = val == selectedVal;
    return GestureDetector(
      onTap: () => onSelect(val),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.black, width: 2.5) : null,
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
      ),
    );
  }
}
