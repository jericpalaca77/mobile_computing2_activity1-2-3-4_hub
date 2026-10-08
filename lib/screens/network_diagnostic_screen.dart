import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/network_diagnostic_state.dart';

/// Activity 3: Network Diagnostic Dashboard.
class NetworkDiagnosticScreen extends StatelessWidget {
  static const String routeName = '/network-diagnostic';

  const NetworkDiagnosticScreen({super.key});

  String _phaseText(DiagPhase p) => switch (p) {
        DiagPhase.idle => 'Ready',
        DiagPhase.idlePing => 'Step 1/3: measuring idle ping...',
        DiagPhase.download => 'Step 2/3: download test + ping...',
        DiagPhase.upload => 'Step 3/3: upload test + ping...',
        DiagPhase.done => 'Finished',
      };

  @override
  Widget build(BuildContext context) {
    final s = context.watch<NetworkDiagnosticState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Activity 3: Network Diagnostic')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Health tier
              Card(
                color: s.health.color.withValues(alpha: 0.15),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('Connection health',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(
                        s.health.label,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                color: s.health.color,
                                fontWeight: FontWeight.bold),
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
                      onPressed: s.isRunning ? null : s.runDiagnostic,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Run test'),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto-run every 60 seconds'),
                value: s.autoRun,
                onChanged: s.setAutoRun,
              ),
              Text(_phaseText(s.phase)),
              const SizedBox(height: 6),
              if (s.isRunning) const LinearProgressIndicator(),
              const SizedBox(height: 12),

              _MetricCard(
                icon: Icons.timer,
                title: 'Idle ping',
                value: _ms(s.idlePing?.avg),
                detail: _loss(s.idlePing),
              ),
              _MetricCard(
                icon: Icons.download,
                title: 'Download',
                value: _mbps(s.downMbps),
                detail: 'Ping under load: ${_ms(s.downPing?.avg)} ${_loss(s.downPing)}',
              ),
              _MetricCard(
                icon: Icons.upload,
                title: 'Upload',
                value: _mbps(s.upMbps),
                detail: 'Ping under load: ${_ms(s.upPing?.avg)} ${_loss(s.upPing)}',
              ),
              const SizedBox(height: 12),

              Text('Adaptive media',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              AdaptiveMediaCard(highRes: s.useHighResMedia),
            ],
          ),
        ),
      ),
    );
  }

  static String _ms(double? v) => v == null ? '--' : '${v.round()} ms';
  static String _mbps(double? v) =>
      v == null ? '--' : '${v.toStringAsFixed(2)} Mbps';
  static String _loss(PingStats? p) =>
      p == null ? '' : '(loss ${p.lossPercent.round()}%)';
}

/// StatelessWidget: one metric row.
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String detail;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(detail, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

/// StatelessWidget: swaps high-resolution media for a lightweight placeholder.
class AdaptiveMediaCard extends StatelessWidget {
  final bool highRes;

  const AdaptiveMediaCard({super.key, required this.highRes});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget placeholder(String text) => Container(
          color: scheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.image_not_supported_outlined, size: 40),
              const SizedBox(height: 8),
              Text(text),
            ],
          ),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: highRes
            ? Image.network(
                'https://picsum.photos/id/1015/1280/720',
                fit: BoxFit.cover,
                loadingBuilder: (c, child, p) =>
                    p == null ? child : placeholder('Loading HD image...'),
                errorBuilder: (c, e, s) => placeholder('Image unavailable'),
              )
            : placeholder('Low-data mode: lightweight placeholder'),
      ),
    );
  }
}
