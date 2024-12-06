import 'package:flutter/material.dart';
import 'package:udp/udp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
  final String serverIp = '83.85.92.230'; // Replace with your server IP
  final int serverPort = 2525; // Replace with your server port
  String macAddress = '';

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

  Future<void> sendWoL(String macAddress) async {
    // Validate MAC address format
    if (!isValidMacAddress(macAddress)) {
      print('Invalid MAC address format: $macAddress');
      return;
    }

    // Convert MAC address to bytes
    List<int> macBytes = macAddress.split(':').map((e) => int.parse(e, radix: 16)).toList();

    // Create the magic packet
    Uint8List magicPacket = Uint8List(102);
    for (int i = 0; i < 6; i++) {
      magicPacket[i] = 0xFF; // First 6 bytes are 0xFF
    }
    for (int i = 0; i < 16; i++) {
      for (int j = 0; j < 6; j++) {
        magicPacket[6 + i * 6 + j] = macBytes[j]; // Next 16 repetitions of MAC address
      }
    }

    // Send the magic packet to the broadcast address
    var sender = await UDP.bind(Endpoint.any(port: Port(0))); // Bind to any available port
    await sender.send(magicPacket, Endpoint.broadcast(port: Port(serverPort))); // Use the same port as the server
    print('Magic packet sent to MAC address: $macAddress');
    sender.close(); // Close the sender after sending
  }

  bool isValidMacAddress(String macAddress) {
    // Check if the MAC address is in the correct format (e.g., "00:1A:2B:3C:4D:5E")
    final RegExp macRegExp = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
    return macRegExp.hasMatch(macAddress);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wake on LAN')),
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
                  sendWoL(macAddress); // Call sendWoL function with the MAC address
                } else {
                  print('Please enter a valid MAC address');
                }
              },
              child: const Text('Wake PC'),
            ),
          ],
        ),
      ),
    );
  }
}