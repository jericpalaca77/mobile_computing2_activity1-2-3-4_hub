import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

class Peer {
  final String id;
  final String name;
  const Peer(this.id, this.name);
}

class PendingConnection {
  final String endpointId;
  final String endpointName;
  final String token; // shown on both devices for the handshake check
  final bool incoming;
  const PendingConnection(
      this.endpointId, this.endpointName, this.token, this.incoming);
}

class ChatMessage {
  final String text;
  final String sender;
  final bool isMe;
  final bool isSystem;
  final DateTime time;

  ChatMessage({
    required this.text,
    required this.sender,
    this.isMe = false,
    this.isSystem = false,
  }) : time = DateTime.now();
}

/// Activity 4: serverless local chat (Nearby Connections, P2P_CLUSTER mesh).
/// The chat UI is a pure function of this state: UI = f(state).
class LocalMeshChatState extends ChangeNotifier {
  static const _serviceId = 'com.example.lab_activity_hub.meshchat';
  static const _strategy = Strategy.P2P_CLUSTER;

  String nickname = 'Student';
  bool advertising = false;
  bool discovering = false;
  String? error;

  final Map<String, Peer> _discovered = {};
  final Map<String, Peer> _connected = {};
  final Map<String, PendingConnection> _pending = {};
  final List<ChatMessage> _messages = [];
  final Set<String> _seenIds = {};

  List<Peer> get discovered => _discovered.values.toList();
  List<Peer> get connected => _connected.values.toList();
  List<PendingConnection> get pending => _pending.values.toList();
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool get active => advertising || discovering;

  /// Nearby Connections only works on Android devices (not web/desktop).
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  // ---------- Discovery ----------
  Future<void> start(String name) async {
    nickname = name.trim().isEmpty ? 'Student' : name.trim();
    error = null;

    if (!await _ensurePermissions()) {
      error = 'Permissions are required to find nearby devices.';
      notifyListeners();
      return;
    }

    try {
      // Broadcast this device's presence
      advertising = await Nearby().startAdvertising(
        nickname,
        _strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: _serviceId,
      );

      // Scan for neighbors
      discovering = await Nearby().startDiscovery(
        nickname,
        _strategy,
        onEndpointFound: (id, name, serviceId) {
          _discovered[id] = Peer(id, name);
          notifyListeners();
        },
        onEndpointLost: (id) {
          _discovered.remove(id);
          notifyListeners();
        },
        serviceId: _serviceId,
      );
    } catch (e) {
      error = 'Could not start: $e';
    }
    notifyListeners();
  }

  Future<void> stop() async {
    try {
      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();
      await Nearby().stopAllEndpoints();
    } catch (_) {}
    advertising = false;
    discovering = false;
    _discovered.clear();
    _connected.clear();
    _pending.clear();
    notifyListeners();
  }

  Future<bool> _ensurePermissions() async {
    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ].request();
    return Permission.location.isGranted;
  }

  // ---------- Connection & handshake ----------
  Future<void> connectTo(Peer peer) async {
    try {
      await Nearby().requestConnection(
        nickname,
        peer.id,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (e) {
      error = 'Connection request failed: $e';
      notifyListeners();
    }
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    _pending[id] = PendingConnection(
        id, info.endpointName, info.authenticationToken, info.isIncomingConnection);
    notifyListeners();
  }

  Future<void> accept(String id) async {
    await Nearby().acceptConnection(
      id,
      onPayLoadRecieved: _onPayloadReceived,
      onPayloadTransferUpdate: (endpointId, update) {},
    );
  }

  Future<void> reject(String id) async {
    await Nearby().rejectConnection(id);
    _pending.remove(id);
    notifyListeners();
  }

  void _onConnectionResult(String id, Status status) {
    final name = _pending[id]?.endpointName ?? _discovered[id]?.name ?? id;
    _pending.remove(id);

    if (status == Status.CONNECTED) {
      _connected[id] = Peer(id, name);
      _discovered.remove(id);
      _addSystem('Connected to $name');
    } else {
      _addSystem('Connection with $name failed');
    }
    notifyListeners();
  }

  void _onDisconnected(String id) {
    final name = _connected.remove(id)?.name ?? 'A device';
    _addSystem('$name disconnected');
    notifyListeners();
  }

  // ---------- Payload routing ----------
  void sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _connected.isEmpty) return;

    final msgId = '$nickname-${DateTime.now().microsecondsSinceEpoch}';
    _seenIds.add(msgId);
    _messages.add(ChatMessage(text: trimmed, sender: nickname, isMe: true));

    final data = {'id': msgId, 'from': nickname, 'text': trimmed};
    _broadcast(data, exceptEndpoint: null);
    notifyListeners();
  }

  void _onPayloadReceived(String endpointId, Payload payload) {
    if (payload.type != PayloadType.BYTES || payload.bytes == null) return;

    try {
      final data =
          jsonDecode(utf8.decode(payload.bytes!)) as Map<String, dynamic>;
      final id = data['id'] as String;
      if (!_seenIds.add(id)) return; // already seen -> avoid loops

      _messages.add(ChatMessage(
        text: data['text'] as String,
        sender: data['from'] as String,
      ));

      // Mesh routing: relay to every other connected peer.
      _broadcast(data, exceptEndpoint: endpointId);
      notifyListeners();
    } catch (_) {
      // ignore malformed payloads
    }
  }

  void _broadcast(Map<String, dynamic> data, {String? exceptEndpoint}) {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(data)));
    for (final id in _connected.keys) {
      if (id == exceptEndpoint) continue;
      Nearby().sendBytesPayload(id, bytes);
    }
  }

  void _addSystem(String text) {
    _messages.add(ChatMessage(text: text, sender: 'system', isSystem: true));
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
