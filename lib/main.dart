import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'models/chat.dart';
import 'models/demo_question.dart';
import 'models/transaction.dart';
import 'models/user.dart';
import 'models/wallet.dart';

import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/transaction_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/camera_scan_screen.dart';

void main() {
  runApp(const CuanlyApp());
}

class CuanlyApp extends StatefulWidget {
  const CuanlyApp({super.key});

  @override
  State<CuanlyApp> createState() => _CuanlyAppState();
}

class _CuanlyAppState extends State<CuanlyApp> {
  String _globalAccent = 'gold';

  void _updateAccent(String newAccent) {
    setState(() {
      _globalAccent = newAccent;
    });
  }

  Color _getPrimaryColor() {
    switch (_globalAccent) {
      case 'emerald':
        return const Color(0xFF10B981);
      case 'sapphire':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFCCA352); // Gold
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getPrimaryColor();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cuanly',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F14),
        cardColor: const Color(0xFF1C1C24),
        colorScheme: ColorScheme.dark(
          primary: primaryColor,
          secondary: _globalAccent == 'gold'
              ? const Color(0xFFF5A623)
              : _globalAccent == 'emerald'
                  ? const Color(0xFF059669)
                  : const Color(0xFF1D4ED8),
          surface: const Color(0xFF1C1C24),
          shadow: Colors.black.withValues(alpha: 0.5),
        ),
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      home: CuanlyMainLayout(
        currentAccent: _globalAccent,
        onAccentChanged: _updateAccent,
      ),
    );
  }
}

class CuanlyMainLayout extends StatefulWidget {
  final String currentAccent;
  final ValueChanged<String> onAccentChanged;

  const CuanlyMainLayout({
    super.key,
    required this.currentAccent,
    required this.onAccentChanged,
  });

  @override
  State<CuanlyMainLayout> createState() => _CuanlyMainLayoutState();
}

class _CuanlyMainLayoutState extends State<CuanlyMainLayout> {
  int _activeTabIndex = 0;
  bool _isLoggedIn = false;

  // Users Auth simulation database
  final List<UserAccount> _users = [
    UserAccount(name: 'Bilaa', email: 'bilaa@cuanly.ai', password: 'password123'),
    UserAccount(name: 'Demo', email: 'demo@cuanly.ai', password: 'password123'),
  ];

  // User Profile
  String _userName = 'Bilaa';
  String _userEmail = 'bilaa@cuanly.ai';
  double _budgetLimit = 3000000;
  bool _roastMode = false;

  final List<WalletItem> _wallets = [];
  late List<TransactionItem> _transactions;

  // AI Chat states
  // Gunakan http://10.0.2.2:8787 untuk Android Emulator, atau http://localhost:8787 untuk Web/Windows Desktop
  final String _apiBaseUrl = 'https://final-projectcuanlyapp-production.up.railway.app';
  final List<ChatMsg> _chatHistory = [];
  bool _chatLoading = false;
  String _activeChatSegment = 'b2c';
  String _userAvatar = 'violet';

  final List<DemoQuestion> _demoQuestions = const [
    DemoQuestion('Budget B2C', 'b2c', 'Berapa total pengeluaranku bulan ini dan apakah sudah melebihi budget?'),
    DemoQuestion('Tips Hemat', 'b2c', 'Berikan tips menghemat uang jajan mahasiswa.'),
    DemoQuestion('Investasi', 'b2c', 'Bagaimana cara mulai investasi dengan modal kecil?'),
    DemoQuestion('AWS Claim B2B', 'b2b', 'Apakah pengeluaran AWS Cloud Hosting senilai Rp 1.500.000 disetujui?'),
    DemoQuestion('Hotel Limit B2B', 'b2b', 'Berapa batas reimbursement hotel dinas luar kota?'),
  ];

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
  void initState() {
    super.initState();
    _transactions = [];
  }

