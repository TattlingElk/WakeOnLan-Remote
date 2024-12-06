import 'package:flutter/material.dart';
import 'package:udp/udp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WoLApp(),
    );
  }
}

class WoLApp extends StatefulWidget {
  const WoLApp({super.key});

  @override
  _WoLAppState createState() => _WoLAppState();
}

class _WoLAppState extends State<WoLApp> {
  String macAddress = '';
  final String targetIp = 'tattlingelk.com'; // Replace with your target IP
  final int targetPort = 2525; // Replace with your target port

  @override
  void initState() {
    super.initState();
    _loadLastMacAddress(); // Load the last MAC address when the app starts
  }

  Future<void> _loadLastMacAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      macAddress = prefs.getString('last_mac_address') ?? ''; // Load the last MAC address
    });
  }

  Future<void> _saveLastMacAddress(String macAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_mac_address', macAddress); // Save the MAC address
  }

  Future<void> sendMacAddress(String macAddress) async {
  // Validate MAC address format
  if (!isValidMacAddress(macAddress)) {
    print('Invalid MAC address format: $macAddress');
    return;
  }

  // Send the MAC address as a string
  var sender = await UDP.bind(Endpoint.any(port: const Port(0))); // Bind to any available port
  await sender.send(Uint8List.fromList(macAddress.codeUnits), Endpoint.unicast(InternetAddress(targetIp), port: Port(targetPort))); // Send MAC address as bytes
  print('MAC address sent to $targetIp:$targetPort: $macAddress');
  sender.close(); // Close the sender after sending
}

  bool isValidMacAddress(String macAddress) {
    final RegExp macRegExp = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
    return macRegExp.hasMatch(macAddress);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send MAC Address')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Enter MAC Address'),
              onChanged: (value) {
                setState(() {
                  macAddress = value; // Store the MAC address
                });
              },
              controller: TextEditingController(text: macAddress), // Set the initial value
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (macAddress.isNotEmpty) {
                  _saveLastMacAddress(macAddress); // Save the MAC address
                  sendMacAddress(macAddress); // Call sendMacAddress function with the MAC address
                } else {
                  print('Please enter a valid MAC address');
                }
              },
              child: const Text('Send MAC Address'),
            ),
          ],
        ),
      ),
    );
  }
}