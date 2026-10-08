import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum NetworkHealth { unknown, excellent, fair, poor, degraded }

enum DiagPhase { idle, idlePing, download, upload, done }

extension NetworkHealthStyle on NetworkHealth {
  String get label => switch (this) {
        NetworkHealth.unknown => 'Not tested',
        NetworkHealth.excellent => 'Excellent',
        NetworkHealth.fair => 'Fair',
        NetworkHealth.poor => 'Poor',
        NetworkHealth.degraded => 'Degraded',
      };

  Color get color => switch (this) {
        NetworkHealth.unknown => Colors.grey,
        NetworkHealth.excellent => Colors.green,
        NetworkHealth.fair => Colors.amber,
        NetworkHealth.poor => Colors.orange,
        NetworkHealth.degraded => Colors.red,
      };
}

class PingStats {
  int sent = 0;
  int lost = 0;
  final List<int> samples = [];

  void add(int? ms) {
    sent++;
    if (ms == null) {
      lost++;
    } else {
      samples.add(ms);
    }
  }

  double? get avg =>
      samples.isEmpty ? null : samples.reduce((a, b) => a + b) / samples.length;

  double get lossPercent => sent == 0 ? 0 : lost * 100 / sent;
}

/// Activity 3: diagnostic tool (idle ping -> download+ping -> upload+ping).
/// The resulting [health] is broadcast app-wide through Provider.
class NetworkDiagnosticState extends ChangeNotifier {
  // CORS-enabled endpoints (work on Flutter web, Android, etc.)
  static const _pingUrl = 'https://speed.cloudflare.com/__down?bytes=0';
  static const _downUrl = 'https://speed.cloudflare.com/__down?bytes=25000000';
  static const _upUrl = 'https://speed.cloudflare.com/__up';

  static const _testDuration = Duration(seconds: 6);
  static const _autoInterval = Duration(seconds: 60);

  DiagPhase _phase = DiagPhase.idle;
  NetworkHealth _health = NetworkHealth.unknown;
  PingStats? _idlePing;
  PingStats? _downPing;
  PingStats? _upPing;
  double? _downMbps;
  double? _upMbps;
  DateTime? _lastRun;
  bool _autoRun = false;
  Timer? _timer;
  bool _disposed = false;

  DiagPhase get phase => _phase;
  NetworkHealth get health => _health;
  PingStats? get idlePing => _idlePing;
  PingStats? get downPing => _downPing;
  PingStats? get upPing => _upPing;
  double? get downMbps => _downMbps;
  double? get upMbps => _upMbps;
  DateTime? get lastRun => _lastRun;
  bool get autoRun => _autoRun;
  bool get isRunning =>
      _phase != DiagPhase.idle && _phase != DiagPhase.done;

  /// Used by the UI to switch between multimedia and lightweight placeholders.
  bool get useHighResMedia =>
      _health == NetworkHealth.excellent || _health == NetworkHealth.fair;

  void setAutoRun(bool value) {
    _autoRun = value;
    _timer?.cancel();
    if (value) {
      runDiagnostic();
      _timer = Timer.periodic(_autoInterval, (_) => runDiagnostic());
    }
    _notify();
  }

  Future<void> runDiagnostic() async {
    if (isRunning) return;

    _idlePing = PingStats();
    _downPing = PingStats();
    _upPing = PingStats();
    _downMbps = null;
    _upMbps = null;

    // Step 1: baseline idle ping
    _phase = DiagPhase.idlePing;
    _notify();
    for (var i = 0; i < 5; i++) {
      _idlePing!.add(await _pingOnce());
      _notify();
    }

    // Step 2: download bandwidth + concurrent ping
    _phase = DiagPhase.download;
    _notify();
    _downMbps = await _measureDownload(_downPing!);
    _notify();

    // Step 3: upload bandwidth + concurrent ping
    _phase = DiagPhase.upload;
    _notify();
    _upMbps = await _measureUpload(_upPing!);

    _health = _classify();
    _lastRun = DateTime.now();
    _phase = DiagPhase.done;
    _notify();
  }

  Future<int?> _pingOnce() async {
    final sw = Stopwatch()..start();
    try {
      final uri = Uri.parse(
          '$_pingUrl&t=${DateTime.now().microsecondsSinceEpoch}');
      await http.get(uri).timeout(const Duration(seconds: 3));
      return sw.elapsedMilliseconds;
    } catch (_) {
      return null; // timeout / failure counts as packet loss
    }
  }

  Future<void> _pingLoop(PingStats stats, bool Function() keepGoing) async {
    while (keepGoing()) {
      stats.add(await _pingOnce());
      _notify();
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<double> _measureDownload(PingStats pings) async {
    final client = http.Client();
    var running = true;
    final pinger = _pingLoop(pings, () => running);
    final sw = Stopwatch()..start();
    var bytes = 0;

    try {
      final res = await client
          .send(http.Request('GET', Uri.parse(_downUrl)))
          .timeout(const Duration(seconds: 8));
      await for (final chunk in res.stream) {
        bytes += chunk.length;
        if (sw.elapsed > _testDuration) break;
      }
    } catch (_) {
      // keep whatever was measured
    } finally {
      sw.stop();
      running = false;
      client.close();
    }
    await pinger;

    final secs = sw.elapsedMilliseconds / 1000;
    return secs <= 0 ? 0 : bytes * 8 / secs / 1e6;
  }

  Future<double> _measureUpload(PingStats pings) async {
    final client = http.Client();
    var running = true;
    final pinger = _pingLoop(pings, () => running);
    final payload = Uint8List(1024 * 1024); // 1 MB per request
    final sw = Stopwatch()..start();
    var bytes = 0;

    try {
      while (sw.elapsed < _testDuration) {
        await client
            .post(Uri.parse(_upUrl), body: payload)
            .timeout(const Duration(seconds: 8));
        bytes += payload.length;
      }
    } catch (_) {
      // keep whatever was measured
    } finally {
      sw.stop();
      running = false;
      client.close();
    }
    await pinger;

    final secs = sw.elapsedMilliseconds / 1000;
    return secs <= 0 ? 0 : bytes * 8 / secs / 1e6;
  }

  /// Threshold logic. Tiers are based on download bandwidth:
  /// Excellent > 10 Mbps, Fair 2-10 Mbps, Poor < 2 Mbps,
  /// Degraded = heavy packet loss (>= 30%) or extreme latency (> 800 ms).
  NetworkHealth _classify() {
    final all = [_idlePing, _downPing, _upPing].whereType<PingStats>();
    final sent = all.fold<int>(0, (a, p) => a + p.sent);
    final lost = all.fold<int>(0, (a, p) => a + p.lost);
    final lossPct = sent == 0 ? 100.0 : lost * 100 / sent;

    final avgs = all.map((p) => p.avg).whereType<double>();
    final worstLatency = avgs.isEmpty ? double.infinity : avgs.reduce(max);

    if (lossPct >= 30 || worstLatency > 800) return NetworkHealth.degraded;

    final down = _downMbps ?? 0;
    if (down > 10) return NetworkHealth.excellent;
    if (down >= 2) return NetworkHealth.fair;
    return NetworkHealth.poor;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
