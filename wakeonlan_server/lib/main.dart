import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:udp/udp.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WoLServer(),
    );
  }
}

class WoLServer extends StatefulWidget {
  const WoLServer({super.key});

  @override
  _WoLServerState createState() => _WoLServerState();
}

class _WoLServerState extends State<WoLServer> {
  String _statusText = 'Listening for WoL requests...';

  @override
  void initState() {
    super.initState();
    // Start the UDP server when the widget is initialized
    startServer((macAddress) {
      // Update the UI when a MAC address is received
      setState(() {
        _statusText = 'Wake up received for $macAddress';
      });

      // Revert back to the original text after 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        setState(() {
          _statusText = 'Listening for WoL requests...';
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WoL Server')),
      body: Center(child: Text(_statusText)),
    );
  }
}

Future<void> startServer(Function(String) onMacAddressReceived) async {
  var server = await UDP.bind(Endpoint.any(port: const Port(2525)));
  print('Server is running on port 2525');

  await for (var datagram in server.asStream()) {




    // Check if datagram is not null and has data
    if (datagram != null && datagram.data.isNotEmpty) {
      // Convert the datagram data to a string (assuming it's a MAC address)
      var macAddress = String.fromCharCodes(datagram.data);
      print('Received MAC address: $macAddress');

      await sendMagicPacket(macAddress); // Send the magic packet
      // Call the callback function to update the UI
      onMacAddressReceived(macAddress);
      // Validate the MAC address format
      if (isValidMacAddress(macAddress)) {
        await sendMagicPacket(macAddress); // Send the magic packet
        // Call the callback function to update the UI
        onMacAddressReceived(macAddress);
      } else {
        print('Invalid MAC address format received: $macAddress');
      }
    } else {
      print('Received empty or null datagram.');
    }
  }
}
Future<void> sendMagicPacket(String macAddress) async {

  // Convert the MAC address from string format to byte array
  List<int> macBytes = macAddress.split(':').map((part) => int.parse(part, radix: 16)).toList();

  // Create the magic packet
  // The magic packet consists of 6 bytes of 0xFF followed by 16 repetitions of the MAC address
  List<int> magicPacket = List.filled(6, 0xFF) + List.generate(16, (index) => macBytes).expand((x) => x).toList();

  // Create a UDP socket
  RawDatagramSocket socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  
  // Send the magic packet to the broadcast address (255.255.255.255) on port 9
  socket.send(Uint8List.fromList(magicPacket), InternetAddress('192.168.178.255'), 9);
  
  // Close the socket
  socket.close();
}

bool isValidMacAddress(String macAddress) {
  // Check if the MAC address is in the correct format (e.g., "00:1A:2B:3C:4D:5E")
  final RegExp macRegExp = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
  return macRegExp.hasMatch(macAddress);
}