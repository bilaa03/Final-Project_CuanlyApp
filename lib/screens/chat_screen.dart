import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/demo_question.dart';

class ChatScreen extends StatefulWidget {
  final List<ChatMsg> chatHistory;
  final bool chatLoading;
  final String currentAccent;
  final List<DemoQuestion> demoQuestions;
  final String activeChatSegment;
  final Function(String) onAskQuestion;
  final Function(String) onSegmentChanged;
  final bool roastMode;
  final ValueChanged<bool> onRoastModeChanged;
  final VoidCallback? onSettingsClick;

  const ChatScreen({
    super.key,
    required this.chatHistory,
    required this.chatLoading,
    required this.currentAccent,
    required this.demoQuestions,
    required this.activeChatSegment,
    required this.onAskQuestion,
    required this.onSegmentChanged,
    required this.roastMode,
    required this.onRoastModeChanged,
    this.onSettingsClick,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chatHistory.length != oldWidget.chatHistory.length || widget.chatLoading != oldWidget.chatLoading) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getPrimaryColor();
    final filteredQuestions = widget.demoQuestions.where((q) => q.segment == widget.activeChatSegment).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.auto_awesome, color: primaryColor, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuanly',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Active Intelligence',
                  style: TextStyle(fontSize: 10, color: Color(0xFF8B8A88)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Roast Mode Toggle in appbar
          Row(
            children: [
              Icon(Icons.local_fire_department, color: widget.roastMode ? const Color(0xFFD85A30) : const Color(0xFF8B8A88), size: 18),
              const SizedBox(width: 4),
              const Text('Roast', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              Switch(
                value: widget.roastMode,
                onChanged: widget.onRoastModeChanged,
                activeThumbColor: const Color(0xFFD85A30),
              ),
            ],
          ),
          if (widget.onSettingsClick != null)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70, size: 20),
              onPressed: widget.onSettingsClick,
            ),
        ],
      ),
      body: Column(
        children: [
          // Segment selector B2B / B2C
          Container(
            color: const Color(0xFF1C1C24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onSegmentChanged('b2c'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.activeChatSegment == 'b2c' ? primaryColor.withValues(alpha: 0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.activeChatSegment == 'b2c' ? primaryColor.withValues(alpha: 0.3) : Colors.transparent,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Personal (B2C)',
                        style: TextStyle(
                          color: widget.activeChatSegment == 'b2c' ? primaryColor : const Color(0xFF8B8A88),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onSegmentChanged('b2b'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.activeChatSegment == 'b2b' ? primaryColor.withValues(alpha: 0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.activeChatSegment == 'b2b' ? primaryColor.withValues(alpha: 0.3) : Colors.transparent,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Bisnis / Kantor (B2B)',
                        style: TextStyle(
                          color: widget.activeChatSegment == 'b2b' ? primaryColor : const Color(0xFF8B8A88),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages View
          Expanded(
            child: widget.chatHistory.isEmpty
                ? _buildEmptyState(filteredQuestions)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.chatHistory.length,
                    itemBuilder: (context, index) {
                      final msg = widget.chatHistory[index];
                      return _buildChatBubble(msg, primaryColor);
                    },
                  ),
          ),

          // Typing Indicator animation
          if (widget.chatLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C24),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7F77DD)),
                    ),
                    SizedBox(width: 8),
                    Text('Cuanly sedang berpikir...', style: TextStyle(color: Color(0xFF8B8A88), fontSize: 11)),
                  ],
                ),
              ),
            ),

          // Suggestion Chips (if not loading)
          if (!widget.chatLoading && widget.chatHistory.isNotEmpty)
            _buildQuickReplies(filteredQuestions),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C24),
              border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Tanya Cuanly...',
                        hintStyle: TextStyle(color: Color(0xFF8B8A88), fontSize: 13),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          widget.onAskQuestion(val.trim());
                          _inputController.clear();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final txt = _inputController.text.trim();
                    if (txt.isNotEmpty) {
                      widget.onAskQuestion(txt);
                      _inputController.clear();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.black, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(List<DemoQuestion> filtered) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF7F77DD).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFF7F77DD), size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tanya Cuanly',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ajukan pertanyaan seputar budget, pengeluaran kantor, atau simulasi split bill.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8B8A88), fontSize: 12),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: filtered.map((dq) {
                return GestureDetector(
                  onTap: () => widget.onAskQuestion(dq.question),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C24),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Text(
                      dq.label,
                      style: const TextStyle(color: Color(0xFF8B8A88), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMsg msg, Color primary) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: msg.isUser ? const Color(0xFF534AB7) : const Color(0xFF1C1C24),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: msg.isUser ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
          ),
          border: msg.isUser ? null : Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium layout elements
            if (!msg.isUser) ...[
              // Part 1: Direct Answer block
              if (msg.directAnswer != null) ...[
                Text(
                  msg.directAnswer!,
                  style: const TextStyle(
                    color: Color(0xFF7F77DD),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              // Part 2: Context Badge
              if (msg.contextBadge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D9E75).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    msg.contextBadge!,
                    style: const TextStyle(color: Color(0xFF1D9E75), fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],

            // Main Text Body
            Text(
              msg.text,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            ),

            // Roast commentary sub-card
            if (msg.roastText != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD85A30).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD85A30).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        msg.roastText!,
                        style: const TextStyle(color: Color(0xFFD85A30), fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Chunks retrieval indicators for B2B transparency
            if (msg.retrievedChunks != null && msg.retrievedChunks!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.source, size: 12, color: Color(0xFF8B8A88)),
                    const SizedBox(width: 6),
                    Text(
                      'AI RAG: ${msg.retrievedChunks!.length} Dokumen lokal dirujuk.',
                      style: const TextStyle(color: Color(0xFF8B8A88), fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
            
            // Part 3: Rekomendasi / CTA Quick Replies inside chat bubble
            if (msg.rekomendasi != null && msg.rekomendasi!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: msg.rekomendasi!.map((rec) {
                  return GestureDetector(
                    onTap: () => widget.onAskQuestion(rec.toString()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7F77DD).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF7F77DD).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        rec.toString(),
                        style: const TextStyle(color: Color(0xFF7F77DD), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplies(List<DemoQuestion> filtered) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filtered.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final dq = filtered[index];
          return GestureDetector(
            onTap: () => widget.onAskQuestion(dq.question),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C24),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              alignment: Alignment.center,
              child: Text(
                dq.label,
                style: const TextStyle(color: Color(0xFF8B8A88), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}
