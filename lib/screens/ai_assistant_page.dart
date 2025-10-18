import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> messages = [
    {
      'sender': 'AI',
      'text':
      '👋 Hi there! I’m your AI Task Assistant. You can ask me anything about your tasks, deadlines, or project tips.'
    },
  ];

  // 🚀 This will simulate AI responses for now
  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add({'sender': 'You', 'text': text});
    });

    _controller.clear();

    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        messages.add({
          'sender': 'AI',
          'text': _generateAIResponse(text),
        });
      });

      // Scroll to bottom after response
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // 💡 Simple AI logic (you can connect it to Gemini or OpenAI later)
  String _generateAIResponse(String userInput) {
    userInput = userInput.toLowerCase();

    if (userInput.contains('deadline')) {
      return '⏰ To manage deadlines, break your tasks into smaller milestones and set reminders.';
    } else if (userInput.contains('task')) {
      return '🧾 You can view or assign tasks from your dashboard. Want me to show you how?';
    } else if (userInput.contains('motivate')) {
      return '💪 Remember: small progress every day adds up to big results. Stay consistent!';
    } else if (userInput.contains('hello') || userInput.contains('hi')) {
      return '👋 Hello! How can I assist you today with your tasks?';
    } else {
      return '🤖 I’m not sure about that, but I can help with tasks, deadlines, or productivity tips!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Task Assistant 🤖',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        elevation: 4,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg['sender'] == 'You';
                return Align(
                  alignment:
                  isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color:
                      isUser ? Colors.teal.shade200 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask something about your tasks...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
