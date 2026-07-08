import 'dart:async';
import 'package:flutter/material.dart';

class CameraScanScreen extends StatefulWidget {
  final Function(String title, double amount, String category, String wallet) onScanSuccess;

  const CameraScanScreen({super.key, required this.onScanSuccess});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;
  bool _isFlashOn = false;
  bool _isScanning = false;
  bool _isFlashActive = false;
  Timer? _autoScanTimer;
  int _secondsLeft = 3;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scannerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scannerController, curve: Curves.easeInOut),
    );

    // Start auto detection countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsLeft > 1) {
            _secondsLeft--;
          } else {
            _secondsLeft = 0;
            _countdownTimer?.cancel();
          }
        });
      }
    });

    _autoScanTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isScanning) {
        _triggerAutoScan();
      }
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _autoScanTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _triggerAutoScan() {
    setState(() {
      _isFlashActive = true;
      _isScanning = true;
    });

    // White flash shutter animation effect
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isFlashActive = false;
        });
      }
    });

    // Simulate OCR processing for 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        widget.onScanSuccess(
          'Makan Siang Struk Mandiri (Auto-Detected)',
          85000.0,
          'Makanan',
          'Bank Mandiri',
        );
        Navigator.pop(context);
      }
    });
  }

  void _clickShutter() {
    _autoScanTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _isScanning = true;
      _secondsLeft = 0;
    });

    // Simulate OCR processing for 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        widget.onScanSuccess(
          'Makan Siang Struk Mandiri',
          85000.0,
          'Makanan',
          'Bank Mandiri',
        );
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Simulated camera view background (dim/dark camera texture)
          Container(
            color: const Color(0xFF0F0F14),
            child: const Center(
              child: Opacity(
                opacity: 0.15,
                child: Icon(
                  Icons.receipt_long,
                  size: 240,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Viewfinder Frame Overlay
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Corner markers
                  _buildCornerMarker(top: 0, left: 0),
                  _buildCornerMarker(top: 0, right: 0),
                  _buildCornerMarker(bottom: 0, left: 0),
                  _buildCornerMarker(bottom: 0, right: 0),

                  // OCR Scan laser animation line
                  AnimatedBuilder(
                    animation: _scannerAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _scannerAnimation.value * (MediaQuery.of(context).size.height * 0.5 - 20) + 10,
                        left: 15,
                        right: 15,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: _isScanning ? const Color(0xFF1D9E75) : const Color(0xFF7F77DD),
                            boxShadow: [
                              BoxShadow(
                                color: (_isScanning ? const Color(0xFF1D9E75) : const Color(0xFF7F77DD)).withValues(alpha: 0.8),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Overlay Scanner Status Text
                  if (_isScanning)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1D9E75)),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'AI Membaca Struk...',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      ),
                    )
                  else
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          _secondsLeft > 0
                              ? 'Posisikan Struk Belanja di Dalam Kotak\nAuto-detect dalam $_secondsLeft detik...'
                              : 'Mengidentifikasi struk...',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Top Action Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'PINDAI STRUK OCR',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                ),
                IconButton(
                  icon: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: _isFlashOn ? Colors.yellow : Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isFlashOn = !_isFlashOn;
                    });
                  },
                ),
              ],
            ),
          ),

          // Bottom Shutter Panel
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _isScanning ? null : _clickShutter,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _isScanning ? 'SEDANG MEMPROSES...' : 'KETUK UNTUK MENGAMBIL FOTO',
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                )
              ],
            ),
          ),

          // Shutter Camera Flash Overlay Effect
          if (_isFlashActive)
            Positioned.fill(
              child: Container(
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCornerMarker({double? top, double? bottom, double? left, double? right}) {
    final markerColor = _isScanning ? const Color(0xFF1D9E75) : const Color(0xFF7F77DD);
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border(
            top: top != null ? BorderSide(color: markerColor, width: 3) : BorderSide.none,
            bottom: bottom != null ? BorderSide(color: markerColor, width: 3) : BorderSide.none,
            left: left != null ? BorderSide(color: markerColor, width: 3) : BorderSide.none,
            right: right != null ? BorderSide(color: markerColor, width: 3) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
