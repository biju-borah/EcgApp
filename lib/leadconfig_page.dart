import 'dart:async';
import 'dart:typed_data';
import 'package:ecgapp/graph_page.dart';
import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class LeadConfigPage extends StatefulWidget {
  const LeadConfigPage({super.key, required this.id});
  final int id;

  @override
  State<LeadConfigPage> createState() => _LeadConfigPageState();
}

class _LeadConfigPageState extends State<LeadConfigPage> {
  var text = '';
  var msg = '';
  var data = <double>[];
  var filteredData = <double>[];
  var logData = <double>[];
  var timestamp = <DateTime>[];
  var timestampData = <DateTime>[];
  var dataPoint = '';
  int i = 0;
  // List<double> values = GraphData().values;
  List<double> values = [];

  @override
  void initState() {
    super.initState();
    _startConnection(widget.id);
  }

  late ChartSeriesController _chartSeriesController;

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
          // text += dataAsString;
          if (dataAsString.contains('\n')) {
            dataPoint += dataAsString.split('\n')[0];
            values.add(double.parse(dataPoint));
            timestamp.add(DateTime.now());
            data.add(double.parse(dataPoint));
            timestampData.add(DateTime.now());
            dataPoint = '';

            if (data.length > 100) {
              data.removeAt(0);
              timestampData.removeAt(0);
            }

            _chartSeriesController.updateDataSource(
                addedDataIndex: data.length - 1, removedDataIndex: 0);
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
          child: data.isNotEmpty
              ? Column(
                  children: [
                    SfCartesianChart(
                      primaryXAxis: const DateTimeAxis(),
                      primaryYAxis: const NumericAxis(),
                      series: <LineSeries<double, DateTime>>[
                        LineSeries<double, DateTime>(
                          onRendererCreated:
                              (ChartSeriesController controller) {
                            _chartSeriesController = controller;
                          },
                          dataSource: data,
                          xValueMapper: (double data, int index) =>
                              timestampData[index],
                          yValueMapper: (double data, int index) => data,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Select a lead configuration:',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => GraphPage(id: widget.id)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.fromLTRB(36.0, 12.0, 36.0, 12.0),
                        ),
                        child: const Text('Lead I'),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle lead 2 button press
                        },
                        style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.fromLTRB(36.0, 12.0, 36.0, 12.0),
                        ),
                        child: const Text('Lead II'),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle lead 3 button press
                        },
                        style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.fromLTRB(36.0, 12.0, 36.0, 12.0),
                        ),
                        child: const Text('Lead III'),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Text(text),
                  ],
                ),
        ),
      ),
    );
  }
}
