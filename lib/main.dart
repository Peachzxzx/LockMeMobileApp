import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() => runApp(new LockMeMobileApp());

class LockMeMobileApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MainPage());
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPage createState() => new _MainPage();
}

/* State Machine diagram
 * 0 = Disconnected(Initial) state
 * 1 = Searching state
 * 2 = Connected state
 * 3 = Not found state
 */
class _MainPage extends State<MainPage> {
  int state = 0;
  BluetoothConnection connection;
  bool get isConnected => connection != null && connection.isConnected;

  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    if (isConnected) {
      state = 0;
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    super.dispose();
  }

  List<String> textState = [
    "Touch to unlock",
    "Searching for ESP32 lock",
    "Connected",
    "Device is not found. Touch to try again"
  ];

  List<IconData> iconState = [
    Icons.bluetooth,
    Icons.bluetooth_searching,
    Icons.bluetooth_connected,
    Icons.bluetooth_disabled
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => connectToESP32(),
      child: Scaffold(
        backgroundColor: Colors.lightBlue,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                iconState[state],
                size: 200.0,
                color: Colors.white54,
              ),
              Text(
                textState[state],
                style: Theme.of(context)
                    .primaryTextTheme
                    .subtitle1
                    .copyWith(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onDataReceived2(Uint8List data) {}

  void connectToESP32() {
    if (state == 2) return;
    setState(() {
      state = 1;
    });
    BluetoothConnection.toAddress("E8:68:E7:22:BE:A2").then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        state = 2;
        isDisconnecting = false;
      });

      connection.input.listen(_onDataReceived2).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {
            state = 0;
          });
        }
      });
    }).catchError((error) {
      setState(() {
        state = 3;
      });
      print('Cannot connect, exception occured');
      print(error);
    });
  }
}
