import 'package:flutter/material.dart';
import '../models/wallet.dart';
import 'home_screen.dart'; // import format helper

class WalletScreen extends StatefulWidget {
  final List<WalletItem> wallets;
  final String currentAccent;
  final Function(String, String, double) onTransfer;

  const WalletScreen({
    super.key,
    required this.wallets,
    required this.currentAccent,
    required this.onTransfer,
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
              itemCount: widget.wallets.length,
              separatorBuilder: (context, idx) => const SizedBox(width: 14),
              itemBuilder: (context, idx) {
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
                )
        ],
      ),
    );
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
              const Icon(Icons.credit_card, color: Colors.white70, size: 20),
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
}
