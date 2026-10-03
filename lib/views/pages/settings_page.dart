import 'package:flutter/material.dart';
import 'package:peluna/controllers/settings_controller.dart';
import 'package:peluna/views/widgets/list_tile_widget.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        children: [
          Column(
            spacing: 6,
            children: [
              ListTileWidget(
                title: const Text('Clear All Diary'),
                trailing: Icon(Icons.refresh),
                onTap: () => SettingsController.deleteAllDiaries(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
