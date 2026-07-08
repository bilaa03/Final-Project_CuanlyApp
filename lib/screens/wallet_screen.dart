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

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Dompet Cuanly Anda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
                  const Text('Pindahkan Saldo (Transfer)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 16),
                  
                  // From and To dropdowns
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _fromWallet,
                          dropdownColor: const Color(0xFF1C1C24),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Dari Dompet',
                            labelStyle: TextStyle(color: Color(0xFF8B8A88), fontSize: 11),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
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
                          dropdownColor: const Color(0xFF1C1C24),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Ke Dompet',
                            labelStyle: TextStyle(color: Color(0xFF8B8A88), fontSize: 11),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
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
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Jumlah Transfer (Rupiah)',
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
                          widget.onTransfer(_fromWallet, _toWallet, amt);
                          _amountController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kirim saldo sukses!'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      },
                      child: const Text('Kirim Saldo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
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
    // Card styles mapping
    Color cardColor = const Color(0xFF1D4ED8); // Blue Mandiri default
    if (w.designType == 'teal') {
      cardColor = const Color(0xFF0D9488);
    } else if (w.designType == 'purple') {
      cardColor = const Color(0xFF7C3AED);
    } else if (w.designType == 'slate') {
      cardColor = const Color(0xFF475569);
    }

    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.3),
            blurRadius: 10,
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
