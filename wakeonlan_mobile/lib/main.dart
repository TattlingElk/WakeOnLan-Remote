import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WoLApp(),
    );
  }
}

class WoLApp extends StatefulWidget {
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
    final response = await http.post(
      Uri.parse('http://$serverIp:$serverPort/wake'),
      body: {'mac': macAddress},
    );

    if (response.statusCode == 200) {
      print('Wake on LAN packet sent successfully');
    } else {
      print('Failed to send WoL packet: ${response.reasonPhrase}');
    }
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