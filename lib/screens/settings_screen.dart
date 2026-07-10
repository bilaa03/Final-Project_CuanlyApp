import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final double budgetLimit;
  final String currentAccent;
  final String userAvatar;
  final ValueChanged<double> onBudgetLimitChanged;
  final ValueChanged<String> onAccentChanged;
  final ValueChanged<String> onAvatarChanged;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.budgetLimit,
    required this.currentAccent,
    required this.userAvatar,
    required this.onBudgetLimitChanged,
    required this.onAccentChanged,
    required this.onAvatarChanged,
    required this.onLogout,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _localLimit;

  @override
  void initState() {
    super.initState();
    _localLimit = widget.budgetLimit;
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
          const Text('Pengaturan Akun', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 18),

          // Profile card
          Container(
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
            child: Row(
              children: [
                GestureDetector(
                  onTap: _showAvatarSelector,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating Sweep gradient ring
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF10B981), Color(0xFF818CF8), Color(0xFF4F46E5)],
                          ),
                        ),
                      ),
                      // Core avatar container
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _getAvatarGradient(),
                        ),
                        child: const Center(
                          child: Icon(Icons.person, color: Colors.white, size: 26),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.userName, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(widget.userEmail, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                      const SizedBox(height: 6),
                      Text(
                        'Ketuk foto untuk ganti avatar',
                        style: TextStyle(color: primaryColor, fontSize: 9, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Budget limit setup
          const Text('Limit Anggaran Bulanan', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Batas Maksimal Pengeluaran', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    Text(
                      'Rp ${(_localLimit / 1000000).toStringAsFixed(1)} Juta',
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Slider(
                  value: _localLimit,
                  min: 1000000,
                  max: 10000000,
                  divisions: 18,
                  activeColor: primaryColor,
                  inactiveColor: Colors.black.withOpacity(0.06),
                  onChanged: (val) {
                    setState(() {
                      _localLimit = val;
                    });
                    widget.onBudgetLimitChanged(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Theme accent setup
          const Text('Tema Warna Aplikasi', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAccentButton('gold', const Color(0xFFD97706), 'Emas'),
                _buildAccentButton('emerald', const Color(0xFF059669), 'Mint'),
                _buildAccentButton('sapphire', const Color(0xFF1D4ED8), 'Biru'),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE24B4A), width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: widget.onLogout,
              child: const Text('Keluar dari Akun', style: TextStyle(color: Color(0xFFE24B4A), fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAccentButton(String code, Color color, String name) {
    final isSelected = widget.currentAccent == code;
    return GestureDetector(
      onTap: () => widget.onAccentChanged(code),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(isSelected ? 0.4 : 0.1),
                  blurRadius: 8,
                  spreadRadius: isSelected ? 2 : 0,
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(name, style: TextStyle(color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  LinearGradient _getAvatarGradient() {
    switch (widget.userAvatar) {
      case 'emerald':
        return const LinearGradient(colors: [Color(0xFF059669), Color(0xFF34D399)]);
      case 'coral':
        return const LinearGradient(colors: [Color(0xFFEA580C), Color(0xFFFDBA74)]);
      case 'gold':
        return const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFFBBF24)]);
      default:
        return const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF818CF8)]);
    }
  }

  void _showAvatarSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pilih Avatar Siluet Anda', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih salah satu gradasi siluet premium Cuanly di bawah ini:',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAvatarOption('violet', const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF818CF8)])),
                _buildAvatarOption('emerald', const LinearGradient(colors: [Color(0xFF059669), Color(0xFF34D399)])),
                _buildAvatarOption('coral', const LinearGradient(colors: [Color(0xFFEA580C), Color(0xFFFDBA74)])),
                _buildAvatarOption('gold', const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFFBBF24)])),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOption(String type, LinearGradient gradient) {
    final isSelected = widget.userAvatar == type;
    return GestureDetector(
      onTap: () {
        widget.onAvatarChanged(type);
        Navigator.pop(context);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
            width: 2,
          ),
        ),
        child: const Center(
          child: Icon(Icons.person, color: Colors.white70, size: 22),
        ),
      ),
    );
  }
}
