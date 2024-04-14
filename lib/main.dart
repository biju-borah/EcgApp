import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
            children: <Widget>[
              Text(text),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          List<UsbDevice> devices = await UsbSerial.listDevices();
          print(devices[0]);
          setState(() {
            text = devices.toString();
          });
          UsbPort port;
          if (devices.length == 0) {
            return;
          }
          port = (await devices[0].create())!;

          bool openResult = await port.open();
          if (!openResult) {
            setState(() {
              text += "\nFailed to open port";
            });
            print("Failed to open");
            return;
          }
          setState(() {
            text += "\nOpened port: $openResult";
          });
          await port.setDTR(true);
          await port.setRTS(true);

          port.setPortParameters(115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1,
              UsbPort.PARITY_NONE);

          // print first result and close port.
          port.inputStream?.listen((Uint8List event) {
            print(event);
            setState(() {
              text += '\n$event';
            });
            // port.close();
          });

          // await port.write(Uint8List.fromList([0x10, 0x00]));
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
