import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud/chat_models.dart';
import 'cloud/cloud_service.dart';

const String kBackgroundAsset = 'assets/kalantar_bg.jpg';
const Color kPurple = Color(0xFF9A66FF);
const Color kBlue = Color(0xFF25AFFF);
const Color kRed = Color(0xFFFF3B62);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await CloudService.instance.init();
  runApp(KalantarApp(prefs: prefs));
}

final ThemeData kTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFF020306),
  colorScheme: const ColorScheme.dark(
    primary: kPurple,
    secondary: kBlue,
    surface: Color(0xFF0A0B10),
    error: kRed,
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xDD080910),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
      borderSide: BorderSide(color: Color(0x443F4250)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
      borderSide: BorderSide(color: Color(0x443F4250)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
      borderSide: BorderSide(color: kPurple, width: 1.5),
    ),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Color(0xF2080910),
    indicatorColor: Color(0x339A66FF),
    height: 72,
  ),
  snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
);

class KalantarApp extends StatelessWidget {
  const KalantarApp({super.key, required this.prefs});
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'کلانتر',
      theme: kTheme,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: RootPage(prefs: prefs),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key, required this.prefs});
  final SharedPreferences prefs;

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  bool loading = true;
  bool loggedIn = false;
  int tab = 0;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() {
          loading = false;
          loggedIn = CloudService.instance.configured;
        });
      }
    });
  }

  Future<void> _loginDone() async {
    if (mounted) setState(() => loggedIn = true);
  }

  Future<void> _logout() async {
    await CloudService.instance.disconnect();
    if (mounted) setState(() { loggedIn = false; tab = 0; });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const SplashPage();
    if (!loggedIn) return LoginPage(onLoggedIn: _loginDone);

    final pages = <Widget>[
      HomePage(onNavigate: (value) => setState(() => tab = value)),
      const ChatPage(),
      const CheckInPage(),
      const GamesPage(),
      const MediaPage(),
      SettingsPage(onLogout: _logout),
    ];

    return Scaffold(
      body: Bg(child: pages[tab]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (value) => setState(() => tab = value),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'خانه'),
                NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: 'چت'),
                NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'حال من'),
                NavigationDestination(icon: Icon(Icons.sports_esports_outlined), selectedIcon: Icon(Icons.sports_esports), label: 'بازی'),
                NavigationDestination(icon: Icon(Icons.perm_media_outlined), selectedIcon: Icon(Icons.perm_media), label: 'رسانه'),
                NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'تنظیمات'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Bg extends StatelessWidget {
  const Bg({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.asset(
          kBackgroundAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: const Color(0xFF05060A)),
        ),
        Container(color: const Color(0xC8000006)),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0x22180A2F),
                Color(0xA5020308),
                Color(0xEF020306),
              ],
            ),
          ),
        ),
        SafeArea(child: child),
      ],
    );
  }
}

class Glass extends StatelessWidget {
  const Glass({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xD7090A11),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: child,
    );
  }
}

