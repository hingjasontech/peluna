import 'package:flutter/material.dart';

import 'package:peluna/config/constant.dart';

class WeatherMenuWidget extends StatefulWidget {
  const WeatherMenuWidget({super.key, this.selectedWeather});

  final String? selectedWeather;

  @override
  State<WeatherMenuWidget> createState() => _WeatherMenuWidgetState();
}

class _WeatherMenuWidgetState extends State<WeatherMenuWidget> {
  String? _selectedWeather;

  @override
  void initState() {
    super.initState();
    _selectedWeather = widget.selectedWeather;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Weather'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: Weather.weatherString.length,
          itemBuilder: (_, index) {
            return RadioGroup<String>(
              groupValue: _selectedWeather,
              onChanged: (value) {
                setState(() {
                  _selectedWeather = value;
                });
              },
              child: RadioListTile(
                minVerticalPadding: 12,
                value: Weather.weatherString[index],
                title: Row(
                  spacing: 8,
                  children: [
                    Icon(Weather.weatherIcon[index]),
                    Text(Weather.weatherString[index]),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedWeather),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
