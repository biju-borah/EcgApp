import 'dart:async';
import 'dart:typed_data';
import 'package:ecgapp/graph_data.dart';
import 'package:flutter/material.dart';
import 'package:iirjdart/butterworth.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'dart:io';

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
  var filteredData = <double>[];
  var logData = <double>[];
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
  late ChartSeriesController _chartSeriesController_filtered;

  Future<void> saveLogData(List<double> logData) async {
    final List<List<dynamic>> csvData = [];
    for (var i = 0; i < logData.length; i++) {
      csvData.add([i, logData[i]]);
    }
    final String csv = const ListToCsvConverter().convert(csvData);

    final Directory? directory = await getExternalStorageDirectory();
    final String filePath = '${directory!.path}/logdata.csv';

    print(filePath);
    final File file = File(filePath);
    await file.writeAsString(csv);
  }

  void plotgraph() {
    Butterworth butterworth = Butterworth();
    Butterworth butterworthlog = Butterworth();
    // butterworth.bandPass(3, 250, 50, 25);
    butterworth.bandPass(3, 250, 45, 44.5);
    butterworthlog.bandPass(3, 250, 45, 44.5);
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (i >= values.length) {
        timer.cancel();
        saveLogData(logData);
        print('Data saved');
        return;
      }
      setState(() {
        data.add(values[i]);
        filteredData.add(butterworth.filter(values[i]));
        logData.add(butterworthlog.filter(values[i]));
        timestamp.add(DateTime.now());
        i++;
        if (data.length > 100) {
          data.removeAt(0);
          filteredData.removeAt(0);
          timestamp.removeAt(0);
          _chartSeriesController.updateDataSource(
              addedDataIndex: data.length - 1, removedDataIndex: 0);
          _chartSeriesController_filtered.updateDataSource(
              addedDataIndex: filteredData.length - 1, removedDataIndex: 0);
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
              SfCartesianChart(
                primaryXAxis: const DateTimeAxis(),
                primaryYAxis: const NumericAxis(),
                series: <LineSeries<double, DateTime>>[
                  LineSeries<double, DateTime>(
                    onRendererCreated: (ChartSeriesController controller) {
                      _chartSeriesController_filtered = controller;
                    },
                    dataSource: filteredData,
                    xValueMapper: (double data, int index) => timestamp[index],
                    yValueMapper: (double data, int index) => data,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
