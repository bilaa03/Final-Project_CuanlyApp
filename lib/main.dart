import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const FinSightApp());
}

class FinSightApp extends StatelessWidget {
  const FinSightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FinSight AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF127C74),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F8),
        useMaterial3: true,
      ),
      home: const FinSightHomePage(),
    );
  }
}

class DemoQuestion {
  const DemoQuestion(this.label, this.segment, this.question);

  final String label;
  final String segment;
  final String question;
}

class FinSightHomePage extends StatefulWidget {
  const FinSightHomePage({super.key});

  @override
  State<FinSightHomePage> createState() => _FinSightHomePageState();
}

class _FinSightHomePageState extends State<FinSightHomePage> {
  static const apiBaseUrl = 'http://localhost:8787';

  final controller = TextEditingController(
    text:
        'Apakah klaim makan klien senilai Rp 500.000 ini sesuai dengan policy expense perusahaan?',
  );

  final demos = const [
    DemoQuestion(
      'Budget B2C',
      'b2c',
      'Berapa total pengeluaranku bulan ini dan apakah sudah melebihi budget?',
    ),
    DemoQuestion(
      'Tips Transport',
      'b2c',
      'Apa tips menghemat pengeluaran transport?',
    ),
    DemoQuestion(
      'Investasi',
      'b2c',
      'Apakah FinSight AI bisa memberi saran investasi saham?',
    ),
    DemoQuestion(
      'Client Meal',
      'b2b',
      'Apakah klaim makan klien senilai Rp 500.000 ini sesuai dengan policy expense perusahaan?',
    ),
    DemoQuestion(
      'Akomodasi',
      'b2b',
      'Berapa batas maksimum reimbursement untuk akomodasi hotel?',
    ),
    DemoQuestion('Out-of-domain', 'b2c', 'Siapa presiden Indonesia saat ini?'),
  ];

