import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../theme/app_theme.dart';

class AiChatbotSheet extends StatefulWidget {
  const AiChatbotSheet({super.key});

  @override
  State<AiChatbotSheet> createState() => _AiChatbotSheetState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  _ChatMessage({required this.text, required this.isUser, required this.time});
}

class _AiChatbotSheetState extends State<AiChatbotSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    final user = context.read<AttendanceProvider>().currentUser;
    _messages.add(
      _ChatMessage(
        text: 'வணக்கம் ${user.name}! Hello! I am your Campus AI Assistant.\n'
            'Ask me anything about your attendance, exam eligibility, leave rules, or condonation in English or தமிழ்.',
        isUser: false,
        time: DateTime.now(),
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, time: DateTime.now()));
    });

    _scrollToBottom();

    // AI Response generation using live student data
    final provider = context.read<AttendanceProvider>();
    final user = provider.currentUser;
    final stats = provider.getStudentAttendanceStats(user.id);
    final double pct = (stats['percentage'] as num).toDouble();
    final int lates = stats['late'] as int;
    final int latesAsAbs = stats['latesAsAbsence'] as int;
    final int absent = stats['absent'] as int;
    final int excused = stats['excused'] as int;

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final reply = _generateAiReply(
        query: text.toLowerCase(),
        studentName: user.name,
        percentage: pct,
        lates: lates,
        latesAsAbs: latesAsAbs,
        absent: absent,
        excused: excused,
        leaves: provider.leaveRequests.where((l) => l.studentId == user.id).toList(),
      );

      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false, time: DateTime.now()));
      });
      _scrollToBottom();
    });
  }

  String _generateAiReply({
    required String query,
    required String studentName,
    required double percentage,
    required int lates,
    required int latesAsAbs,
    required int absent,
    required int excused,
    required List<dynamic> leaves,
  }) {
    final bool isTamil = RegExp(r'[\u0B80-\u0BFF]').hasMatch(query) ||
        query.contains('vanakkam') ||
        query.contains('tamil');

    if (query.contains('attendance') || query.contains('percentage') || query.contains('வருகை') || query.contains('சதவீதம்')) {
      if (isTamil) {
        return 'வணக்கம் $studentName. உங்கள் தற்போதைய வருகைப் பதிவு $percentage% ஆகும்.\n'
            '• வருகை மற்றும் தாமதம்: $percentage%\n'
            '• தாமதங்கள்: $lates (இதில் ஒவ்வொரு 3 தாமதங்களும் 1 விடுப்பாகக் கணக்கிடப்படும்: $latesAsAbs விடுப்பு)\n'
            '• அங்கீகரிக்கப்பட்ட விலக்கு (Leave/OD): $excused\n'
            '${percentage < 75.0 ? "⚠️ எச்சரிக்கை: உங்கள் வருகை 75% க்கும் குறைவாக உள்ளது. தயவுசெய்து துறைத் தலைவருக்கு (HOD) Condonation விண்ணப்பிக்கவும்." : "✅ நீங்கள் செமஸ்டர் தேர்வெழுத தகுதியுடையவர்."}';
      }
      return 'Hello $studentName! Your overall attendance is currently $percentage%.\n'
          '• Present & on-time: Recorded\n'
          '• Late arrivals: $lates (converted into $latesAsAbs absences per the 3-lates rule)\n'
          '• Excused sessions: $excused\n'
          '${percentage < 75.0 ? "⚠️ WARNING: You are below the 75% college requirement. You must submit a Condonation application with medical proof to the HOD." : "✅ You are currently in the safe zone for semester exams."}';
    }

    if (query.contains('rule') || query.contains('late') || query.contains('தாமதம்') || query.contains('விதி')) {
      if (isTamil) {
        return 'வருகைப் பதிவு விதிகள்:\n'
            '1. வகுப்பு தொடங்கிய 10 நிமிடங்களுக்குள் தட்டினால் -> Present (முழு வருகை).\n'
            '2. 10 நிமிடங்களுக்குப் பிறகு தட்டினால் -> Late (தாமதம்).\n'
            '3. ஒவ்வொரு 3 தாமதங்களும் (3 Lates) = 1 முழு நாள் விடுப்பாக (1 Absence) தானாக மாறும்!\n'
            '4. ஆசிரியர் அங்கீகரித்த Leave அல்லது On-Duty மொத்த வகுப்புகளிலிருந்து விலக்கப்படும்.';
      }
      return 'Campus Attendance Rules:\n'
          '1. Tap within 10 minutes of session start = PRESENT.\n'
          '2. Tap after 10 minutes = LATE.\n'
          '3. Every 3 late scans count as 1 absence against your attendance percentage!\n'
          '4. Approved Leave or OD removes the session from the total count (Excused).';
    }

    if (query.contains('condonation') || query.contains('கண்டோனேஷன்') || query.contains('விலக்கு') || query.contains('exam')) {
      if (isTamil) {
        return 'Condonation (வருகை விலக்கு) விதிமுறைகள்:\n'
            'வருகை 75%க்கு கீழே குறைந்துவிட்டால், மருத்துவச் சான்றிதழுடன் (Medical Certificate) மாணவர் போர்ட்டலில் விண்ணப்பிக்க வேண்டும். துறைத்தலைவர் (HOD) அதை ஆய்வு செய்து ஒப்புதல் அளிப்பார்.';
      }
      return 'Condonation Policy:\n'
          'Students with attendance below 75% can apply for Condonation by uploading medical/hospitalization documents. The Head of Department (HOD) will review the application and grant semester exam eligibility upon approval.';
    }

    if (query.contains('leave') || query.contains('od') || query.contains('விடுப்பு')) {
      if (isTamil) {
        return 'நீங்கள் மாணவர் திரையில் உள்ள "Apply Leave / OD" பொத்தானை அழுத்தி விடுப்பு அல்லது ஆன்-டியூட்டிக்கு விண்ணப்பிக்கலாம். உங்கள் வகுப்பு ஆலோசகர் (Advisor) அதை மதிப்பாய்வு செய்வார்.';
      }
      return 'You can submit Leave or On-Duty (OD) applications from the Student Portal. Once approved by your class advisor, affected sessions will be marked as Excused.';
    }

    if (isTamil) {
      return 'வணக்கம் $studentName! நான் உங்கள் கல்வி உதவியாளர். வருகை விவரம், தாமதக் கணக்கு அல்லது Condonation குறித்து ஏதேனும் உதவி தேவையா?';
    }
    return 'I can assist you with attendance records, the 3-lates-to-1-absence rule, semester exam eligibility, or applying for Leave/Condonation. Type your question in English or தமிழ்!';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkLine : AppTheme.lightLine,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSoft : AppTheme.lightSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Campus AI Assistant',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                        ),
                      ),
                      Text(
                        'Tool calling • English & தமிழ்',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 16),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isUser
                          ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                          : (isDark ? AppTheme.darkPanel : AppTheme.lightPanel),
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
                        bottomLeft: !msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
                      ),
                      border: msg.isUser
                          ? null
                          : Border.all(color: isDark ? AppTheme.darkLine : AppTheme.lightLine),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: msg.isUser
                            ? (isDark ? const Color(0xFF072722) : Colors.white)
                            : (isDark ? AppTheme.darkFg : AppTheme.lightFg),
                        fontWeight: msg.isUser ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Quick Suggestion Chips
          Container(
            height: 38,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _quickChip('What is my attendance %?'),
                _quickChip('Explain the 3-lates rule'),
                _quickChip('நான் தேர்வெழுத தகுதியா?'),
                _quickChip('How to apply for condonation?'),
              ],
            ),
          ),

          // Text Input Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkPanel : AppTheme.lightPanel,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppTheme.darkLine : AppTheme.lightLine,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Ask in English or தமிழ்...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded, size: 18),
                  onPressed: () => _sendMessage(_textController.text),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                    foregroundColor: isDark ? const Color(0xFF072722) : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickChip(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 11)),
        backgroundColor: isDark ? AppTheme.darkSoft : AppTheme.lightSoft,
        labelStyle: TextStyle(
          color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        onPressed: () => _sendMessage(text),
      ),
    );
  }
}
