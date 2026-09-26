import 'package:flutter/material.dart';

import '../cloud/cloud_service.dart';
import '../models/app_models.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class CloudSharedLoginScreen extends StatefulWidget {
  const CloudSharedLoginScreen({
    super.key,
    required this.storage,
    required this.theme,
    required this.onThemeChanged,
  });

  final StorageService storage;
  final AppThemeChoice theme;
  final ValueChanged<AppThemeChoice> onThemeChanged;

  @override
  State<CloudSharedLoginScreen> createState() => _CloudSharedLoginScreenState();
}

class _RoleInfo {
  const _RoleInfo({required this.role, required this.title, required this.subtitle, required this.icon, required this.theme});
  final String role;
  final String title;
  final String subtitle;
  final IconData icon;
  final AppThemeChoice theme;
}

const _roles = <_RoleInfo>[
  _RoleInfo(role: 'person1', title: 'کلید A', subtitle: 'تم بنفش', icon: Icons.person_rounded, theme: AppThemeChoice.purple),
  _RoleInfo(role: 'person2', title: 'کلید B', subtitle: 'تم آبی', icon: Icons.favorite_rounded, theme: AppThemeChoice.blue),
  _RoleInfo(role: 'person3', title: 'کلید C', subtitle: 'تم قرمز', icon: Icons.auto_awesome_rounded, theme: AppThemeChoice.red),
];

class _CloudSharedLoginScreenState extends State<CloudSharedLoginScreen> {
  final CloudService cloud = CloudService.instance;
  late final TextEditingController server;
  final password = TextEditingController();
  String role = 'person1';
  bool busy = false;
  String? status;

  @override
  void initState() {
    super.initState();
    server = TextEditingController(
      text: cloud.baseUrl?.isNotEmpty == true
          ? cloud.baseUrl!
          : const String.fromEnvironment('THREE_PERSON_API_URL', defaultValue: ''),
    );
    if (_roles.any((r) => r.role == cloud.role)) role = cloud.role!;
  }

  @override
  void dispose() {
    server.dispose();
    password.dispose();
    super.dispose();
  }

  String _errorText(Object error) {
    final raw = error.toString();
    if (raw.contains('invalid_login')) return 'رمز ورود این حساب اشتباه است.';
    if (raw.contains('server_credentials_missing')) return 'حساب‌ها روی Railway کامل تنظیم نشده‌اند.';
    return 'اتصال به Railway برقرار نشد. آدرس سرویس و اینترنت را بررسی کن.';
  }

  Future<bool> _prepareServer() async {
    if (server.text.trim().isEmpty) {
      setState(() => status = 'آدرس Railway را وارد کن.');
      return false;
    }
    await cloud.setServerUrl(server.text.trim());
    return true;
  }

  Future<void> login() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (password.text.trim().length < 4) {
      setState(() => status = 'رمز ورود را وارد کن.');
      return;
    }
    setState(() {
      busy = true;
      status = null;
    });
    try {
      if (!await _prepareServer()) return;
      await cloud.login(role: role, password: password.text.trim());
      final selected = themeForCloudRole(role);
      await widget.storage.saveTheme(selected);
      widget.onThemeChanged(selected);
      await cloud.pullAndApply();
      await cloud.syncNow();
      if (mounted) setState(() => status = 'اتصال دفتر مشترک فعال شد ❤️');
    } catch (e) {
      if (mounted) setState(() => status = _errorText(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> disconnect() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('قطع ارتباط'),
        content: const Text('ارتباط این دستگاه با دفتر مشترک قطع شود؟ اطلاعات محلی حذف نمی‌شود.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لغو')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('قطع ارتباط')),
        ],
      ),
    );
    if (ok != true) return;
    await cloud.disconnect();
    if (mounted) setState(() => status = 'ارتباط قطع شد. اطلاعات محلی باقی ماند.');
  }

  @override
  Widget build(BuildContext context) {
    final selected = _roles.firstWhere((r) => r.role == role);
    final c = colorsFor(selected.theme);
    return Scaffold(
      backgroundColor: AppPalette.page,
      appBar: AppBar(
         title: const Text('دفتر مشترک'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: const Color(0xFF090F19),
              border: Border.all(color: c.primary.withValues(alpha: .16)),
            ),
            child: Column(
              children: [
                Icon(Icons.groups_3_rounded, color: c.primary, size: 54),
                const SizedBox(height: 12),
                 const Text('یک دفتر مشترک', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text(
                   'یادداشت‌ها، عکس‌ها، صداها و پیام‌های این دفتر بین دستگاه‌های متصل همگام می‌شوند.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: server,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
               labelText: 'آدرس Railway',
               hintText: 'https://YOUR-RAILWAY.up.railway.app',
              prefixIcon: Icon(Icons.dns_rounded),
            ),
          ),
          const SizedBox(height: 14),
          Column(
            children: _roles.map((r) {
              final chosen = r.role == role;
              final rc = colorsFor(r.theme);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => setState(() {
                    role = r.role;
                    password.clear();
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: rc.primary.withValues(alpha: chosen ? .13 : .05),
                      border: Border.all(color: chosen ? rc.primary : Colors.white.withValues(alpha: .07), width: chosen ? 1.6 : 1),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(backgroundColor: rc.primary.withValues(alpha: .14), child: Icon(r.icon, color: rc.primary)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(r.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            const SizedBox(height: 2),
                            Text(r.subtitle, style: TextStyle(color: rc.accent, fontSize: 12)),
                          ]),
                        ),
                        Icon(chosen ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded, color: rc.primary),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: password,
            obscureText: true,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: 'رمز ${selected.title}',
              hintText: 'رمز این حساب در Railway',
              prefixIcon: const Icon(Icons.password_rounded),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: busy ? null : login,
            icon: const Icon(Icons.login_rounded),
             label: const Text('ورود و اتصال به دفتر'),
          ),
          const SizedBox(height: 10),
          Text(
             'بعد از اولین ورود، حساب و تم همین دستگاه ذخیره می‌شود و دفتر هنگام اجرای برنامه همگام خواهد شد.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: .58), height: 1.55),
          ),
          if (cloud.configured) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(onPressed: busy ? null : disconnect, icon: const Icon(Icons.link_off_rounded), label: const Text('قطع ارتباط این دستگاه')),
            const SizedBox(height: 8),
            Text(cloud.online ? '● اتصال زنده برقرار است' : '● اتصال ذخیره شده است؛ هنوز آنلاین نیست', textAlign: TextAlign.center, style: TextStyle(color: cloud.online ? c.primary : Colors.white54, fontWeight: FontWeight.w700)),
          ],
          if (busy) ...[
            const SizedBox(height: 18),
            const Center(child: CircularProgressIndicator()),
          ],
          if (status != null) ...[
            const SizedBox(height: 18),
            Text(status!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, height: 1.5)),
          ],
        ],
      ),
    );
  }
}
