import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ESPConfigPage extends StatefulWidget {
  const ESPConfigPage({Key? key}) : super(key: key);

  @override
  State<ESPConfigPage> createState() => _ESPConfigPageState();
}

class _ESPConfigPageState extends State<ESPConfigPage> {
  WebSocketChannel? _channel;
  bool _isConnected = false;

  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _connectToESP();
  }

  void _connectToESP() async {
    try {
      final channel = WebSocketChannel.connect(
        Uri.parse('ws://192.168.4.1:81'),
      );
      
      _channel = channel;

      channel.stream.listen(
        (message) {
          debugPrint("ESP32 sent: $message");
          if (!_isConnected) {
            setState(() => _isConnected = true);
            _showConnectedDialog();
          }
        },
        onError: (error) {
          debugPrint("WebSocket error: $error");
          setState(() => _isConnected = false);
        },
        onDone: () {
          debugPrint("WebSocket closed.");
          setState(() => _isConnected = false);
        },
      );
    } catch (e) {
      debugPrint("Could not connect to ESP32: $e");
      setState(() => _isConnected = false);
    }
  }

  void _showConnectedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Đã kết nối ESP32"),
        content: const Text("Kết nối WebSocket thành công."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showWiFiInputDialog();
            },
            child: const Text("Nhập WiFi"),
          ),
        ],
      ),
    );
  }

  void _showWiFiInputDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nhập thông tin WiFi"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ssidController,
              decoration: const InputDecoration(labelText: "SSID"),
            ),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Mật khẩu"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final ssid = _ssidController.text.trim();
              final pass = _passController.text.trim();

              if (ssid.isNotEmpty && pass.isNotEmpty && _channel != null) {
                final message = '$ssid;$pass';
                _channel!.sink.add(message);
                Navigator.of(context).pop();
                _showSentDialog();
              }
            },
            child: const Text("Gửi"),
          ),
        ],
      ),
    );
  }

  void _showSentDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Đã gửi"),
        content: const Text("Đã gửi SSID và mật khẩu tới ESP32."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _ssidController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cấu hình ESP32"),
        centerTitle: true,
      ),
      body: Center(
        child: _isConnected
            ? const Text("Đã kết nối ESP32")
            : const CircularProgressIndicator(),
      ),
    );
  }
}