  void _initializeUserData(String email) {
    _wallets.clear();
    if (email == 'bilaa@cuanly.ai' || email == 'demo@cuanly.ai') {
      _wallets.addAll([
        WalletItem(name: 'Bank Mandiri', balance: 3500000, cardNumber: '•••• 8821', designType: 'blue'),
        WalletItem(name: 'GoPay', balance: 500000, cardNumber: '0812 •••• 9012', designType: 'teal'),
        WalletItem(name: 'OVO', balance: 200000, cardNumber: '0812 •••• 9012', designType: 'purple'),
        WalletItem(name: 'Cash', balance: 120000, cardNumber: 'Fisik', designType: 'slate'),
      ]);

      _transactions = [
        TransactionItem(
          id: 't1',
          title: 'Restoran & Coffee Shop',
          category: 'Makanan',
          date: DateTime.now().subtract(const Duration(minutes: 45)),
          amount: 650000,
          isExpense: true,
          wallet: 'Cash',
        ),
        TransactionItem(
          id: 't2',
          title: 'Grab Ride',
          category: 'Transport',
          date: DateTime.now().subtract(const Duration(days: 2)),
          amount: 320000,
          isExpense: true,
          wallet: 'GoPay',
        ),
        TransactionItem(
          id: 't3',
          title: 'Belanja Indomaret',
          category: 'Belanja',
          date: DateTime.now().subtract(const Duration(hours: 4)),
          amount: 430000,
          isExpense: true,
          wallet: 'Bank Mandiri',
        ),
        TransactionItem(
          id: 't4',
          title: 'Gaji Bulanan',
          category: 'Pemasukan',
          date: DateTime.now().subtract(const Duration(days: 3)),
          amount: 3500000,
          isExpense: false,
          wallet: 'Bank Mandiri',
        ),
      ];
    }
  }

