import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:udp/udp.dart';

void main() {
  runApp(MyApp());
  startServer(); // Start the UDP server when the app starts
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('WoL Server')),
        body: Center(child: Text('Listening for WoL requests...')),
      ),
    );
  }
}

Future<void> startServer() async {
  var server = await UDP.bind(Endpoint.any(port: Port(2525)));
  print('Server is running on port 2525');

  await for (var datagram in server.asStream()) {
    // Check if datagram is not null and has data
    if (datagram != null && datagram.data.isNotEmpty) {
      // Convert the datagram data to a string (assuming it's a MAC address)
      var macAddress = String.fromCharCodes(datagram.data);
      print('Received MAC address: $macAddress');
      await sendMagicPacket(macAddress); // Send the magic packet
    } else {
      print('Received empty or null datagram.');
    }
  }
}

Future<void> sendMagicPacket(String macAddress) async {
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
  await sender.send(magicPacket, Endpoint.broadcast(port: Port(9))); // Port 9 is commonly used for WoL
  print('Magic packet sent to MAC address: $macAddress');
  sender.close(); // Close the sender after sending
}

bool isValidMacAddress(String macAddress) {
  // Check if the MAC address is in the correct format (e.g., "00:1A:2B:3C:4D:5E")
  final RegExp macRegExp = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
  return macRegExp.hasMatch(macAddress);
}