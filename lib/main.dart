import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'ECG Monitoring App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var text = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[Text(text)],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          List<UsbDevice> devices = await UsbSerial.listDevices();
          setState(() {
            text = devices.toString();
          });
          UsbPort port;
          if (devices.isEmpty) {
            return;
          }
          port = (await devices[0].create())!;

          bool openResult = await port.open();
          if (!openResult) {
            setState(() {
              text += "\nFailed to open port";
            });
            return;
          }
          setState(() {
            text += "\nOpened port: $openResult";
          });
          await port.setDTR(true);
          await port.setRTS(true);

          try {
            await port.setPortParameters(9600, UsbPort.DATABITS_8,
                UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

            setState(() {
              text += "\nParameters set, data is being read...\n";
            });
            port.inputStream!.listen((Uint8List event) {
              setState(() {
                String dataAsString = String.fromCharCodes(event);
                text += dataAsString;
              });
            });
          } catch (e) {
            setState(() {
              text += "\nFailed to set parameters: $e";
            });
          }
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