  Future<void> _fetchFinancialData(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/financial/data?email=$email'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> walletsData = data['wallets'] ?? [];
        final List<dynamic> txsData = data['transactions'] ?? [];

        setState(() {
          _wallets.clear();
          for (var w in walletsData) {
            _wallets.add(WalletItem(
              name: w['name'] ?? 'Cash',
              balance: (w['balance'] as num).toDouble(),
              cardNumber: w['cardNumber'] ?? 'Fisik',
              designType: w['designType'] ?? 'slate',
            ));
          }

          _transactions.clear();
          for (var t in txsData) {
            _transactions.add(TransactionItem(
              id: t['id'] ?? '',
              title: t['title'] ?? '',
              category: t['category'] ?? '',
              date: DateTime.parse(t['date'] ?? DateTime.now().toIso8601String()),
              amount: (t['amount'] as num).toDouble(),
              isExpense: t['isExpense'] ?? true,
              wallet: t['walletName'] ?? 'Cash',
            ));
          }
        });
      } else {
        throw Exception();
      }
    } catch (_) {
      // Fallback to local hardcoded initial mock data
      _initializeUserData(email);
    }
  }

  void _addTransaction(String title, double amount, String category, bool isExpense, String walletName) {
    final newTx = TransactionItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: category,
      date: DateTime.now(),
      amount: amount,
      isExpense: isExpense,
      wallet: walletName,
    );

    setState(() {
      _transactions.insert(0, newTx);
      final wallet = _wallets.firstWhere((w) => w.name == walletName);
      if (isExpense) {
        wallet.balance -= amount;
      } else {
        wallet.balance += amount;
      }
    });

    // Notify backend if online
    http.post(
      Uri.parse('$_apiBaseUrl/financial/transaction'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _userEmail,
        'id': newTx.id,
        'title': title,
        'category': category,
        'date': newTx.date.toIso8601String(),
        'amount': amount,
        'isExpense': isExpense,
        'walletName': walletName,
      }),
    ).catchError((_) => http.Response('Offline Fallback', 200));
  }

  void _transferWallet(String from, String to, double amount) {
    setState(() {
      final fWallet = _wallets.firstWhere((w) => w.name == from);
      final tWallet = _wallets.firstWhere((w) => w.name == to);
      fWallet.balance -= amount;
      tWallet.balance += amount;
    });
  }

  Future<void> _askRAG(String question) async {
    setState(() {
      _chatLoading = true;
      _chatHistory.add(ChatMsg(isUser: true, text: question));
    });

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/rag/query'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'question': question,
          'userSegment': _activeChatSegment,
          'docType': 'auto',
          'topK': 3,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception();
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      String answerText = data['jawaban'] ?? 'Tidak ada jawaban.';
      if (_roastMode) {
        answerText += '\n\n🔥 Roast AI: Belanja bulanan kamu boros banget! Kurangi beli kopi Starbucks Caramelnya!';
      }

      setState(() {
        List<dynamic> recs = [];
        if (data['rekomendasi'] is List) {
          recs = data['rekomendasi'] as List<dynamic>;
        } else if (data['rekomendasi'] is String) {
          recs = [data['rekomendasi'] as String];
        } else {
          recs = ['Tips hemat makanan', 'Cara split bill'];
        }

        _chatHistory.add(ChatMsg(
          isUser: false,
          text: answerText,
          directAnswer: (() {
            if (!answerText.contains('Rp')) return null;
            try {
              var amt = answerText.split('Rp')[1].trim().split(' ')[0];
              while (amt.endsWith('.') || amt.endsWith(',')) {
                amt = amt.substring(0, amt.length - 1);
              }
              return 'Rp $amt';
            } catch (_) {
              return null;
            }
          })(),
          contextBadge: answerText.contains('naik') ? '▲ Naik' : answerText.contains('turun') ? '▼ Turun' : '■ Stabil',
          rekomendasi: recs,
          retrievedChunks: data['retrieved_chunks'],
        ));
      });
    } catch (_) {
      // Fallback local simulated RAG response
      Timer(const Duration(milliseconds: 800), () {
        String simAnswer = 'Jawaban Simulasi RAG: Total pengeluaran bulan ini terkendali.';
        if (_roastMode) {
          simAnswer += '\n\n🔥 Roast AI: Dompet kamu udah sekarat!';
        }
        setState(() {
          _chatHistory.add(ChatMsg(
            isUser: false,
            text: simAnswer,
            directAnswer: 'Rp 1.400.000',
            contextBadge: '▲ Naik 12%',
            rekomendasi: const ['Tips hemat makanan', 'Cara split bill'],
          ));
        });
      });
    } finally {
      setState(() {
        _chatLoading = false;
      });
    }
  }

  // Calculations
  double get _totalSaldo => _wallets.fold(0, (sum, w) => sum + w.balance);
  double get _totalPemasukan => _transactions.where((t) => !t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
  double get _totalPengeluaran => _transactions.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);

  void _showScanBonDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.photo_camera, color: Color(0xFF7F77DD), size: 40),
            SizedBox(height: 14),
            Text(
              'Akses Kamera',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          'Cuanly memerlukan izin kamera untuk memindai struk belanja dan mencatat pengeluaran Anda secara otomatis menggunakan AI.',
          style: TextStyle(color: Color(0xFF8B8A88), fontSize: 12, height: 1.4),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(
                  content: Text('Akses kamera ditolak. Fitur OCR struk dinonaktifkan.'),
                  backgroundColor: Color(0xFFE24B4A),
                ),
              );
            },
            child: const Text('Tolak', style: TextStyle(color: Color(0xFF8B8A88), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7F77DD),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(context);
              // Open Camera
              Navigator.push(
                this.context,
                MaterialPageRoute(
                  builder: (context) => CameraScanScreen(
                    apiBaseUrl: _apiBaseUrl,
                    onScanSuccess: (title, amount, category, wallet) {
                      _addTransaction(title, amount, category, true, wallet);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('Berhasil memindai struk: $title senilai Rp ${NumberFormat.format(amount)}.'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            child: const Text('Izinkan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return AuthScreen(
        users: _users,
        currentAccent: widget.currentAccent,
        onLogin: (email, pass) async {
          try {
            final response = await http.post(
              Uri.parse('$_apiBaseUrl/auth/login'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'email': email, 'password': pass}),
            ).timeout(const Duration(seconds: 10));

            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              final user = data['user'];
              final name = user['name'] ?? email.split('@')[0];

              setState(() {
                _isLoggedIn = true;
                _userEmail = email;
                _userName = name;
              });

              await _fetchFinancialData(email);
            } else {
              final errData = jsonDecode(response.body);
              final errMsg = errData['error'] ?? 'Email atau password tidak sesuai!';
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errMsg), backgroundColor: const Color(0xFFE24B4A)),
              );
            }
          } catch (e) {
            // Local offline fallback
            final found = _users.any((u) => u.email == email && u.password == pass);
            if (found) {
              setState(() {
                _isLoggedIn = true;
                _userEmail = email;
                _userName = email.split('@')[0];
                _initializeUserData(email);
              });
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terhubung dalam Mode Offline (Lokal).'), backgroundColor: Colors.orange),
              );
            } else {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Koneksi server gagal.'), backgroundColor: Color(0xFFE24B4A)),
              );
            }
          }
        },
        onRegister: (name, email, pass) async {
          try {
            final response = await http.post(
              Uri.parse('$_apiBaseUrl/auth/register'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'name': name, 'email': email, 'password': pass}),
            ).timeout(const Duration(seconds: 10));

            if (response.statusCode == 200) {
              setState(() {
                if (!_users.any((u) => u.email == email)) {
                  _users.add(UserAccount(name: name, email: email, password: pass));
                }
              });
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Registrasi Sukses! Silakan login.'), backgroundColor: Color(0xFF10B981)),
              );
            } else {
              final errData = jsonDecode(response.body);
              final errMsg = errData['error'] ?? 'Registrasi gagal.';
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errMsg), backgroundColor: const Color(0xFFE24B4A)),
              );
            }
          } catch (e) {
            // Local fallback
            setState(() {
              _users.add(UserAccount(name: name, email: email, password: pass));
            });
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registrasi Lokal Sukses (Mode Offline)! Silakan login.'), backgroundColor: Colors.orange),
            );
          }
        },
      );
    }

    final List<Widget> screens = [
      HomeScreen(
        totalSaldo: _totalSaldo,
        totalPemasukan: _totalPemasukan,
        totalPengeluaran: _totalPengeluaran,
        budgetLimit: _budgetLimit,
        transactions: _transactions,
        wallets: _wallets,
        onScanClick: _showScanBonDialog,
        onNavigateToTab: (idx) => setState(() => _activeTabIndex = idx),
      ),
      WalletScreen(
        wallets: _wallets,
        currentAccent: widget.currentAccent,
        onTransfer: _transferWallet,
      ),
      TransactionScreen(
        transactions: _transactions,
        wallets: _wallets,
        currentAccent: widget.currentAccent,
        onAddTransaction: _addTransaction,
      ),
      AnalysisScreen(
        transactions: _transactions,
        currentAccent: widget.currentAccent,
      ),
      ChatScreen(
        chatHistory: _chatHistory,
        chatLoading: _chatLoading,
        currentAccent: widget.currentAccent,
        demoQuestions: _demoQuestions,
        activeChatSegment: _activeChatSegment,
        onAskQuestion: _askRAG,
        onSegmentChanged: (seg) => setState(() => _activeChatSegment = seg),
        roastMode: _roastMode,
        onRoastModeChanged: (val) => setState(() => _roastMode = val),
        onSettingsClick: () => setState(() => _activeTabIndex = 5),
      ),
      SettingsScreen(
        userName: _userName,
        userEmail: _userEmail,
        budgetLimit: _budgetLimit,
        currentAccent: widget.currentAccent,
        userAvatar: _userAvatar,
        onBudgetLimitChanged: (lim) => setState(() => _budgetLimit = lim),
        onAccentChanged: widget.onAccentChanged,
        onAvatarChanged: (avatar) => setState(() => _userAvatar = avatar),
        onLogout: () => setState(() => _isLoggedIn = false),
      ),
    ];

    final primaryColor = _getPrimaryColor();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: SafeArea(
        child: IndexedStack(
          index: _activeTabIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _activeTabIndex > 4 ? 4 : _activeTabIndex, // clamp settings tab indicator
        onTap: (index) {
          setState(() {
            if (index == 4) {
              // Redirect to Chat or Settings depending on tap
              _activeTabIndex = 4;
            } else {
              _activeTabIndex = index;
            }
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1C1C24),
        selectedItemColor: primaryColor,
        unselectedItemColor: const Color(0xFF8B8A88),
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Dompet'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline_rounded), label: 'Catat'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Analisis'),
          BottomNavigationBarItem(icon: Icon(Icons.forum_rounded), label: 'Tanya AI'),
        ],
      ),
      // Floating Action Button: Kamera di Dashboard, Gear Settings di tab lain
      floatingActionButton: _activeTabIndex == 0
          ? FloatingActionButton(
              onPressed: _showScanBonDialog,
              backgroundColor: const Color(0xFF7F77DD),
              tooltip: 'Pindai Struk OCR',
              child: const Icon(Icons.photo_camera, color: Colors.black, size: 24),
            )
          : (_activeTabIndex != 4 && _activeTabIndex != 5) // Hide on Chat (4) and Settings (5)
              ? FloatingActionButton(
                  onPressed: () => setState(() => _activeTabIndex = 5),
                  backgroundColor: const Color(0xFF1C1C24),
                  mini: true,
                  child: const Icon(Icons.settings, color: Colors.white70),
                )
              : null,
    );
  }
}
