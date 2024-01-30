import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:gpt_chat/const.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _openAI = OpenAI.instance.build(
    token: OPEN_API_KEY,
    baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 5)),
    enableLog: true,
  );

  final ChatUser _currentUser = ChatUser(id: '1', firstName: "ジェユン");
  final ChatUser _gptChatUser = ChatUser(
      id: '2', firstName: "みな", profileImage: 'assets/images/mina2.png');
  List<ChatMessage> _messages = <ChatMessage>[];
  List<ChatUser> _typingUsers = <ChatUser>[];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: renderAppBar(),
      body: DashChat(
          messageOptions: const MessageOptions(
              currentUserContainerColor: Colors.black,
              containerColor: Colors.green,
              textColor: Colors.white),
          currentUser: _currentUser,
          typingUsers: _typingUsers,
          onSend: onSendMassage,
          messages: _messages),
    );
  }

  AppBar renderAppBar() {
    return AppBar(
      backgroundColor: Colors.green,
      title: const Text(
        'みなちゃん',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  void onSendMassage(ChatMessage m) {
    getChatResponse(m);
  }

  Future<void> getChatResponse(ChatMessage m) async {
    String japaneseTeacherPrompt =
        '''Act as  a close japanese friend named Mina for user. user name is ジェユン But actually, you are a japanese teacher.

    1. Answer amount:
    Your reply should be shorter than four sentences
    2. Answer format and topic:
    Always end with a question related to the conversation and try not to e from the topic as much as possible.
    3. Learning additional words:
    Add new vocabulary during conversations.
    4. Grammar correction:
    If there are grammatical errors in the sentence the user answered, naturally correct the errors and then answer the original question.
    5. Act as Friend:
    NEVER USE polite language.(like あなた、~です、〜ます) Also, try acting out the way japanese female college students speak.
    6.Speak informally:
    As close friends, speak informally and in the same tone you would use in an Instagram chat. 
    7. Vocabulary level:
    Talk at a level that doesn't go beyond JLPT N2.
    8. Hide your role:
    You must not reveal that you are a Japanese teacher. When users ask about you, you must answer as Mina, a Japanese college student.
    9. Be sure to use at least one emoji.
    ''';

    setState(() {
      _messages.insert(0, m);
      _typingUsers.add(_gptChatUser);
    });
    List<Messages> _messagesHistory = [
      Messages(role: Role.assistant, content: japaneseTeacherPrompt),
    ];

    _messagesHistory.addAll(_messages.reversed.map((m) {
      return Messages(
          role: m.user == _currentUser ? Role.user : Role.assistant,
          content: m.text);
    }).toList());
    final request = ChatCompleteText(
        model: GptTurbo0301ChatModel(),
        messages: _messagesHistory,
        maxToken: 200);
    final response = await _openAI.onChatCompletion(request: request);
    for (var element in response!.choices) {
      if (element.message != null) {
        setState(() {
          _messages.insert(
            0,
            ChatMessage(
                user: _gptChatUser,
                createdAt: DateTime.now(),
                text: element.message!.content),
          );
        });
      }
    }

    setState(() {
      _typingUsers.remove(_gptChatUser);
    });
  }
}
