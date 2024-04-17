import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key, required this.id});
  final int id;

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  var text = '';
  var msg = '';
  var data = <String>[];
  var timestamp = <DateTime>[];
  var dataPoint = '';

  @override
  void initState() {
    super.initState();
    _startConnection(widget.id);
  }

  Future<void> _startConnection(int id) async {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    UsbPort port;
    if (devices.isEmpty) {
      setState(() {
        msg = 'Error establishing connection';
      });
      return;
    }
    port = (await devices[id].create())!;
    bool openResult = await port.open();
    if (!openResult) {
      setState(() {
        msg = "Failed to open port";
      });
      return;
    }
    setState(() {
      text = "Port opened successfully";
    });
    await port.setDTR(true);
    await port.setRTS(true);

    try {
      await port.setPortParameters(
          9600, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

      setState(() {
        text += "\nParameters set, data is being read...\n";
      });
      port.inputStream!.listen((Uint8List event) {
        setState(() {
          String dataAsString = String.fromCharCodes(event);
          text += dataAsString;
          if (dataAsString.contains('\n')) {
            dataPoint += dataAsString.split('\n')[0];
            data.add(dataPoint);
            timestamp.add(DateTime.now());
            dataPoint = dataAsString.split('\n')[1];
          } else {
            dataPoint += dataAsString;
          }
        });
      });
    } catch (e) {
      setState(() {
        text += "\nFailed to set parameters: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ECG Monitoring App'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              data.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Text(data.toString()),
            ],
          ),
        ),
      ),
    );
  }
}
