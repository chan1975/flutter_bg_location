import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:cron/cron.dart';

class ListenLocationWidget extends StatefulWidget {
  const ListenLocationWidget({super.key});

  @override
  State<ListenLocationWidget> createState() => _ListenLocationWidgetState();
}

class _ListenLocationWidgetState extends State<ListenLocationWidget> {
  LocationData? _location;
  StreamSubscription<LocationData>? _locationSubscription;
  String? _error;
  Cron cron = Cron();
  List<String> _history = [];
  bool _inBackground = false;

  Future<void> _listenLocation() async {
    _locationSubscription =
        onLocationChanged(inBackground: true).handleError((dynamic err) {
      print('Error en listen location');
      if (err is PlatformException) {
        setState(() {
          _error = err.code;
        });
      }
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen((LocationData currentLocation) async {
      var newHistoryData = _history;
      newHistoryData.add(
          "Location: ${currentLocation.longitude}, Date: ${DateTime.now()} ");
      setState(() {
        _error = null;

        _location = currentLocation;

        _history = newHistoryData;
      });
      await updateBackgroundNotification(
        subtitle:
            'Location: ${currentLocation.latitude}, ${currentLocation.longitude}',
        onTapBringToFront: true,
      );
      _locationSubscription?.cancel();
      _locationSubscription = null;
    });
  }

  Future<void> _initCron() async {
    setLocationSettings(useGooglePlayServices: true, maxWaitTime: 60000);
    cron = Cron();
    try {
      cron.schedule(Schedule.parse('*/3 * * * *'), () {
        print('init');
        if (_locationSubscription == null) _listenLocation();
      });
    } on ScheduleParseException {
      // "ScheduleParseException" is thrown if cron parsing is failed.
      print('error');
      await cron.close();
    }
  }

  Future<void> _stopCron() async {
    if (_locationSubscription == null) await _stopListen();
    await cron.close();
  }

  Future<void> _stopListen() async {
    await _locationSubscription?.cancel();
    setState(() {
      _locationSubscription = null;
    });
  }

  void _clearList() {
    setState(() {
      _history = [];
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    setState(() {
      _locationSubscription = null;
    });
    cron.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _error ??
                '''
Listen location: ${_location?.latitude}, ${_location?.longitude}
                ''',
            style: Theme.of(context).textTheme.bodyText1,
          ),
          Row(
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(right: 42),
                child: ElevatedButton(
                  onPressed: _locationSubscription == null ? _initCron : null,
                  child: const Text('Listen'),
                ),
              ),
              ElevatedButton(
                onPressed: _stopCron,
                child: const Text('Stop'),
              ),
              ElevatedButton(
                onPressed: _clearList,
                child: const Text('Clear List'),
              )
            ],
          ),
          SwitchListTile(
            value: _inBackground,
            title: const Text('Get location in background'),
            onChanged: (value) {
              setState(() {
                _inBackground = value;
              });
            },
          ),
          Column(children: _history.map((e) => Text(e)).toList()),
        ],
      ),
    );
  }
}
