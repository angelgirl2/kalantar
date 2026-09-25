import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'chat_models.dart';

class CloudService {
  CloudService._();
  static final CloudService instance = CloudService._();

  static const _urlKey = 'kalantar_cloud_url_v1';
  static const _tokenKey = 'kalantar_cloud_token_v1';
  static const _roleKey = 'kalantar_cloud_role_v1';
  static const _deviceKey = 'kalantar_cloud_device_v1';

  final _secure = const FlutterSecureStorage();
  final contentChanges = StreamController<void>.broadcast();
  final incomingMessages = StreamController<ChatMessage>.broadcast();
  final messageStatusChanges = StreamController<Map<String, dynamic>>.broadcast();
  final connectionChanges = StreamController<bool>.broadcast();
  final typingController = StreamController<bool>.broadcast();
  final presenceController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<bool> get typingChanges => typingController.stream;
  Stream<Map<String, dynamic>> get presenceChanges => presenceController.stream;

  /// Returns the current JWT without the `Bearer ` prefix.
  /// ChatScreen adds the HTTP Authorization prefix itself.
  Future<String?> authHeaderToken() => _token();

  /// Builds an absolute authenticated-media URL from a server-relative path.
  String mediaUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = (_baseUrl ?? '').replaceFirst(RegExp(r'/+$'), '');
    final relative = path.startsWith('/') ? path : '/$path';
    return '$base$relative';
  }

  /// Refreshes the cloud snapshot and announces that shared content may have changed.
  Future<void> syncNow() async {
    await init();
    if (!configured) return;
    await _request('GET', '/api/sync/snapshot');
    contentChanges.add(null);
  }

  /// Pulls the latest cloud snapshot. The app's content listeners reload it from the API.
  Future<void> pullAndApply() => syncNow();


  IO.Socket? _socket;
  Dio? _dio;
  String? _baseUrl;
  String? _role;
  bool _online = false;
  bool _initialized = false;

  bool get online => _online;
  bool get configured => (_baseUrl ?? '').trim().isNotEmpty && _role != null;
  String? get baseUrl => _baseUrl;
  String? get role => _role;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_urlKey) ?? (const String.fromEnvironment('KALANTAR_API_URL', defaultValue: '').trim().isEmpty ? null : const String.fromEnvironment('KALANTAR_API_URL', defaultValue: '').trim());
    _role = prefs.getString(_roleKey);
    _dio = _makeDio(_baseUrl ?? '');
    _initialized = true;
    if (configured) await _connectSocket();
  }

  Dio _makeDio(String url) => Dio(BaseOptions(baseUrl: url, connectTimeout: const Duration(seconds: 12), receiveTimeout: const Duration(seconds: 40), sendTimeout: const Duration(seconds: 90), validateStatus: (s) => s != null && s < 500));

  Future<void> setServerUrl(String url) async {
    await init();
    var v = url.trim(); while (v.endsWith('/')) v = v.substring(0, v.length - 1);
    _baseUrl = v;
    _dio = _makeDio(v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, v);
  }

  Future<String?> _token() => _secure.read(key: _tokenKey);
  Future<String?> get deviceId => _secure.read(key: _deviceKey);


  Future<void> login({required String role, required String password}) async {
    await init();
    final r = await _dio!.post('/api/auth/login', data: {'role': role, 'password': password});
    _ok(r);
    final map = Map<String, dynamic>.from(r.data as Map);
    await _secure.write(key: _tokenKey, value: map['token']?.toString());
    await _secure.write(key: _deviceKey, value: map['deviceId']?.toString());
    final prefs = await SharedPreferences.getInstance();
    _role = role;
    await prefs.setString(_roleKey, role);
    await _connectSocket();
  }

  Future<void> disconnect() async {
    _socket?.dispose(); _socket = null; _online = false; connectionChanges.add(false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    await _secure.delete(key: _tokenKey); await _secure.delete(key: _deviceKey);
    _role = null;
  }

  Future<void> _connectSocket() async {
    final t = await _token();
    if (!configured || t == null || t.isEmpty) return;
    _socket?.dispose();
    _socket = IO.io(_baseUrl!, IO.OptionBuilder().setTransports(['websocket']).setAuth({'token': t}).enableAutoConnect().enableForceNew().build());
    _socket!
      ..onConnect((_) { _online = true; connectionChanges.add(true); })
      ..onDisconnect((_) { _online = false; connectionChanges.add(false); })
      ..onConnectError((_) { _online = false; connectionChanges.add(false); })
      ..on('chat:message', (d) { if (d is Map) incomingMessages.add(ChatMessage.fromJson(Map<String, dynamic>.from(d))); })
      ..on('chat:read', (d) { if (d is Map) messageStatusChanges.add({'type':'read', ...Map<String,dynamic>.from(d)}); })
      ..on('chat:reaction', (d) {
        if (d is Map) messageStatusChanges.add({'type': 'reaction', ...Map<String, dynamic>.from(d)});
      })
      ..on('chat:delivered', (d) {
        if (d is Map) messageStatusChanges.add({'type': 'delivered', ...Map<String, dynamic>.from(d)});
      })
      ..on('typing', (d) {
        if (d is Map) {
          typingController.add(d['typing'] == true);
        } else {
          typingController.add(d == true);
        }
      })
      ..on('presence', (d) {
        if (d is Map) presenceController.add(Map<String, dynamic>.from(d));
      })
      ..on('content:changed', (_) => contentChanges.add(null))
      ..on('checkins:changed', (_) => contentChanges.add(null));
  }

  Future<Map<String, dynamic>> _request(String method, String path, {dynamic data, Map<String,dynamic>? query, ResponseType? responseType}) async {
    final t = await _token(); if (t == null || t.isEmpty) throw StateError('not_connected');
    final r = await _dio!.request(path, data: data, queryParameters: query, options: Options(method: method, headers: {'Authorization':'Bearer $t'}, responseType: responseType));
    _ok(r); return Map<String,dynamic>.from(r.data as Map);
  }

  Future<List<ChatMessage>> fetchMessages({int limit = 80}) async { final d = await _request('GET','/api/chat/messages', query: {'limit': limit}); final list = (d['messages'] as List? ?? const []); return list.map((e)=>ChatMessage.fromJson(Map<String,dynamic>.from(e))).toList(); }
  Future<ChatMessage> sendText(String body) async { return _sendMessage(type:'text', body:body); }
  Future<ChatMessage> _sendMessage({required String type, required String body, String? attachmentId, String? attachmentName}) async { final d = await _request('POST','/api/chat/messages', data: {'type':type,'body':body,'attachmentId':attachmentId,'attachmentName':attachmentName}); return ChatMessage.fromJson(Map<String,dynamic>.from(d['message'] as Map)); }

  Future<ChatMessage> sendAttachment({required String path, required String kind}) async {
    final t = await _token(); if (t == null) throw StateError('not_connected');
    final name = path.split(Platform.pathSeparator).last;
    final form = FormData.fromMap({'kind':kind,'file':await MultipartFile.fromFile(path, filename:name)});
    final up = await _dio!.post('/api/media', data: form, options: Options(headers: {'Authorization':'Bearer $t'})); _ok(up);
    return _sendMessage(type: kind, body:'', attachmentId:up.data['id']?.toString(), attachmentName:up.data['originalName']?.toString() ?? name);
  }

  Future<void> uploadSharedMedia({required String path, required String kind}) async {
    final t = await _token(); if (t == null) throw StateError('not_connected');
    final name = path.split(Platform.pathSeparator).last;
    final form = FormData.fromMap({'kind':kind,'file':await MultipartFile.fromFile(path, filename:name)});
    final r = await _dio!.post('/api/media', data: form, options: Options(headers: {'Authorization':'Bearer $t'})); _ok(r);
  }

  Future<List<int>> downloadMediaBytes(String id) async {
    final t = await _token(); if (t == null) throw StateError('not_connected');
    final r = await _dio!.get<List<int>>('/api/media/$id', options: Options(responseType: ResponseType.bytes, headers: {'Authorization':'Bearer $t'})); _ok(r); return r.data ?? const <int>[];
  }

  Future<List<Map<String,dynamic>>> listMedia() async { final d = await _request('GET','/api/media'); return (d['media'] as List? ?? const []).map((e)=>Map<String,dynamic>.from(e as Map)).toList(); }

  Future<Map<String,dynamic>> fetchCheckins() async => _request('GET','/api/checkins');
  Future<void> saveMood(String mood) async { await _request('POST','/api/checkins/mood', data: {'mood':mood}); }
  Future<void> saveNeeds(List<String> needs) async { await _request('POST','/api/checkins/needs', data: {'needs':needs}); }

  Future<List<Map<String,dynamic>>> fetchSharedNotes() async { final d = await _request('GET','/api/sync/snapshot'); final p = Map<String,dynamic>.from(d['payload'] as Map? ?? const {}); return (p['notes'] as List? ?? const []).map((e)=>Map<String,dynamic>.from(e as Map)).toList(); }
  Future<void> saveSharedNotes(List<Map<String, dynamic>> notes) async {
    await _request(
      'PUT',
      '/api/sync/snapshot',
      data: {
        'payload': {
          'version': 4,
          'notes': notes,
          'deletedIds': [],
        },
      },
    );
  }

  Future<void> markRead(String id) async { await _request('PATCH','/api/chat/messages/$id/read'); }
  Future<void> react(String id,String reaction) async { await _request('PATCH','/api/chat/messages/$id/reaction', data:{'reaction':reaction}); }
  void setTyping(bool value) => _socket?.emit('typing', value);
  void _ok(Response<dynamic> r) { if (r.statusCode == null || r.statusCode! >= 300) { final d=r.data; final e=d is Map ? d['error']?.toString() : null; throw StateError(e ?? 'request_failed'); } }
}
