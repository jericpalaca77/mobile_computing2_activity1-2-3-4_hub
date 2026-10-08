import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../providers/local_mesh_chat_state.dart';

/// Activity 4: Local Mesh Chat. UI = f(LocalMeshChatState).
class LocalMeshChatScreen extends StatefulWidget {
  static const String routeName = '/local-mesh-chat';

  const LocalMeshChatScreen({super.key});

  @override
  State<LocalMeshChatScreen> createState() => _LocalMeshChatScreenState();
}

class _LocalMeshChatScreenState extends State<LocalMeshChatScreen> {
  late final TextEditingController _nameCtrl;
  final TextEditingController _msgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: context.read<AppState>().userName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<LocalMeshChatState>();

    if (!chat.supported) {
      return Scaffold(
        appBar: AppBar(title: const Text('Activity 4: Local Mesh Chat')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Local Mesh Chat needs a real Android device or emulator. '
              'Nearby Connections is not available on web or desktop.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activity 4: Local Mesh Chat'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Peers'), Tab(text: 'Chat')],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [_peersTab(chat), _chatTab(chat)],
          ),
        ),
      ),
    );
  }

  Widget _peersTab(LocalMeshChatState chat) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _nameCtrl,
          enabled: !chat.active,
          decoration: const InputDecoration(
            labelText: 'Your display name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: chat.active ? chat.stop : () => chat.start(_nameCtrl.text),
          icon: Icon(chat.active ? Icons.stop : Icons.wifi_tethering),
          label: Text(chat.active ? 'Stop' : 'Start advertising & scanning'),
        ),
        if (chat.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(chat.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        const SizedBox(height: 16),

        const _SectionTitle('Connection requests'),
        if (chat.pending.isEmpty) const Text('None'),
        for (final p in chat.pending)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.endpointName,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('Verification code: ${p.token}'),
                  const Text('Make sure both devices show the same code.'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => chat.accept(p.endpointId),
                          child: const Text('Accept'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => chat.reject(p.endpointId),
                          child: const Text('Reject'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),

        const _SectionTitle('Nearby devices'),
        if (chat.discovered.isEmpty) const Text('No devices found yet'),
        for (final peer in chat.discovered)
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone_android),
              title: Text(peer.name),
              trailing: FilledButton(
                onPressed: () => chat.connectTo(peer),
                child: const Text('Connect'),
              ),
            ),
          ),
        const SizedBox(height: 16),

        const _SectionTitle('Connected'),
        if (chat.connected.isEmpty) const Text('Not connected to anyone'),
        for (final peer in chat.connected)
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(peer.name),
          ),
      ],
    );
  }

  Widget _chatTab(LocalMeshChatState chat) {
    final msgs = chat.messages;
    final canSend = chat.connected.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: msgs.isEmpty
              ? const Center(child: Text('No messages yet'))
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) =>
                      _MessageBubble(message: msgs[msgs.length - 1 - i]),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  enabled: canSend,
                  decoration: InputDecoration(
                    hintText: canSend ? 'Type a message' : 'Connect to a device first',
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: canSend ? (_) => _send(chat) : null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: canSend ? () => _send(chat) : null,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _send(LocalMeshChatState chat) {
    chat.sendMessage(_msgCtrl.text);
    _msgCtrl.clear();
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

/// StatelessWidget: one chat bubble.
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Text(message.text,
              style: Theme.of(context).textTheme.bodySmall),
        ),
      );
    }

    final me = message.isMe;
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: me ? scheme.primaryContainer : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!me)
                Text(message.sender,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              Text(message.text),
            ],
          ),
        ),
      ),
    );
  }
}
