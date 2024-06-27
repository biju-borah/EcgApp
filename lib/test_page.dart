import 'package:ecgapp/filtered_data.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class TestPage extends StatefulWidget {
  TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 30; i++) {
      graphData.add(filteredData[i] / 1000);
      timestampData.add(i.toDouble() * 0.08);
    }
  }

  var majorDivision = 0.2;
  var graphData = <double>[];
  var timestampData = <double>[];
  final filteredData = FilteredData().ecgData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Page'),
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: 400,
        child: SfCartesianChart(
          primaryXAxis: NumericAxis(
              interval: majorDivision,
              majorGridLines: const MajorGridLines(
                width: 1,
                color: Colors.red,
              ),
              minorGridLines: const MinorGridLines(
                width: 0.5,
                color: Colors.red,
              ),
              minorTicksPerInterval: 4),
          primaryYAxis: const NumericAxis(
              interval: 0.5,
              majorGridLines: MajorGridLines(
                width: 1,
                color: Colors.red,
              ),
              minorGridLines: MinorGridLines(
                width: 0.5,
                color: Colors.red,
              ),
              minorTicksPerInterval: 4),
          series: <LineSeries<double, double>>[
            LineSeries<double, double>(
              dataSource: graphData,
              xValueMapper: (double data, int index) => timestampData[index],
              yValueMapper: (double data, int index) => data,
            ),
          ],
        ),
      ),
    );
  }
}
