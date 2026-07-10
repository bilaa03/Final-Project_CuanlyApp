import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';

class CameraScanScreen extends StatefulWidget {
  final String apiBaseUrl;
  final String currentAccent;
  final Function(String title, double amount, String category, String wallet) onScanSuccess;

  const CameraScanScreen({
    super.key,
    required this.apiBaseUrl,
    required this.currentAccent,
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

  String _validateCategory(String? cat) {
    const valid = ['Makanan', 'Transport', 'Belanja', 'Hiburan', 'Lainnya'];
    if (cat != null && valid.contains(cat)) return cat;
    if (cat == null) return 'Lainnya';
    final c = cat.toLowerCase();
    if (c.contains('makan') || c.contains('minum') || c.contains('cafe') || c.contains('resto')) return 'Makanan';
    if (c.contains('trans') || c.contains('ojek') || c.contains('grab') || c.contains('gojek') || c.contains('bensin') || c.contains('parkir')) return 'Transport';
    if (c.contains('belanja') || c.contains('beli') || c.contains('indo') || c.contains('alfa') || c.contains('super')) return 'Belanja';
    if (c.contains('hibur') || c.contains('game') || c.contains('movie') || c.contains('nonton')) return 'Hiburan';
    return 'Lainnya';
  }

  Future<void> _uploadAndScanReceipt() async {
    if (_selectedImage == null) return;

    setState(() {
      _isScanning = true;
      _statusText = 'AI Cuanly sedang membaca struk...';
    });

    try {
      final keyUri = Uri.parse('${widget.apiBaseUrl}/financial/ocr/key');
      final keyResponse = await http.get(keyUri).timeout(const Duration(seconds: 10));
      if (keyResponse.statusCode != 200) {
        throw Exception('Gagal mengambil API Key dari server (Status: ${keyResponse.statusCode}).');
      }
      final keyData = jsonDecode(keyResponse.body);
      final String apiKey = keyData['apiKey'] ?? '';
      if (apiKey.isEmpty) {
        throw Exception('API Key Gemini belum diset di server Railway Anda.');
      }

      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final extension = _selectedImage!.path.split('.').last.toLowerCase();
      final mimeType = (extension == 'png') ? 'image/png' : 'image/jpeg';

      final geminiUri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
      );

      final prompt = [
        'Kamu adalah Cuanly OCR Engine.',
        'Tugasmu adalah menganalisis gambar struk/receipt belanja ini dan mengekstrak informasi keuangan berikut:',
        '1. title: Nama toko/merchant atau ringkasan pembelian yang representatif (contoh: "Starbucks Coffee", "Indomaret").',
        '2. amount: Total pengeluaran nominal angka bulat (number) saja tanpa simbol rupiah/titik desimal (contoh: 45000).',
        '3. category: Kategori transaksi. Kamu WAJIB memilih salah satu dari daftar ini saja:',
        '   - "Makanan" (untuk makanan, minuman, kafe, restoran)',
        '   - "Transport" (untuk bensin, parkir, ojek, tol, tiket perjalanan)',
        '   - "Belanja" (untuk belanja bulanan, minimarket, baju, barang retail)',
        '   - "Hiburan" (untuk bioskop, game, rekreasi)',
        '   - "Lainnya" (jika tidak masuk kategori mana pun)',
        '4. walletName: Metode pembayaran yang terdeteksi atau disarankan berdasarkan struk (contoh: "Cash", "GoPay", "Bank Mandiri", "OVO", "ShopeePay").',
        '',
        'PENTING: Kembalikan respon HANYA dalam format JSON valid dengan key: title, amount, category, walletName. Jangan tambahkan penjelasan lain di luar JSON.',
      ].join('\n');

      final requestBody = {
        'contents': [
          {
            'parts': [
              { 'text': prompt },
              {
                'inlineData': {
                  'mimeType': mimeType,
                  'data': base64Image,
                },
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.1,
          'responseMimeType': 'application/json',
        },
      };

      final response = await http.post(
        geminiUri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? textResult = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (textResult == null || textResult.isEmpty) {
          throw Exception('Respon Gemini kosong.');
        }

        final parsed = jsonDecode(textResult.trim());
        
        setState(() {
          _isScanning = false;
          _statusText = 'Pemindaian sukses!';
        });

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          widget.onScanSuccess(
            parsed['title'] ?? 'Struk Belanja',
            (parsed['amount'] as num).toDouble(),
            _validateCategory(parsed['category'] as String?),
            parsed['walletName'] ?? 'Cash',
          );
          Navigator.pop(context);
        }
      } else {
        String errorMsg = 'Google API error ${response.statusCode}';
        try {
          final errData = jsonDecode(response.body);
          if (errData['error']?['message'] != null) {
            errorMsg = errData['error']['message'];
          }
        } catch (_) {}
        throw Exception(errorMsg);
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
    final themeColor = _getPrimaryColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Pindai Struk Belanja',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
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
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isScanning ? themeColor : Colors.black.withOpacity(0.06),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              )
                            ],
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
                                          opacity: 0.15,
                                          child: Icon(
                                            Icons.receipt_long_rounded,
                                            size: 100,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                                          child: Text(
                                            'Ambil foto struk belanja Anda untuk dibaca otomatis oleh AI',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),

                        _buildCornerMarker(top: 0, left: 0, color: _isScanning ? themeColor : Colors.black38),
                        _buildCornerMarker(top: 0, right: 0, color: _isScanning ? themeColor : Colors.black38),
                        _buildCornerMarker(bottom: 0, left: 0, color: _isScanning ? themeColor : Colors.black38),
                        _buildCornerMarker(bottom: 0, right: 0, color: _isScanning ? themeColor : Colors.black38),

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
                                        color: themeColor.withOpacity(0.8),
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
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.015),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isScanning)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                        ),
                      ),
                    ),
                  Flexible(
                    child: Text(
                      _statusText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.only(bottom: 36, left: 24, right: 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isScanning ? null : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                      label: const Text('Ambil Foto', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        elevation: 0,
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
                      icon: const Icon(Icons.photo_library_rounded, color: Color(0xFF64748B)),
                      label: const Text('Galeri Foto', style: TextStyle(color: Color(0xFF64748B))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black12),
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
