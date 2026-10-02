import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() => runApp(const MaybankApp());

class MaybankApp extends StatelessWidget {
  const MaybankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CAPITÃO MAYBANK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const ChatPage(),
    );
  }
}

class Msg {
  final String text;
  final bool mine;
  Msg(this.text, this.mine);
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Msg> msgs = [];
  final TextEditingController ctrl = TextEditingController();
  final ScrollController scroll = ScrollController();
  final FlutterTts tts = FlutterTts();
  final SpeechToText stt = SpeechToText();
  bool sttOk = false;
  bool listening = false;
  bool voiceOn = true;
  String userName = 'Chefe';

  @override
  void initState() {
    super.initState();
    _setup();
    msgs.add(Msg('Opa! Eu sou o CAPITÃO MAYBANK. Fale ou digite.', false));
  }

  Future<void> _setup() async {
    await tts.setLanguage('pt-BR');
    await tts.setPitch(0.6);
    await tts.setSpeechRate(0.5);
    sttOk = await stt.initialize();
    if (mounted) setState(() {});
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _answer(String input) {
    final t = input.toLowerCase().trim();
    if (t.startsWith('meu nome é ') || t.startsWith('meu nome e ')) {
      final n = input.trim().substring(11).trim();
      if (n.isNotEmpty) {
        userName = n;
        return 'Prazer, $userName! Vou te chamar assim.';
      }
    }
    if (RegExp(r'^(opa|oi|olá|ola|e aí|e ai|eae|salve)').hasMatch(t)) {
      return 'Opa, $userName! Em que posso ajudar?';
    }
    if (t.contains('hora')) {
      final n = DateTime.now();
      return 'Agora são ${_two(n.hour)}:${_two(n.minute)}.';
    }
    if (t.contains('data') || t.contains('dia é hoje') || t.contains('que dia')) {
      final n = DateTime.now();
      return 'Hoje é ${_two(n.day)}/${_two(n.month)}/${n.year}.';
    }
    if (t.contains('quem é você') || t.contains('quem e voce') || t.contains('seu nome')) {
      return 'Sou o CAPITÃO MAYBANK, seu assistente pessoal.';
    }
    if (t.contains('como você está') || t.contains('tudo bem')) {
      return 'Tudo certo por aqui, $userName! E você?';
    }
    if (t.contains('obrigado') || t.contains('valeu')) {
      return 'Sempre às ordens, $userName!';
    }
    return 'Ainda estou aprendendo essa, $userName. Na próxima versão vou responder qualquer assunto.';
  }

  void _send(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    final r = _answer(t);
    setState(() {
      msgs.add(Msg(t, true));
      msgs.add(Msg(r, false));
    });
    ctrl.clear();
    if (voiceOn) tts.speak(r);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scroll.hasClients) {
        scroll.animateTo(scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _mic() async {
    if (!sttOk) {
      setState(() => msgs.add(Msg('Microfone indisponível. Verifique a permissão.', false)));
      return;
    }
    if (listening) {
      await stt.stop();
      setState(() => listening = false);
      return;
    }
    setState(() => listening = true);
    await stt.listen(
      localeId: 'pt_BR',
      onResult: (r) {
        if (r.finalResult) {
          setState(() => listening = false);
          _send(r.recognizedWords);
        }
      },
    );
  }

  @override
  void dispose() {
    ctrl.dispose();
    scroll.dispose();
    tts.stop();
    stt.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CAPITÃO MAYBANK'),
        actions: [
          IconButton(
            icon: Icon(voiceOn ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() => voiceOn = !voiceOn);
              if (!voiceOn) tts.stop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.all(12),
              itemCount: msgs.length,
              itemBuilder: (c, i) {
                final m = msgs[i];
                return Align(
                  alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: m.mine ? Colors.blue.shade800 : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(m.text, style: const TextStyle(fontSize: 16)),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(listening ? Icons.mic : Icons.mic_none,
                        color: listening ? Colors.red : null),
                    onPressed: _mic,
                  ),
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      onSubmitted: _send,
                      decoration: const InputDecoration(
                        hintText: 'Fale ou digite...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _send(ctrl.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
