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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Pengaturan Akun', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 18),

          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C24),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _showAvatarSelector,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating/pulsing border ring representation
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [Color(0xFF534AB7), Color(0xFF1D9E75), Color(0xFF7F77DD), Color(0xFF534AB7)],
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
                      Text(widget.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(widget.userEmail, style: const TextStyle(color: Color(0xFF8B8A88), fontSize: 11)),
                      const SizedBox(height: 6),
                      const Text(
                        'Ketuk foto untuk ganti avatar',
                        style: TextStyle(color: Color(0xFF7F77DD), fontSize: 9, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Budget limit setup
          const Text('Limit Anggaran Bulanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C24),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Batas Maksimal Pengeluaran', style: TextStyle(color: Color(0xFF8B8A88), fontSize: 11)),
                    Text(
                      'Rp ${(_localLimit / 1000000).toStringAsFixed(1)} Juta',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Slider(
                  value: _localLimit,
                  min: 1000000,
                  max: 10000000,
                  divisions: 18,
                  activeColor: const Color(0xFF7F77DD),
                  inactiveColor: Colors.white12,
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
          const Text('Tema Warna Aplikasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C24),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAccentButton('gold', const Color(0xFFCCA352), 'Emas'),
                _buildAccentButton('emerald', const Color(0xFF10B981), 'Mint'),
                _buildAccentButton('sapphire', const Color(0xFF3B82F6), 'Biru'),
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
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(name, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF8B8A88), fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  LinearGradient _getAvatarGradient() {
    switch (widget.userAvatar) {
      case 'emerald':
        return const LinearGradient(colors: [Color(0xFF1D9E75), Color(0xFF10B981)]);
      case 'coral':
        return const LinearGradient(colors: [Color(0xFFD85A30), Color(0xFFEF9F27)]);
      case 'gold':
        return const LinearGradient(colors: [Color(0xFFCCA352), Color(0xFFE5C158)]);
      default:
        return const LinearGradient(colors: [Color(0xFF534AB7), Color(0xFF7F77DD)]);
    }
  }

  void _showAvatarSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pilih Avatar Siluet Anda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih salah satu gradasi siluet premium Cuanly di bawah ini:',
              style: TextStyle(color: Color(0xFF8B8A88), fontSize: 11, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAvatarOption('violet', const LinearGradient(colors: [Color(0xFF534AB7), Color(0xFF7F77DD)])),
                _buildAvatarOption('emerald', const LinearGradient(colors: [Color(0xFF1D9E75), Color(0xFF10B981)])),
                _buildAvatarOption('coral', const LinearGradient(colors: [Color(0xFFD85A30), Color(0xFFEF9F27)])),
                _buildAvatarOption('gold', const LinearGradient(colors: [Color(0xFFCCA352), Color(0xFFE5C158)])),
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
            color: isSelected ? Colors.white : Colors.transparent,
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
