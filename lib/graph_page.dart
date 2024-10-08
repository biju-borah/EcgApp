import 'dart:async';
import 'dart:typed_data';
import 'package:ecgapp/processing_page.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:iirjdart/butterworth.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'dart:io';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key, required this.id});
  final int id;

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  var isRecording = true;
  var analyzeData = false;
  var filteringStatus = false;
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

  var startTimestamp = DateTime.now().millisecondsSinceEpoch;

  int order = 3;
  double sampleRate = 250;
  double centerFrequency = 45;
  double widthFrequency = 44.5;

  @override
  void initState() {
    super.initState();
    _startConnection(widget.id);
  }

  late ChartSeriesController _chartSeriesController;
  late ChartSeriesController _chartSeriesControllerFiltered;

  Future<void> saveLogData(List<double> logData) async {
    final List<List<dynamic>> csvData = [];
    for (var i = 0; i < logData.length; i++) {
      csvData.add([i, logData[i]]);
    }
    final String csv = const ListToCsvConverter().convert(csvData);

    final Directory? directory = await getExternalStorageDirectory();
    final String filePath =
        '${directory!.path}/EcgLogData_${DateTime.now()}.csv';

    print(filePath);
    final File file = File(filePath);
    await file.writeAsString(csv);
  }

  void resetGraph() {
    setState(() {
      analyzeData = true;
      data.clear();
      timestampData.clear();
      _chartSeriesController.updateDataSource(
          addedDataIndex: 0, removedDataIndex: data.length);
    });
  }

  void plotgraph() {
    resetGraph();
    Butterworth butterworth = Butterworth();
    butterworth.bandPass(order, sampleRate, centerFrequency, widthFrequency);
    Butterworth butterworthlog = Butterworth();
    // butterworth.bandPass(3, 250, 50, 25);
    butterworthlog.bandPass(order, sampleRate, centerFrequency, widthFrequency);
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (i >= values.length) {
        timer.cancel();
        setState(() {
          analyzeData = false;
          filteringStatus = true;
        });
        saveLogData(logData);
        Fluttertoast.showToast(
          msg: 'Data saved',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        // print('Data saved');
        return;
      }
      if (isRecording == false && analyzeData == true) {
        setState(() {
          data.add(values[i]);
          filteredData.add(butterworth.filter(values[i]));
          logData.add(butterworthlog.filter(values[i]));
          timestampData.add(timestamp[i]);
          i++;
          if (data.length > 100) {
            data.removeAt(0);
            filteredData.removeAt(0);
            timestampData.removeAt(0);
            _chartSeriesController.updateDataSource(
                addedDataIndex: data.length - 1, removedDataIndex: 0);
            _chartSeriesControllerFiltered.updateDataSource(
                addedDataIndex: filteredData.length - 1, removedDataIndex: 0);
          }
        });
      }
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
        startTimestamp = DateTime.now().millisecondsSinceEpoch;
      });
      port.inputStream!.listen((Uint8List event) {
        if (DateTime.now().millisecondsSinceEpoch - startTimestamp > 20000 &&
            isRecording) {
          port.close();
          setState(() {
            text += "\nConnection closed";
            isRecording = false;
          });
          return;
        } else {
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
        }
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
                    isRecording
                        ? const Text('Recording...')
                        : analyzeData
                            ? const Text('Filtering...')
                            : filteringStatus
                                ? ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProcessingPage(
                                            rawValue: values,
                                            values: logData,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('Extract features'),
                                  )
                                : ElevatedButton(
                                    onPressed: () {
                                      plotgraph();
                                    },
                                    child: const Text('Analyse Data'),
                                  ),
                    const SizedBox(height: 20),
                    analyzeData || filteringStatus
                        ? SfCartesianChart(
                            primaryXAxis: const DateTimeAxis(),
                            primaryYAxis: const NumericAxis(),
                            series: <LineSeries<double, DateTime>>[
                              LineSeries<double, DateTime>(
                                onRendererCreated:
                                    (ChartSeriesController controller) {
                                  _chartSeriesControllerFiltered = controller;
                                },
                                dataSource: filteredData,
                                xValueMapper: (double data, int index) =>
                                    timestampData[index],
                                yValueMapper: (double data, int index) => data,
                              ),
                            ],
                          )
                        : const SizedBox(height: 0),
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
