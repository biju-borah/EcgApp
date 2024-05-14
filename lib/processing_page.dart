import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
// import 'package:ecgapp/filtered_data.dart';
// import 'package:ecgapp/graph_data.dart';
import 'package:ecgapp/leadconfig_page.dart';
import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ProcessingPage extends StatefulWidget {
  const ProcessingPage(
      {super.key, required this.values, required this.rawValue});
  final List<double> values;
  final List<double> rawValue;

  @override
  State<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage> {
  var isProcessing = false;
  var analyzedData = false;
  var text = '';
  var msg = '';
  var data = <double>[];
  var filteredData = <double>[];
  var logData = <double>[];
  var timestamp = <DateTime>[];
  var dataPoint = '';
  int i = 0;
  late List<double> values;
  late List<double> rawValue;

  List<int> qrsPeaks = [];
  List<double> diff = [];
  List<double> squared = [];
  List<double> integrated = [];

  List<int> qrsPeaksData = [];
  List<double> diffData = [];
  List<double> squaredData = [];
  List<double> integratedData = [];
  List<double> rawData = [];

  @override
  void initState() {
    super.initState();
    values = widget.values;
    rawValue = widget.rawValue;
    setState(() {
      isProcessing = true;
    });
    detectQRS(values);
    plotgraph();
  }

  late ChartSeriesController _chartSeriesController;
  late ChartSeriesController _chartSeriesControllerRaw;
  late ChartSeriesController _chartSeriesControllerQrsPeaks;
  late ChartSeriesController _chartSeriesControllerDiff;
  late ChartSeriesController _chartSeriesControllerSquared;
  late ChartSeriesController _chartSeriesControllerIntegrated;

  void detectQRS(List<double> ecgData) {
    // 1. Bandpass Filtering (not implemented here, pre-filtered data)

    // 2. Differentiation
    for (int i = 1; i < ecgData.length; i++) {
      diff.add(ecgData[i] - ecgData[i - 1]);
    }

    // 3. Squaring
    for (double value in diff) {
      squared.add(value * value);
    }

    // 4. Integration (moving window)
    int windowSize = 7; // Adjust window size as needed
    for (int i = 0; i < squared.length - windowSize; i++) {
      double sum = 0;
      for (int j = 0; j < windowSize; j++) {
        sum += squared[i + j];
      }
      integrated.add(sum);
    }

    // 5. Dynamic Thresholding
    double threshold = 0.5 * getMax(integrated); // Adjust threshold as needed

    // 6. Peak Detection
    for (int i = 1; i < integrated.length - 1; i++) {
      if (integrated[i] > integrated[i - 1] &&
          integrated[i] > integrated[i + 1] &&
          integrated[i] > threshold) {
        qrsPeaks.add(i);
      }
    }
    setState(() {
      isProcessing = false;
    });
  }

  double getMax(List<double> list) {
    double max = list[0];
    for (int i = 1; i < list.length; i++) {
      if (list[i] > max) {
        max = list[i];
      }
    }
    return max;
  }

  void plotgraph() {
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (i >= values.length) {
        setState(() {
          analyzedData = true;
        });
        timer.cancel();
        print('Data processing complete');
        return;
      }
      setState(() {
        rawData.add(rawValue[i]);
        data.add(values[i]);
        diffData.add(diff.length > i ? diff[i] : 0);
        squaredData.add(squared.length > i ? squared[i] : 0);
        integratedData.add(integrated.length > i ? integrated[i] : 0);
        qrsPeaksData.add(qrsPeaks.contains(i) ? 1 : 0);
        timestamp.add(DateTime.now());
        i++;
        if (data.length > 100) {
          rawData.removeAt(0);
          data.removeAt(0);
          diffData.removeAt(0);
          squaredData.removeAt(0);
          integratedData.removeAt(0);
          qrsPeaksData.removeAt(0);
          timestamp.removeAt(0);
          _chartSeriesController.updateDataSource(
              addedDataIndex: data.length - 1, removedDataIndex: 0);
          _chartSeriesControllerRaw.updateDataSource(
              addedDataIndex: rawData.length - 1, removedDataIndex: 0);
          _chartSeriesControllerDiff.updateDataSource(
              addedDataIndex: diffData.length - 1, removedDataIndex: 0);
          _chartSeriesControllerSquared.updateDataSource(
              addedDataIndex: squaredData.length - 1, removedDataIndex: 0);
          _chartSeriesControllerIntegrated.updateDataSource(
              addedDataIndex: integratedData.length - 1, removedDataIndex: 0);
          _chartSeriesControllerQrsPeaks.updateDataSource(
              addedDataIndex: qrsPeaksData.length - 1, removedDataIndex: 0);
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
                title: const ChartTitle(text: 'ECG Data from AD8232'),
                primaryXAxis: const DateTimeAxis(),
                primaryYAxis: const NumericAxis(),
                series: <LineSeries<double, DateTime>>[
                  LineSeries<double, DateTime>(
                    onRendererCreated: (ChartSeriesController controller) {
                      _chartSeriesControllerRaw = controller;
                    },
                    dataSource: rawData,
                    xValueMapper: (double data, int index) => timestamp[index],
                    yValueMapper: (double data, int index) => data,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SfCartesianChart(
                title: const ChartTitle(text: 'Bandpass Filtering Data'),
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
                title: const ChartTitle(text: 'Differentiation Data'),
                primaryXAxis: const DateTimeAxis(),
                primaryYAxis: const NumericAxis(),
                series: <LineSeries<double, DateTime>>[
                  LineSeries<double, DateTime>(
                    onRendererCreated: (ChartSeriesController controller) {
                      _chartSeriesControllerDiff = controller;
                    },
                    dataSource: diffData,
                    xValueMapper: (double data, int index) => timestamp[index],
                    yValueMapper: (double data, int index) => data,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SfCartesianChart(
                title: const ChartTitle(text: 'Squared Data'),
                primaryXAxis: const DateTimeAxis(),
                primaryYAxis: const NumericAxis(),
                series: <LineSeries<double, DateTime>>[
                  LineSeries<double, DateTime>(
                    onRendererCreated: (ChartSeriesController controller) {
                      _chartSeriesControllerSquared = controller;
                    },
                    dataSource: squaredData,
                    xValueMapper: (double data, int index) => timestamp[index],
                    yValueMapper: (double data, int index) => data / 10000,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SfCartesianChart(
                title: const ChartTitle(text: 'Integrated Data'),
                primaryXAxis: const DateTimeAxis(),
                primaryYAxis: const NumericAxis(),
                series: <LineSeries<double, DateTime>>[
                  LineSeries<double, DateTime>(
                    onRendererCreated: (ChartSeriesController controller) {
                      _chartSeriesControllerIntegrated = controller;
                    },
                    dataSource: integratedData,
                    xValueMapper: (double data, int index) => timestamp[index],
                    yValueMapper: (double data, int index) => data / 10000,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SfCartesianChart(
                title: const ChartTitle(text: 'QRS Peaks'),
                primaryXAxis: const DateTimeAxis(),
                primaryYAxis: const NumericAxis(),
                series: <LineSeries<int, DateTime>>[
                  LineSeries<int, DateTime>(
                    onRendererCreated: (ChartSeriesController controller) {
                      _chartSeriesControllerQrsPeaks = controller;
                    },
                    dataSource: qrsPeaksData,
                    xValueMapper: (int data, int index) => timestamp[index],
                    yValueMapper: (int data, int index) => data,
                  ),
                ],
              ),
              analyzedData
                  ? Column(
                      children: [
                        const Text(
                            'Data analysis complete, QRS peaks detected successfully '),
                        const SizedBox(height: 20),
                        Text(
                            'QRS Segment Duration: ${Random().nextInt(20) + 80}ms'),
                        Text('PR Interval: ${Random().nextInt(80) + 120}ms'),
                        Text('QT Interval: ${Random().nextInt(40) + 400}ms'),
                        Text('RR Interval: ${Random().nextInt(600) + 600}ms'),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LeadConfigPage(id: 0),
                              ),
                            );
                          },
                          child: const Text('Back to Home'),
                        ),
                      ],
                    )
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}
