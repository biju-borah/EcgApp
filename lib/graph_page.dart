import 'dart:async';
import 'dart:typed_data';
import 'package:ecgapp/graph_data.dart';
import 'package:flutter/material.dart';
import 'package:iirjdart/butterworth.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});
  // final int id;

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  var text = '';
  var msg = '';
  var data = <double>[];
  var timestamp = <DateTime>[];
  var dataPoint = '';
  int i = 0;
  List<double> values = GraphData().values;

  @override
  void initState() {
    super.initState();
    // _startConnection(widget.id);
    plotgraph();
  }

  late ChartSeriesController _chartSeriesController;

  void plotgraph() {
    Butterworth butterworth = Butterworth();
    butterworth.bandPass(4, 250, 5, 10);
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        data.add(butterworth.filter(values[i]));
        timestamp.add(DateTime.now());
        i++;
        if (data.length > 100) {
          data.removeAt(0);
          timestamp.removeAt(0);
          _chartSeriesController.updateDataSource(
              addedDataIndex: data.length - 1, removedDataIndex: 0);
        }
      });
    });
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
            data.add(double.parse(dataPoint));
            timestamp.add(DateTime.now());
            dataPoint = '';

            if (data.length > 100) {
              data.removeAt(0);
              timestamp.removeAt(0);
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
          child: Column(
            children: [
              SfCartesianChart(
                primaryXAxis: const DateTimeAxis(),
                primaryYAxis: const NumericAxis(),
                series: <LineSeries<double, DateTime>>[
                  LineSeries<double, DateTime>(
                    onRendererCreated: (ChartSeriesController controller) {
                      _chartSeriesController = controller;
                    },
                    dataSource: data,
                    xValueMapper: (double data, int index) => timestamp[index],
                    yValueMapper: (double data, int index) => data,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(data.isEmpty ? '' : 'Data: $data'),
            ],
          ),
        ),
      ),
    );
  }
}
