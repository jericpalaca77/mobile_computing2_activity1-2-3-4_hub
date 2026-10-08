import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/network_monitor_state.dart';

/// Activity 2: Active Network Monitor & Handover Handling.
class NetworkMonitorScreen extends StatelessWidget {
  static const String routeName = '/network-monitor';

  const NetworkMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<NetworkMonitorState>();
    final style = _IfaceStyle.of(s.displayInterface);

    return Scaffold(
      appBar: AppBar(title: const Text('Activity 2: Network Monitor')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Real-time interface card
              Card(
                color: style.color.withValues(alpha: 0.15),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(style.icon, size: 48, color: style.color),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Active network',
                                style: Theme.of(context).textTheme.bodySmall),
                            Text(
                              style.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                      color: style.color,
                                      fontWeight: FontWeight.bold),
                            ),
                            Text('Queued requests: ${s.queuedCount}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: s.startRequest,
                      icon: const Icon(Icons.cloud_download),
                      label: const Text('Start request'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: s.toggleSimulatedOffline,
                      icon: Icon(s.simulateOffline
                          ? Icons.wifi
                          : Icons.signal_wifi_off),
                      label: Text(s.simulateOffline ? 'Restore' : 'Simulate drop'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Requests', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Expanded(
                flex: 3,
                child: s.jobs.isEmpty
                    ? const Center(child: Text('No requests yet'))
                    : ListView.builder(
                        itemCount: s.jobs.length,
                        itemBuilder: (_, i) => _JobTile(job: s.jobs[i]),
                      ),
              ),
              const SizedBox(height: 8),
              Text('Event log', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Expanded(
                flex: 2,
                child: ListView.builder(
                  itemCount: s.log.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(s.log[i],
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// StatelessWidget: one row per request.
class _JobTile extends StatelessWidget {
  final RequestJob job;

  const _JobTile({required this.job});

  @override
  Widget build(BuildContext context) {
    final (icon, color, text) = switch (job.status) {
      JobStatus.running => (Icons.sync, Colors.blue, 'Running'),
      JobStatus.queued => (Icons.schedule, Colors.orange, 'Queued - waiting'),
      JobStatus.done => (Icons.check_circle, Colors.green, 'Completed'),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text('${job.name} - $text')),
                Text('${(job.progress * 100).round()}%'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: job.progress, color: color),
            if (job.retries > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Retries: ${job.retries}',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}

class _IfaceStyle {
  final IconData icon;
  final Color color;
  final String label;

  const _IfaceStyle(this.icon, this.color, this.label);

  factory _IfaceStyle.of(NetInterface i) => switch (i) {
        NetInterface.wifi => const _IfaceStyle(Icons.wifi, Colors.green, 'Wi-Fi'),
        NetInterface.cellular =>
          const _IfaceStyle(Icons.signal_cellular_alt, Colors.blue, 'Cellular'),
        NetInterface.other =>
          const _IfaceStyle(Icons.lan, Colors.teal, 'Other network'),
        NetInterface.offline =>
          const _IfaceStyle(Icons.signal_wifi_off, Colors.red, 'Offline'),
      };
}
