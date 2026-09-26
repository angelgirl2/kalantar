// ignore_for_file: unused_element

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
  });

  final StorageService storage;
  final AppThemeChoice theme;

  @override
  State<CloudSharedLoginScreen> createState() => _CloudSharedLoginScreenState();
}

class _CloudSharedLoginScreenState extends State<CloudSharedLoginScreen> {
  final CloudService cloud = CloudService.instance;
  bool busy = false;
  String? status;

  String _labelForRole(String role) {
    switch (role) {
      case 'sister':
        return 'آبجی بزرگه';
      case 'me':
        return 'داداش کوچیکه';
      default:
        return 'ناشناس';
    }
  }

  String _errorText(Object error) {
    final raw = error.toString();
    if (raw.contains('role_taken')) {
      return 'این گزینه روی یک دستگاه دیگر فعال است.';
    }
    if (raw.contains('room_full')) {
      return 'امکان اتصال جدید وجود ندارد.';
    }
    if (raw.contains('server_not_ready') ||
        raw.contains('database_not_ready') ||
        raw.contains('database_unavailable') ||
        raw.contains('login_failed')) {
      return 'سرور دفتر مشترک آماده نیست.';
    }
    if (raw.contains('DioException') ||
        raw.contains('SocketException') ||
        raw.contains('connection refused') ||
        raw.contains('failed host lookup')) {
      return 'ارتباط با سرور برقرار نشد.';
    }
    return 'اتصال انجام نشد؛ دوباره تلاش کن.';
  }

  Future<void> connectAs(String role) async {
    if (busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      busy = true;
      status = null;
    });
    try {
      await cloud.loginAnonymous(role: role);
      try {
        await cloud.pullAndApply(widget.storage);
        await cloud.syncNow(widget.storage);
      } catch (syncError) {
        debugPrint('SYNC ERROR: $syncError');
      }
      if (mounted) {
        setState(() {
          status = 'اتصال فعال شد ❤️';
        });
      }
    } catch (e) {
      debugPrint('CONNECT ERROR: $e');
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
        content: const Text(
          'ارتباط این دستگاه با دفتر مشترک قطع شود؟ اطلاعات محلی حذف نمی‌شود.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('قطع ارتباط'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await cloud.disconnect();
    if (mounted) setState(() => status = 'ارتباط قطع شد.');
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsFor(widget.theme);
    return Scaffold(
      backgroundColor: AppPalette.page,
      appBar: AppBar(
        title: const Text('دفتر مشترک'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/kalantar_background.jpg',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: Color(0xFF05070C)),
          ),
          const ColoredBox(color: Color(0xB8000000)),
          ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: const Color(0xD9090F19),
                  border: Border.all(color: c.primary.withValues(alpha: .12)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.people_alt_rounded, color: c.primary, size: 54),
                    const SizedBox(height: 12),
                    const Text(
                      'دفتر مشترک',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'یک اتصال خصوصی و مشترک؛ هویت افراد در بخش‌های مشترک نمایش داده نمی‌شود.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (cloud.configured) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: c.primary.withValues(alpha: .08),
                    border: Border.all(color: c.primary.withValues(alpha: .16)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_user_rounded, color: c.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'وارد شده‌ای: ${cloud.myDisplayName}\nاتصال در پس‌زمینه نگه داشته می‌شود.',
                          style: const TextStyle(
                            height: 1.55,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const Text(
                'ورود',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              _roleButton('آبجی بزرگه', 'sister', c.primary),
              const SizedBox(height: 9),
              _roleButton('داداش کوچیکه', 'me', c.secondary),
              const SizedBox(height: 9),
              _roleButton('ناشناس', 'guest', c.accent),
              const SizedBox(height: 14),
              if (cloud.configured)
                OutlinedButton.icon(
                  onPressed: busy ? null : disconnect,
                  icon: const Icon(Icons.link_off_rounded),
                  label: const Text('قطع ارتباط این دستگاه'),
                ),
              const SizedBox(height: 10),
              Text(
                cloud.online ? '● اتصال زنده برقرار است' : '● در حال اتصال...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cloud.online ? c.primary : Colors.white54,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (busy) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
              if (status != null) ...[
                const SizedBox(height: 16),
                Text(
                  status!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _roleButton(String label, String role, Color color) {
    return FilledButton.icon(
      onPressed: busy ? null : () => connectAs(role),
      style: FilledButton.styleFrom(
        backgroundColor: color.withValues(alpha: .20),
        foregroundColor: Colors.white,
        side: BorderSide(color: color.withValues(alpha: .45)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      icon: Icon(Icons.favorite_rounded, color: color),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
