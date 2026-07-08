// Chat message data model with premium layout support
class ChatMsg {
  final bool isUser;
  final String text;
  final bool isOfflineWarning;
  final String? directAnswer;
  final String? contextBadge;
  final List<dynamic>? rekomendasi;
  final String? disclaimer;
  final List<dynamic>? retrievedChunks;
  final String? roastText;
  final String? moodEmoji;

  ChatMsg({
    required this.isUser,
    required this.text,
    this.isOfflineWarning = false,
    this.directAnswer,
    this.contextBadge,
    this.rekomendasi,
    this.disclaimer,
    this.retrievedChunks,
    this.roastText,
    this.moodEmoji,
  });
}