class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 72});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(color: Color(0x669A66FF), blurRadius: 34, spreadRadius: 2),
        ],
      ),
      child: ClipOval(child: Image.asset('assets/logo.png', fit: BoxFit.cover)),
    );
  }
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Bg(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Logo(size: 112),
            SizedBox(height: 18),
            Text('کلانتر', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
            SizedBox(height: 6),
            Text('سه نفر • یک فضای مشترک • هویت ناشناس', style: TextStyle(color: Colors.white54)),
            SizedBox(height: 24),
            SizedBox(width: 150, child: LinearProgressIndicator(minHeight: 4)),
          ],
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Logo(size: 54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      ],
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLoggedIn});
  final Future<void> Function() onLoggedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final password = TextEditingController();
  final server = TextEditingController(
    text: const String.fromEnvironment('KALANTAR_API_URL', defaultValue: ''),
  );
  String role = 'person1';
  bool busy = false;
  String error = '';

  @override
  void dispose() {
    password.dispose();
    server.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (server.text.trim().isEmpty) {
      setState(() => error = 'آدرس سرور این نسخه تنظیم نشده است.');
      return;
    }
    if (password.text.trim().length < 4) {
      setState(() => error = 'رمز کلید ناشناس را وارد کن.');
      return;
    }

    setState(() { busy = true; error = ''; });
    try {
      await CloudService.instance.setServerUrl(server.text.trim());
      await CloudService.instance.login(role: role, password: password.text.trim());
      await widget.onLoggedIn();
    } catch (e) {
      setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final names = <String>['کلید A', 'کلید B', 'کلید C'];
    return Bg(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Glass(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Center(child: Logo(size: 108)),
                  const SizedBox(height: 18),
                  const Text('ورود ناشناس', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  const Text('هر سه نفر به یک فضای مشترک وصل می‌شوند؛ در رابط کاربری نام و نقش واقعی نمایش داده نمی‌شود.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, height: 1.5)),
                  const SizedBox(height: 18),
                  Row(
                    children: List<Widget>.generate(3, (int index) {
                      final id = 'person${index + 1}';
                      final selected = role == id;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: index == 2 ? 0 : 6),
                          child: InkWell(
                            onTap: () => setState(() => role = id),
                            borderRadius: BorderRadius.circular(18),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: selected ? const Color(0x339A66FF) : const Color(0x22101018),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: selected ? kPurple : Colors.white12),
                              ),
                              child: Column(
                                children: <Widget>[
                                  Icon(Icons.shield_outlined, color: selected ? kPurple : Colors.grey),
                                  const SizedBox(height: 5),
                                  Text(names[index], style: TextStyle(fontWeight: FontWeight.w800, color: selected ? Colors.white : Colors.white70)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(labelText: 'رمز کلید ناشناس', prefixIcon: Icon(Icons.key)),
                  ),
                  if (const String.fromEnvironment('KALANTAR_API_URL', defaultValue: '').isEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    TextField(
                      controller: server,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(labelText: 'آدرس سرور Railway', prefixIcon: Icon(Icons.dns_outlined)),
                    ),
                  ],
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: busy ? null : submit,
                    icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.login),
                    label: const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Text('ورود به کلانتر')),
                  ),
                  if (error.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFF7B90), height: 1.5)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String friendlyError(Object error) {
  final String text = error.toString();
  if (text.contains('invalid_login')) return 'رمز کلید ناشناس اشتباه است.';
  if (text.contains('server_credentials_missing')) return 'رمزهای سه حساب روی Railway کامل نشده‌اند.';
  if (text.contains('connection') || text.contains('SocketException')) return 'ارتباط با Railway برقرار نشد.';
  return 'ورود انجام نشد؛ تنظیمات سرور را بررسی کن.';
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final title = TextEditingController();
  final body = TextEditingController();
  List<Map<String, dynamic>> notes = <Map<String, dynamic>>[];
  StreamSubscription<void>? changes;

  @override
  void initState() {
    super.initState();
    loadNotes();
    changes = CloudService.instance.contentChanges.stream.listen((_) => loadNotes());
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    changes?.cancel();
    super.dispose();
  }

  Future<void> loadNotes() async {
    try {
      final data = await CloudService.instance.fetchSharedNotes();
      if (mounted) setState(() => notes = data);
    } catch (_) {}
  }

  Future<void> addNote() async {
    title.clear();
    body.clear();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('یادداشت مشترک'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان')),
            const SizedBox(height: 10),
            TextField(controller: body, maxLines: 5, decoration: const InputDecoration(labelText: 'متن')),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لغو')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ذخیره')),
        ],
      ),
    );
    if (ok != true || body.text.trim().isEmpty) return;
    final String now = DateTime.now().toUtc().toIso8601String();
    final newNote = <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'title': title.text.trim(),
      'body': body.text.trim(),
      'createdAt': now,
      'updatedAt': now,
    };
    await CloudService.instance.saveSharedNotes(<Map<String, dynamic>>[...notes, newNote]);
    await loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      children: <Widget>[
        const PageHeader(title: 'کلانتر', subtitle: 'سه نفر • یک فضای مشترک • بدون نمایش هویت'),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(child: QuickButton(title: 'حال من', icon: Icons.favorite, color: kRed, onTap: () => widget.onNavigate(2))),
            const SizedBox(width: 10),
            Expanded(child: QuickButton(title: 'بازی', icon: Icons.sports_esports, color: kBlue, onTap: () => widget.onNavigate(3))),
            const SizedBox(width: 10),
            Expanded(child: QuickButton(title: 'رسانه', icon: Icons.perm_media, color: kPurple, onTap: () => widget.onNavigate(4))),
          ],
        ),
        const SizedBox(height: 14),
        Glass(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(child: Text('دفتر مشترک', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
                  IconButton(onPressed: addNote, icon: const Icon(Icons.add_circle_outline, color: kPurple)),
                ],
              ),
              const SizedBox(height: 5),
              if (notes.isEmpty)
                const Text('هنوز یادداشت مشترکی ثبت نشده است.', style: TextStyle(color: Colors.white54))
              else
                ...notes.take(5).map(
                  (Map<String, dynamic> note) => Container(
                    margin: const EdgeInsets.only(bottom: 9),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0x221A1724), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(note['title']?.toString().isNotEmpty == true ? note['title'].toString() : 'بدون عنوان', style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(note['body']?.toString() ?? '', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, height: 1.5)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class QuickButton extends StatelessWidget {
  const QuickButton({super.key, required this.title, required this.icon, required this.color, required this.onTap});
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Glass(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Column(
          children: <Widget>[
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 7),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final input = TextEditingController();
  final scroll = ScrollController();
  final picker = ImagePicker();
  final recorder = AudioRecorder();
  final player = AudioPlayer();
  final List<ChatMessage> messages = <ChatMessage>[];
  StreamSubscription<ChatMessage>? subscription;
  bool loading = true;
  bool sending = false;
  bool recording = false;
  String? playingId;

  @override
  void initState() {
    super.initState();
    loadMessages();
    subscription = CloudService.instance.incomingMessages.stream.listen((ChatMessage message) {
      if (messages.any((ChatMessage item) => item.id == message.id)) return;
      if (mounted) setState(() => messages.add(message));
      scrollBottom();
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    input.dispose();
    scroll.dispose();
    recorder.dispose();
    player.dispose();
    super.dispose();
  }

  Future<void> loadMessages() async {
    try {
      final List<ChatMessage> loaded = await CloudService.instance.fetchMessages();
      if (mounted) setState(() { messages..clear()..addAll(loaded); loading = false; });
      scrollBottom(false);
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  void scrollBottom([bool animate = true]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scroll.hasClients) return;
      final double target = scroll.position.maxScrollExtent;
      if (animate) {
        scroll.animateTo(target, duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
      } else {
        scroll.jumpTo(target);
      }
    });
  }

  Future<void> sendText() async {
    final String text = input.text.trim();
    if (text.isEmpty || sending) return;
    setState(() => sending = true);
    input.clear();
    try {
      final ChatMessage message = await CloudService.instance.sendText(text);
      if (mounted && !messages.any((ChatMessage item) => item.id == message.id)) setState(() => messages.add(message));
      scrollBottom();
    } catch (_) {
      input.text = text;
      showSnack('ارسال انجام نشد.');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> pickImage() async {
    final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (file != null) await sendFile(file.path, 'image');
  }

  Future<void> pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
    final String? path = result?.files.single.path;
    if (path != null) await sendFile(path, 'file');
  }

  Future<void> toggleRecord() async {
    if (recording) {
      final String? path = await recorder.stop();
      if (mounted) setState(() => recording = false);
      if (path != null) await sendFile(path, 'audio');
      return;
    }
    if (!await recorder.hasPermission()) {
      showSnack('مجوز میکروفون لازم است.');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/chat_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await recorder.start(const RecordConfig(), path: path);
    if (mounted) setState(() => recording = true);
  }

  Future<void> sendFile(String path, String kind) async {
    if (sending) return;
    setState(() => sending = true);
    try {
      final ChatMessage message = await CloudService.instance.sendAttachment(path: path, kind: kind);
      if (mounted && !messages.any((ChatMessage item) => item.id == message.id)) setState(() => messages.add(message));
      scrollBottom();
    } catch (_) {
      showSnack('فایل ارسال نشد.');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> playAudio(ChatMessage message) async {
    if (!message.hasAttachment) return;
    try {
      final List<int> bytes = await CloudService.instance.downloadMediaBytes(message.attachmentId!);
      await player.play(BytesSource(Uint8List.fromList(bytes)));
      if (mounted) setState(() => playingId = message.id);
    } catch (_) {
      showSnack('پخش ممکن نشد.');
    }
  }

  void showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Padding(padding: EdgeInsets.fromLTRB(18, 12, 18, 8), child: PageHeader(title: 'چت مشترک', subtitle: 'پیام‌ها برای هر سه نفر • نمایش «ناشناس»')),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  itemCount: messages.length,
                  itemBuilder: (_, int index) {
                    final ChatMessage message = messages[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xDD080910),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('پیام ناشناس', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700)),
                          if (message.body.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 5),
                            Text(message.body, style: const TextStyle(height: 1.5)),
                          ],
                          if (message.type == 'image' && message.hasAttachment)
                            const Padding(padding: EdgeInsets.only(top: 8), child: Icon(Icons.image_outlined, color: kBlue, size: 30)),
                          if (message.type == 'audio' && message.hasAttachment)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TextButton.icon(
                                onPressed: () => playAudio(message),
                                icon: Icon(playingId == message.id ? Icons.stop_circle : Icons.play_circle_fill),
                                label: Text(playingId == message.id ? 'در حال پخش' : 'پخش صدا'),
                              ),
                            ),
                          if (message.attachmentName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(message.attachmentName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Glass(
              padding: const EdgeInsets.all(7),
              child: Row(
                children: <Widget>[
                  IconButton(onPressed: sending ? null : pickImage, icon: const Icon(Icons.image_outlined, color: kBlue)),
                  IconButton(onPressed: sending ? null : toggleRecord, icon: Icon(recording ? Icons.stop_circle : Icons.mic_none, color: recording ? kRed : Colors.grey)),
                  IconButton(onPressed: sending ? null : pickFile, icon: const Icon(Icons.attach_file, color: Colors.grey)),
                  Expanded(child: TextField(controller: input, maxLines: 4, minLines: 1, onSubmitted: (_) => sendText(), decoration: const InputDecoration(hintText: 'پیامت را بنویس...', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none))),
                  IconButton(onPressed: sending ? null : sendText, icon: const Icon(Icons.send_rounded, color: kPurple)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  static const Map<String, String> moods = <String, String>{
    'not_good': 'حالم خوب نیست',
    'good': 'حالم خوبه',
    'happy': 'خیلی خوشحالم',
    'sad': 'ناراحتم',
    'hurt': 'دلگیرم',
    'draw_or_not': 'بکشم یا نکشم',
  };
  static const List<String> needsList = <String>['آرامش', 'حواس‌پرتی', 'حرف زدن', 'انرژی', 'تنهایی'];

  final Set<String> selectedNeeds = <String>{};
  String? selectedMood;
  String? drawOrNotChoice;
  Map<String, int> moodCounts = <String, int>{};
  Map<String, int> needCounts = <String, int>{};
  bool reorderMode = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final Map<String, dynamic> data = await CloudService.instance.fetchCheckins();
      if (!mounted) return;
      setState(() {
        moodCounts = Map<String, int>.from(data['moodCounts'] as Map? ?? const <String, int>{});
        needCounts = Map<String, int>.from(data['needCounts'] as Map? ?? const <String, int>{});
      });
    } catch (_) {}
  }

  Future<void> chooseMood(String mood) async {
    if (mood == 'draw_or_not') {
      final String? result = await showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('❤️ بکشم یا نکشم'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(context, 'بکشم'), child: const Text('❤️ بکشم')),
            TextButton(onPressed: () => Navigator.pop(context, 'نکشم'), child: const Text('❤️ نکشم')),
          ],
        ),
      );
      if (result != null) {
        setState(() {
          selectedMood = mood;
          drawOrNotChoice = result;
        });
        await CloudService.instance.saveMood('draw_or_not_$result');
        await load();
      }
      return;
    }
    setState(() => selectedMood = mood);
    await CloudService.instance.saveMood(mood);
    await load();
  }

  Future<void> toggleNeed(String need) async {
    setState(() {
      if (selectedNeeds.contains(need)) {
        selectedNeeds.remove(need);
      } else {
        selectedNeeds.add(need);
      }
    });
    await CloudService.instance.saveNeeds(selectedNeeds.toList());
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      children: <Widget>[
        const PageHeader(title: 'حالم الان', subtitle: 'انتخاب‌ها مشترک هستند؛ نام یا کلید هیچ‌کس نشان داده نمی‌شود.'),
        const SizedBox(height: 14),
        Glass(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('الان چه حسی دارم؟', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: moods.entries.map((MapEntry<String, String> entry) {
                  return FilterChip(
                    selected: selectedMood == entry.key,
                    selectedColor: const Color(0x55FF3B62),
                    onSelected: (_) => chooseMood(entry.key),
                    label: Text('❤️ ${entry.value}'),
                  );
                }).toList(),
              ),
              if (drawOrNotChoice != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text('❤️ بکشم یا نکشم: $drawOrNotChoice'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Glass(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(child: Text('الان چی لازم دارم؟', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
                  Switch(value: reorderMode, onChanged: (bool value) => setState(() => reorderMode = value)),
                ],
              ),
              const Text('حالت «بکش و نکش» ترتیب نیازهای انتخاب‌شده را قابل جابه‌جایی می‌کند.', style: TextStyle(color: Colors.white54, height: 1.45)),
              const SizedBox(height: 9),
              if (!reorderMode)
                ...needsList.map(
                  (String need) => CheckboxListTile(
                    value: selectedNeeds.contains(need),
                    onChanged: (_) => toggleNeed(need),
                    contentPadding: EdgeInsets.zero,
                    activeColor: kBlue,
                    title: Text(need),
                    secondary: Text('${needCounts[need] ?? 0}', style: const TextStyle(color: Colors.white38)),
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: selectedNeeds.length,
                  itemBuilder: (_, int index) {
                    final String item = selectedNeeds.elementAt(index);
                    return Container(
                      key: ValueKey<String>(item),
                      margin: const EdgeInsets.only(bottom: 7),
                      decoration: BoxDecoration(color: const Color(0x221A1724), borderRadius: BorderRadius.circular(14)),
                      child: ListTile(leading: const Icon(Icons.drag_indicator, color: Colors.grey), title: Text(item)),
                    );
                  },
                  onReorderItem: (int oldIndex, int newIndex) async {
                    final List<String> list = selectedNeeds.toList();
                    final String moved = list.removeAt(oldIndex);
                    list.insert(newIndex, moved);
                    setState(() { selectedNeeds..clear()..addAll(list); });
                    await CloudService.instance.saveNeeds(list);
                  },
                ),
              if (reorderMode)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(onPressed: () => setState(() => reorderMode = false), child: const Text('پایان جابه‌جایی')),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Glass(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('نمای مشترک سه نفر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              ...moods.entries.map(
                (MapEntry<String, String> entry) => SharedCountRow(label: entry.value, count: moodCounts[entry.key] ?? 0, icon: Icons.favorite, color: kRed),
              ),
              const Divider(color: Colors.white10),
              ...needsList.map(
                (String item) => SharedCountRow(label: item, count: needCounts[item] ?? 0, icon: Icons.check_circle_outline, color: kBlue),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SharedCountRow extends StatelessWidget {
  const SharedCountRow({super.key, required this.label, required this.count, required this.icon, required this.color});
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
            child: Text('$count نفر', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  final random = math.Random();
  int mode = 0;
  int score = 0;
  int round = 1;
  int target = 0;
  int remaining = 45;
  bool breathing = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    newRound();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void newRound() {
    setState(() {
      mode = random.nextInt(3);
      score = 0;
      round = 1;
      target = random.nextInt(8);
      remaining = 45;
      breathing = false;
    });
  }

  void tapTarget(int index) {
    if (index != target) return;
    setState(() {
      score += 1;
      round += 1;
      target = random.nextInt(8);
    });
  }

  void startBreathing() {
    if (breathing) return;
    setState(() { breathing = true; remaining = 45; });
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (remaining <= 1) {
        timer?.cancel();
        setState(() { breathing = false; remaining = 45; });
      } else {
        setState(() => remaining -= 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final titles = <String>['شکار ستاره', 'تغییر رنگ', 'آرام‌سازی نفس'];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      children: <Widget>[
        const PageHeader(title: 'بازی‌های بی‌پایان', subtitle: 'هر بار یک دور تازه؛ سبک، کوتاه و قابل تکرار.'),
        const SizedBox(height: 14),
        Glass(
          child: Row(
            children: <Widget>[
              Expanded(child: Text(titles[mode], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
              IconButton(onPressed: newRound, icon: const Icon(Icons.shuffle, color: kPurple)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (mode == 0)
          Glass(
            child: GridView.builder(
              itemCount: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemBuilder: (_, int index) {
                return InkWell(
                  onTap: () => tapTarget(index),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(color: const Color(0x22101018), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
                    child: Center(child: Icon(index == target ? Icons.star : Icons.circle_outlined, color: index == target ? const Color(0xFFFFC44D) : Colors.grey, size: 34)),
                  ),
                );
              },
            ),
          )
        else if (mode == 1)
          const ColorGame()
        else
          Glass(
            child: Column(
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 900),
                  width: breathing ? 190 : 120,
                  height: breathing ? 190 : 120,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x229A66FF), border: Border.all(color: const Color(0x669A66FF), width: 2)),
                  child: const Center(child: Text('نفس', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                ),
                const SizedBox(height: 14),
                Text('$remaining ثانیه', style: const TextStyle(color: Colors.white54)),
                const SizedBox(height: 12),
                FilledButton.icon(onPressed: startBreathing, icon: const Icon(Icons.air), label: Text(breathing ? 'در حال آرام‌سازی' : 'شروع')),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Glass(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[Text('دور $round', style: const TextStyle(color: Colors.white60)), Text('امتیاز $score', style: const TextStyle(color: kBlue, fontWeight: FontWeight.w900))])),
      ],
    );
  }
}

class ColorGame extends StatefulWidget {
  const ColorGame({super.key});

  @override
  State<ColorGame> createState() => _ColorGameState();
}

class _ColorGameState extends State<ColorGame> {
  final random = math.Random();
  final colors = <Color>[kRed, kBlue, kPurple, Color(0xFF2CE08C)];
  int answer = 0;
  int score = 0;

  @override
  void initState() {
    super.initState();
    answer = random.nextInt(colors.length);
  }

  void pick(int index) {
    setState(() {
      if (index == answer) score += 1;
      answer = random.nextInt(colors.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final labels = <String>['قرمز', 'آبی', 'بنفش', 'سبز'];
    return Glass(
      child: Column(
        children: <Widget>[
          const Text('فقط رنگی را بزن که با نشانگر وسط مطابقت دارد.'),
          const SizedBox(height: 14),
          Container(width: 110, height: 110, decoration: BoxDecoration(shape: BoxShape.circle, color: colors[answer])),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(labels.length, (int index) => FilledButton.tonal(onPressed: () => pick(index), child: Text(labels[index]))),
          ),
          const SizedBox(height: 8),
          Text('امتیاز این بازی: $score', style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

class MediaPage extends StatefulWidget {
  const MediaPage({super.key});

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  final picker = ImagePicker();
  final recorder = AudioRecorder();
  final player = AudioPlayer();
  List<Map<String, dynamic>> media = <Map<String, dynamic>>[];
  String? playing;
  bool recording = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    recorder.dispose();
    player.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final List<Map<String, dynamic>> data = await CloudService.instance.listMedia();
      if (mounted) setState(() => media = data);
    } catch (_) {}
  }

  Future<void> addPhoto() async {
    final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (file != null) await upload(file.path, 'image');
  }

  Future<void> addMusic() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    final String? path = result?.files.single.path;
    if (path != null) await upload(path, 'audio');
  }

  Future<void> toggleRecord() async {
    if (recording) {
      final String? path = await recorder.stop();
      if (mounted) setState(() => recording = false);
      if (path != null) await upload(path, 'audio');
      return;
    }
    if (!await recorder.hasPermission()) {
      snack('مجوز میکروفون لازم است.');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/shared_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await recorder.start(const RecordConfig(), path: path);
    if (mounted) setState(() => recording = true);
  }

  Future<void> upload(String path, String kind) async {
    try {
      await CloudService.instance.uploadSharedMedia(path: path, kind: kind);
      await load();
    } catch (_) {
      snack('ذخیره فایل انجام نشد.');
    }
  }

  Future<void> showImage(Map<String, dynamic> item) async {
    try {
      final List<int> bytes = await CloudService.instance.downloadMediaBytes(item['id'].toString());
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: InteractiveViewer(child: Padding(padding: const EdgeInsets.all(12), child: Image.memory(Uint8List.fromList(bytes)))),
        ),
      );
    } catch (_) {
      snack('نمایش عکس ممکن نشد.');
    }
  }

  Future<void> play(Map<String, dynamic> item) async {
    try {
      final List<int> bytes = await CloudService.instance.downloadMediaBytes(item['id'].toString());
      await player.play(BytesSource(Uint8List.fromList(bytes)));
      if (mounted) setState(() => playing = item['id'].toString());
    } catch (_) {
      snack('پخش ممکن نشد.');
    }
  }

  void snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      children: <Widget>[
        const PageHeader(title: 'رسانه مشترک', subtitle: 'عکس، صدا و آهنگ روی فضای مشترک ذخیره می‌شوند.'),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(child: QuickButton(title: 'عکس', icon: Icons.image, color: kBlue, onTap: addPhoto)),
            const SizedBox(width: 10),
            Expanded(child: QuickButton(title: 'صدا', icon: recording ? Icons.stop_circle : Icons.mic, color: kRed, onTap: toggleRecord)),
            const SizedBox(width: 10),
            Expanded(child: QuickButton(title: 'آهنگ', icon: Icons.music_note, color: kPurple, onTap: addMusic)),
          ],
        ),
        const SizedBox(height: 14),
        Glass(
          child: media.isEmpty
              ? const Padding(padding: EdgeInsets.all(18), child: Center(child: Text('هنوز رسانه‌ای ثبت نشده است.', style: TextStyle(color: Colors.white54))))
              : Column(
                  children: media.map((Map<String, dynamic> item) {
                    final String kind = item['kind']?.toString() ?? 'file';
                    final bool isImage = kind == 'image';
                    return ListTile(
                      leading: Icon(isImage ? Icons.image : Icons.audiotrack, color: isImage ? kBlue : kPurple),
                      title: Text(item['originalName']?.toString() ?? 'فایل'),
                      subtitle: const Text('مشترک • ذخیره شده روی سرور', style: TextStyle(color: Colors.white38)),
                      trailing: isImage
                          ? IconButton(onPressed: () => showImage(item), icon: const Icon(Icons.visibility_outlined))
                          : IconButton(onPressed: () => play(item), icon: Icon(playing == item['id']?.toString() ? Icons.stop_circle : Icons.play_circle_fill)),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.onLogout});
  final VoidCallback onLogout;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool sound = true;
  bool haptics = true;

  Future<void> changeServer() async {
    final controller = TextEditingController(text: CloudService.instance.baseUrl ?? '');
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('آدرس سرور'),
        content: TextField(controller: controller, textDirection: TextDirection.ltr, keyboardType: TextInputType.url, decoration: const InputDecoration(hintText: 'https://...')),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لغو')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ذخیره')),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      await CloudService.instance.setServerUrl(controller.text.trim());
      if (mounted) setState(() {});
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      children: <Widget>[
        const PageHeader(title: 'تنظیمات', subtitle: 'نسخه مستقل سه‌نفره کلانتر'),
        const SizedBox(height: 14),
        Glass(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.cloud_done_outlined, color: CloudService.instance.online ? const Color(0xFF2CE08C) : Colors.grey),
                title: const Text('وضعیت اتصال'),
                subtitle: Text(CloudService.instance.online ? 'آنلاین و همگام' : 'آفلاین / در حال تلاش', style: const TextStyle(color: Colors.white54)),
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.dns_outlined, color: Colors.grey),
                title: const Text('سرور'),
                subtitle: Text(CloudService.instance.baseUrl ?? 'تنظیم نشده', textDirection: TextDirection.ltr, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38)),
                onTap: changeServer,
              ),
              const Divider(color: Colors.white10),
              SwitchListTile(value: sound, onChanged: (bool value) => setState(() => sound = value), title: const Text('صدا'), secondary: const Icon(Icons.volume_up_outlined, color: Colors.grey)),
              SwitchListTile(value: haptics, onChanged: (bool value) => setState(() => haptics = value), title: const Text('لرزش'), secondary: const Icon(Icons.vibration_outlined, color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Glass(
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('ناشناسی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              SizedBox(height: 8),
              Text('در چت و نمایش‌های مشترک فقط «پیام ناشناس» و شمارش جمعی دیده می‌شود. کلید داخلی برای احراز ورود روی سرور باقی می‌ماند و به دیگران نشان داده نمی‌شود.', style: TextStyle(color: Colors.white54, height: 1.6)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.tonalIcon(onPressed: widget.onLogout, icon: const Icon(Icons.logout), label: const Text('خروج از این دستگاه')),
      ],
    );
  }
}
