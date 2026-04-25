import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pipecat/pipecat.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PipecatExample(),
  ));
}

enum MessageType {
  system,
  user,
  bot,
  functionCall,
}

class ChatMessage {
  final MessageType type;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.type,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class PipecatExample extends StatefulWidget {
  const PipecatExample({super.key});

  @override
  State<PipecatExample> createState() => _PipecatExampleState();
}

class _PipecatExampleState extends State<PipecatExample> {
  late PipecatClient _client;
  final TextEditingController _endpointController = TextEditingController(
    text: 'https://your-pipecat-endpoint.com/connect',
  );
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _status = 'disconnected';
  final List<ChatMessage> _messages = [];
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _client = PipecatClient(transport: const SmallWebRTCTransport());
    _setupListeners();
    _registerFunctions();
  }

  void _setupListeners() {
    _client.onConnected.listen((_) {
      _addMessage(MessageType.system, 'Connected to Pipecat');
      setState(() {
        _status = 'connected';
        _isConnecting = false;
      });
    });

    _client.onDisconnected.listen((_) {
      _addMessage(MessageType.system, 'Disconnected from Pipecat');
      setState(() {
        _status = 'disconnected';
        _isConnecting = false;
      });
    });

    _client.onTransportStateChanged.listen((state) {
      _addMessage(MessageType.system, 'Transport state: ${state.name}');
      setState(() => _status = state.name);
    });

    _client.onUserTranscript.listen((transcript) {
      if (transcript.finalStatus ?? false) {
        _addMessage(MessageType.user, transcript.text);
      }
    });

    _client.onBotTranscript.listen((text) {
      _addMessage(MessageType.bot, text);
    });

    _client.onBackendError.listen((error) {
      _addMessage(MessageType.system, 'Error: $error');
      setState(() {
        _isConnecting = false;
        _status = 'error';
      });
    });
  }

  void _registerFunctions() {
    _client.registerFunctionHandler('get_weather', (data) async {
      final args = data.args;
      String location = 'Unknown';
      if (args is ValueObject) {
        final loc = args.properties['location'];
        if (loc is ValueString) location = loc.value;
      }
      _addMessage(MessageType.functionCall, 'get_weather for $location');
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      return ValueObject({
        'weather': const ValueString('sunny'),
        'temperature': const ValueString('72F'),
      });
    });
  }

  void _addMessage(MessageType type, String text) {
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(type: type, text: text));
    });
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _start() async {
    setState(() {
      _isConnecting = true;
      _messages.clear();
    });

    try {
      _addMessage(MessageType.system, 'Initializing devices...');
      await _client.initialize(enableMic: true, enableCam: false);
      await _client.initDevices();

      _addMessage(MessageType.system, 'Connecting to ${_endpointController.text}...');
      await _client.startBotAndConnect(endpoint: _endpointController.text);
    } catch (e) {
      _addMessage(MessageType.system, 'Failed to start: $e');
      setState(() => _isConnecting = false);
    }
  }

  Future<void> _stop() async {
    try {
      await _client.disconnect();
    } catch (e) {
      _addMessage(MessageType.system, 'Failed to disconnect: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      _messageController.clear();
      await _client.sendText(text);
      _addMessage(MessageType.user, text);
    } catch (e) {
      _addMessage(MessageType.system, 'Failed to send message: $e');
    }
  }

  @override
  void dispose() {
    _client.dispose();
    _endpointController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pipecat Flutter Rich Example'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _status,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildConnectionPanel(),
          _buildHardwarePanel(),
          Expanded(child: _buildChatPanel()),
          _buildInputPanel(),
        ],
      ),
    );
  }

  Widget _buildConnectionPanel() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _endpointController,
              decoration: const InputDecoration(
                labelText: 'Bot Endpoint',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConnecting || _status == 'connected' ? null : _start,
                    child: const Text('Connect'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _status == 'connected' ? _stop : null,
                    child: const Text('Disconnect'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHardwarePanel() {
    return ValueListenableBuilder<HardwareState>(
      valueListenable: _client.hardwareState,
      builder: (context, state, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDeviceDropdown(
                        label: 'Microphone',
                        items: state.availableMics,
                        selected: state.selectedMic,
                        onChanged: (id) => _client.updateMic(id!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDeviceDropdown(
                        label: 'Camera',
                        items: state.availableCams,
                        selected: state.selectedCam,
                        onChanged: (id) => _client.updateCam(id!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => _client.enableMic(!state.isMicEnabled),
                      icon: Icon(state.isMicEnabled ? Icons.mic : Icons.mic_off),
                      color: state.isMicEnabled ? Colors.green : Colors.red,
                      tooltip: state.isMicEnabled ? 'Mute Mic' : 'Unmute Mic',
                    ),
                    IconButton.filledTonal(
                      onPressed: () => _client.enableCam(!state.isCamEnabled),
                      icon: Icon(state.isCamEnabled ? Icons.videocam : Icons.videocam_off),
                      color: state.isCamEnabled ? Colors.green : Colors.red,
                      tooltip: state.isCamEnabled ? 'Disable Cam' : 'Enable Cam',
                    ),
                    IconButton.filledTonal(
                      onPressed: _status == 'connected' ? () => _client.disconnectBot() : null,
                      icon: const Icon(Icons.stop_circle),
                      color: Colors.orange,
                      tooltip: 'Disconnect Bot',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceDropdown({
    required String label,
    required List<MediaDeviceInfo> items,
    required MediaDeviceInfo? selected,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey(selected?.id),
      initialValue: selected?.id,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      items: items.map((device) {
        return DropdownMenuItem(
          value: device.id,
          child: Text(
            device.label,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildChatPanel() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildChatBubble(msg);
      },
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    Color bubbleColor;
    Alignment alignment;
    TextStyle textStyle = const TextStyle(color: Colors.black);

    switch (msg.type) {
      case MessageType.system:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              msg.text,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        );
      case MessageType.user:
        bubbleColor = Colors.blue[100]!;
        alignment = Alignment.centerRight;
        break;
      case MessageType.bot:
        bubbleColor = Colors.green[100]!;
        alignment = Alignment.centerLeft;
        break;
      case MessageType.functionCall:
        bubbleColor = Colors.purple[100]!;
        alignment = Alignment.centerLeft;
        textStyle = const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold);
        break;
    }

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg.text, style: textStyle),
            const SizedBox(height: 4),
            Text(
              '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputPanel() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _status == 'connected' ? _sendMessage : null,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
