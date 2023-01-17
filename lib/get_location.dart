import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:cron/cron.dart';

class GetLocationWidget extends StatefulWidget {
  const GetLocationWidget({super.key});

  @override
  State<GetLocationWidget> createState() => _GetLocationWidgetState();
}

class _GetLocationWidgetState extends State<GetLocationWidget> {
  bool _loading = false;
  final cron = Cron();

  LocationData? _location;
  String? _error;

  Future<void> _getLocation() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final _locationResult = await getLocation(
        settings: LocationSettings(ignoreLastKnownPosition: true),
      );

      setState(() {
        _location = _locationResult;
        _loading = false;
      });
    } on PlatformException catch (err) {
      setState(() {
        _error = err.code;
        _loading = false;
      });
    }
  }

  Future<void> _initCron() async {
    try {
      cron.schedule(Schedule.parse('*/5 * * * * *'), () {
        _getLocation();
      });
    } on ScheduleParseException {
      // "ScheduleParseException" is thrown if cron parsing is failed.
      print('error');
      await cron.close();
    }
  }

  Future<void> _stopCron() async {
    await cron.close();
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
                'Location: ${_location?.latitude}, ${_location?.longitude}',
            style: Theme.of(context).textTheme.bodyText1,
          ),
          Row(
            children: <Widget>[
              ElevatedButton(
                onPressed: _initCron,
                child: _loading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text('Get'),
              ),
              ElevatedButton(
                onPressed: _stopCron,
                child: const Text('Stop'),
              )
            ],
          ),
        ],
      ),
    );
  }
}
