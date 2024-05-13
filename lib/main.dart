import 'package:ecgapp/graph_page.dart';
import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
      home: const MyHomePage(title: 'ECG monitoring app'),
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
  List<String?> allDevices = [];

  Future<void> _getDevices() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    if (devices.isEmpty) {
      Fluttertoast.showToast(
          msg: "No devices found",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }
    setState(() {
      allDevices = devices.map((e) => e.deviceName).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Column(
              children: <Widget>[
                for (var i = 0; i < allDevices.length; i++)
                  Card(
                    child: ListTile(
                      title: Text(allDevices[i]!),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GraphPage(
                              id: i,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 5),
              ],
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () async {
                await _getDevices();
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Scan devices'),
                  SizedBox(width: 10),
                  Icon(Icons.search),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
