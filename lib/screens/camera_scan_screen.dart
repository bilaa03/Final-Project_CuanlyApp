import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class CameraScanScreen extends StatefulWidget {
  final String apiBaseUrl;
  final Function(String title, double amount, String category, String wallet) onScanSuccess;

  const CameraScanScreen({
    super.key,
    required this.apiBaseUrl,
    required this.onScanSuccess,
  });

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;
  
  File? _selectedImage;
  bool _isScanning = false;
  String _statusText = 'Pilih struk untuk mulai memindai';
  final ImagePicker _picker = ImagePicker();

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
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _selectedImage = File(image.path);
        _statusText = 'Gambar berhasil dimuat. Memulai pemindaian...';
      });

      await _uploadAndScanReceipt();
    } catch (e) {
      _showError('Gagal mengambil gambar: ${e.toString()}');
    }
  }

  Future<void> _uploadAndScanReceipt() async {
    if (_selectedImage == null) return;

    setState(() {
      _isScanning = true;
      _statusText = 'AI Cuanly sedang membaca struk...';
    });

    try {
      // Read image bytes and convert to Base64
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Extract file extension to determine mimeType
      final extension = _selectedImage!.path.split('.').last.toLowerCase();
      final mimeType = (extension == 'png') ? 'image/png' : 'image/jpeg';

      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/financial/ocr'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'image': base64Image,
          'mimeType': mimeType,
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['ok'] == true && resData['data'] != null) {
          final data = resData['data'];
          
          setState(() {
            _isScanning = false;
            _statusText = 'Pemindaian sukses!';
          });

          // Show success message briefly before returning
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            widget.onScanSuccess(
              data['title'] ?? 'Struk Belanja',
              (data['amount'] as num).toDouble(),
              data['category'] ?? 'Lainnya',
              data['walletName'] ?? 'Cash',
            );
            Navigator.pop(context);
          }
        } else {
          throw Exception(resData['error'] ?? 'Gagal memproses struk.');
        }
      } else {
        throw Exception('Server merespon dengan status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusText = 'Pemindaian gagal.';
      });
      _showError('OCR gagal: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFFCCA352); // Gold theme color

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        title: const Text(
          'Pindai Struk Belanja',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Stack(
                      children: [
                        // Border viewfinder
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isScanning ? themeColor : Colors.white24,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            color: const Color(0xFF161620),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: _selectedImage != null
                                ? Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Opacity(
                                          opacity: 0.25,
                                          child: Icon(
                                            Icons.receipt_long_rounded,
                                            size: 100,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        Opacity(
                                          opacity: 0.6,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 24.0),
                                            child: Text(
                                              'Ambil foto struk belanja Anda untuk dibaca otomatis oleh AI',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: Colors.white, fontSize: 13),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),

                        // Corner decorations
                        _buildCornerMarker(top: 0, left: 0, color: _isScanning ? themeColor : Colors.white70),
                        _buildCornerMarker(top: 0, right: 0, color: _isScanning ? themeColor : Colors.white70),
                        _buildCornerMarker(bottom: 0, left: 0, color: _isScanning ? themeColor : Colors.white70),
                        _buildCornerMarker(bottom: 0, right: 0, color: _isScanning ? themeColor : Colors.white70),

                        // Scan laser animation
                        if (_isScanning)
                          AnimatedBuilder(
                            animation: _scannerAnimation,
                            builder: (context, child) {
                              return Positioned(
                                top: _scannerAnimation.value * (MediaQuery.of(context).size.height * 0.5 - 20) + 10,
                                left: 15,
                                right: 15,
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: themeColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: themeColor.withValues(alpha: 0.8),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Status bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF161620),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isScanning)
                    const Padding(
                      padding: EdgeInsets.only(right: 12.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCCA352)),
                        ),
                      ),
                    ),
                  Flexible(
                    child: Text(
                      _statusText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Controls buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 36, left: 24, right: 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isScanning ? null : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Ambil Foto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isScanning ? null : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded, color: Colors.white),
                      label: const Text('Galeri Foto', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerMarker({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: top != null ? BorderSide(color: color, width: 4) : BorderSide.none,
            bottom: bottom != null ? BorderSide(color: color, width: 4) : BorderSide.none,
            left: left != null ? BorderSide(color: color, width: 4) : BorderSide.none,
            right: right != null ? BorderSide(color: color, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
