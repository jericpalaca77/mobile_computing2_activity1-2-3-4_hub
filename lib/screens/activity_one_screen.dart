import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

/// Activity 1: Flutter Portfolio & State Management.
/// StatefulWidget = local state (counter, slider).
/// Global state (profile name) is read from AppState via Provider.
class ActivityOneScreen extends StatefulWidget {
  static const String routeName = '/activity-one';

  const ActivityOneScreen({super.key});

  @override
  State<ActivityOneScreen> createState() => _ActivityOneScreenState();
}

class _ActivityOneScreenState extends State<ActivityOneScreen> {
  int _counter = 0;
  double _leftFlex = 1;

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AppState>().userName;
    final scheme = Theme.of(context).colorScheme;
    final left = _leftFlex.round();
    final right = 4 - left;

    return Scaffold(
      appBar: AppBar(title: const Text('Activity 1: State & Layout')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, $name!',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              const Text('Local state (setState) lives only in this screen.'),
              const SizedBox(height: 12),

              // Counter (local state)
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    '$_counter',
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => setState(() => _counter--),
                      icon: const Icon(Icons.remove),
                      label: const Text('Minus'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _counter = 0),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => setState(() => _counter++),
                      icon: const Icon(Icons.add),
                      label: const Text('Plus'),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Responsive layout (Expanded + flex)
              Text('Left : Right = $left : $right',
                  style: Theme.of(context).textTheme.titleMedium),
              Slider(
                value: _leftFlex,
                min: 1,
                max: 3,
                divisions: 2,
                label: '$left',
                onChanged: (v) => setState(() => _leftFlex = v),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(
                      flex: left,
                      child: _Panel(
                          color: scheme.primaryContainer,
                          label: 'Expanded\nflex $left'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: right,
                      child: _Panel(
                          color: scheme.secondaryContainer,
                          label: 'Expanded\nflex $right'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// StatelessWidget: static colored panel.
class _Panel extends StatelessWidget {
  final Color color;
  final String label;

  const _Panel({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}
