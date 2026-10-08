import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum NetInterface { wifi, cellular, other, offline }

enum JobStatus { running, queued, done }

class NetworkDroppedException implements Exception {
  final String message;
  NetworkDroppedException(this.message);

  @override
  String toString() => message;
}

class RequestJob {
  final int id;
  final String name;
  final int totalChunks;
  int doneChunks = 0;
  int retries = 0;
  bool active = false; // true while its loop is executing
  JobStatus status = JobStatus.running;

  RequestJob({required this.id, required this.name, required this.totalChunks});

  double get progress => doneChunks / totalChunks;
}

/// Activity 2: real-time network state + request queue with auto-resume.
class NetworkMonitorState extends ChangeNotifier {
  NetInterface _interface = NetInterface.offline;
  bool _simulateOffline = false;
  bool _disposed = false;
  int _nextId = 1;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  final List<RequestJob> _jobs = [];
  final List<String> _log = [];

  NetworkMonitorState() {
    _init();
  }

  bool get simulateOffline => _simulateOffline;
  List<RequestJob> get jobs => List.unmodifiable(_jobs);
  List<String> get log => List.unmodifiable(_log);

  /// What the dashboard shows.
  NetInterface get displayInterface =>
      _simulateOffline ? NetInterface.offline : _interface;

  bool get isOnline => displayInterface != NetInterface.offline;

  int get queuedCount =>
      _jobs.where((j) => j.status == JobStatus.queued).length;

  Future<void> _init() async {
    final initial = await Connectivity().checkConnectivity();
    _apply(initial);
    // Real-time stream listener
    _sub = Connectivity().onConnectivityChanged.listen(_apply);
  }

  void _apply(List<ConnectivityResult> results) {
    final previous = _interface;

    if (results.contains(ConnectivityResult.wifi)) {
      _interface = NetInterface.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      _interface = NetInterface.cellular;
    } else if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      _interface = NetInterface.offline;
    } else {
      _interface = NetInterface.other;
    }

    if (previous != _interface) {
      _addLog('Network changed: ${previous.name} -> ${_interface.name}');
    }
    _notify();

    if (isOnline) _resumeQueued();
  }

  /// Demo helper: force offline without touching device settings.
  void toggleSimulatedOffline() {
    _simulateOffline = !_simulateOffline;
    _addLog(_simulateOffline
        ? 'Simulated connection drop'
        : 'Simulated connection restored');
    _notify();
    if (isOnline) _resumeQueued();
  }

  /// Starts a long-running "large dataset" request.
  void startRequest() {
    final job = RequestJob(
      id: _nextId++,
      name: 'Dataset #${_nextId - 1}',
      totalChunks: 12,
    );
    _jobs.insert(0, job);
    _addLog('Request #${job.id} started');
    _notify();
    _run(job);
  }

  Future<void> _run(RequestJob job) async {
    if (job.active || job.status == JobStatus.done) return;
    job.active = true;
    job.status = JobStatus.running;
    _notify();

    try {
      while (job.doneChunks < job.totalChunks) {
        if (!isOnline) throw NetworkDroppedException('No connection');
        await Future.delayed(const Duration(milliseconds: 700));
        // Connection may drop during the "transfer" (handover).
        if (!isOnline) {
          throw NetworkDroppedException('Connection dropped mid-transfer');
        }
        job.doneChunks++;
        _notify();
      }
      job.status = JobStatus.done;
      _addLog('Request #${job.id} completed');
    } on NetworkDroppedException catch (e) {
      // Catch the error and queue the request instead of crashing.
      job.status = JobStatus.queued;
      _addLog('Request #${job.id} queued (${e.message}), '
          'kept ${job.doneChunks}/${job.totalChunks} chunks');
    } finally {
      job.active = false;
      _notify();
    }
  }

  /// Graceful recovery: called whenever a usable connection returns.
  void _resumeQueued() {
    for (final job in _jobs) {
      if (job.status == JobStatus.queued && !job.active) {
        job.retries++;
        _addLog('Resuming request #${job.id} (retry ${job.retries})');
        _run(job);
      }
    }
  }

  void _addLog(String message) {
    final t = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    _log.insert(0, '[${two(t.hour)}:${two(t.minute)}:${two(t.second)}] $message');
    if (_log.length > 50) _log.removeLast();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