  String segment = 'b2b';
  String docType = 'auto';
  bool loading = false;
  Map<String, dynamic>? result;
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> ask() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/rag/query'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'question': controller.text,
          'userSegment': segment,
          'docType': docType,
          'topK': 3,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('API error ${response.statusCode}: ${response.body}');
      }

      setState(
        () => result = jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      setState(() {
        error =
            'Backend belum aktif atau request gagal. Jalankan: cd backend && npm start\n\n$e';
      });
    } finally {
      setState(() => loading = false);
    }
  }

  void useDemo(DemoQuestion demo) {
    setState(() {
      controller.text = demo.question;
      segment = demo.segment;
      docType = 'auto';
    });
    ask();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            return Row(
              children: [
                SizedBox(
                  width: wide ? 360 : constraints.maxWidth,
                  child: _ControlPanel(
                    controller: controller,
                    demos: demos,
                    segment: segment,
                    docType: docType,
                    loading: loading,
                    onSegmentChanged: (value) =>
                        setState(() => segment = value),
                    onDocTypeChanged: (value) =>
                        setState(() => docType = value),
                    onAsk: ask,
                    onDemo: useDemo,
                  ),
                ),
                if (wide) const VerticalDivider(width: 1),
                if (wide)
                  Expanded(
                    child: _ResultPanel(
                      result: result,
                      error: error,
                      loading: loading,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      bottomSheet: MediaQuery.of(context).size.width < 980
          ? DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.48,
              minChildSize: 0.2,
              maxChildSize: 0.88,
              builder: (context, scrollController) => _ResultPanel(
                result: result,
                error: error,
                loading: loading,
                scrollController: scrollController,
              ),
            )
          : null,
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.controller,
    required this.demos,
    required this.segment,
    required this.docType,
    required this.loading,
    required this.onSegmentChanged,
    required this.onDocTypeChanged,
    required this.onAsk,
    required this.onDemo,
  });

  final TextEditingController controller;
  final List<DemoQuestion> demos;
  final String segment;
  final String docType;
  final bool loading;
  final ValueChanged<String> onSegmentChanged;
  final ValueChanged<String> onDocTypeChanged;
  final VoidCallback onAsk;
  final ValueChanged<DemoQuestion> onDemo;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF127C74),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.query_stats, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FinSight AI',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'RAG Finance Assistant',
                      style: TextStyle(color: Color(0xFF5B6670)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Segmen', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'b2c',
                label: Text('B2C'),
                icon: Icon(Icons.person),
              ),
              ButtonSegment(
                value: 'b2b',
                label: Text('B2B'),
                icon: Icon(Icons.apartment),
              ),
            ],
            selected: {segment},
            onSelectionChanged: (value) => onSegmentChanged(value.first),
          ),
          const SizedBox(height: 16),
          const Text('Sumber', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: docType,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'auto', child: Text('Auto detect')),
              DropdownMenuItem(value: 'faq', child: Text('FAQ')),
              DropdownMenuItem(value: 'policy', child: Text('Policy')),
              DropdownMenuItem(value: 'transaksi', child: Text('Transaksi')),
            ],
            onChanged: (value) => onDocTypeChanged(value ?? 'auto'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pertanyaan',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            minLines: 5,
            maxLines: 8,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Tulis pertanyaan user...',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: loading ? null : onAsk,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: const Text('Run RAG Demo'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Contoh Demo',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final demo in demos)
                ActionChip(
                  avatar: Icon(
                    demo.segment == 'b2b' ? Icons.apartment : Icons.person,
                    size: 18,
                  ),
                  label: Text(demo.label),
                  onPressed: loading ? null : () => onDemo(demo),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const _InfoBox(),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCDE7E1)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Demo covers', style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text(
            'RAG workflow, metadata filter, chunk evidence, guardrail out-of-domain, JSON output, dan Prisma MySQL schema.',
          ),
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.result,
    required this.error,
    required this.loading,
    this.scrollController,
  });

  final Map<String, dynamic>? result;
  final String? error;
  final bool loading;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7F8),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Structured RAG Output',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
              if (loading) const CircularProgressIndicator(),
            ],
          ),
          const SizedBox(height: 16),
          if (error != null)
            _PanelCard(
              child: Text(
                error!,
                style: const TextStyle(color: Color(0xFFB3261E)),
              ),
            ),
          if (result == null && error == null)
            const _PanelCard(
              child: Text(
                'Klik salah satu contoh demo atau tekan Run RAG Demo untuk melihat jawaban, evidence chunk, dan workflow.',
              ),
            ),
          if (result != null) ...[
            _AnswerCard(result: result!),
            const SizedBox(height: 12),
            _WorkflowCard(result: result!),
            const SizedBox(height: 12),
            _ChunksCard(result: result!),
          ],
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final filter = result['metadata_filter'] as Map<String, dynamic>? ?? {};
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Badge(label: 'Status: ${result['status'] ?? '-'}'),
              _Badge(label: 'Segment: ${filter['user_segment'] ?? '-'}'),
              _Badge(label: 'Doc: ${filter['doc_type'] ?? '-'}'),
              _Badge(label: 'Kategori: ${filter['kategori'] ?? '-'}'),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Jawaban',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '${result['jawaban'] ?? '-'}',
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Rekomendasi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '${result['rekomendasi'] ?? '-'}',
            style: const TextStyle(height: 1.4),
          ),
          if (result['disclaimer'] != null) ...[
            const SizedBox(height: 16),
            Text(
              '${result['disclaimer']}',
              style: const TextStyle(
                color: Color(0xFF5B6670),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final workflow = (result['workflow'] as List<dynamic>? ?? [])
        .cast<String>();
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RAG Workflow',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < workflow.length; i++)
                Chip(
                  avatar: CircleAvatar(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  label: Text(workflow[i]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChunksCard extends StatelessWidget {
  const _ChunksCard({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final chunks = result['retrieved_chunks'] as List<dynamic>? ?? [];
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Retrieved Chunks',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (chunks.isEmpty)
            const Text('Tidak ada chunk relevan yang melewati threshold.'),
          for (final item in chunks)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD8DEE4)),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Badge(label: '${item['chunk_id']}'),
                      _Badge(label: 'score ${item['score']}'),
                      _Badge(label: '${item['metadata']?['source'] ?? '-'}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item['text']}',
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E5EA)),
      ),
      child: child,
    );
  }
}
