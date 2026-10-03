import 'package:flutter/material.dart';
import 'package:peluna/config/constant.dart';
import 'package:peluna/controllers/diary_controller.dart';
import 'package:peluna/views/widgets/list_tags_widget.dart';
import 'package:peluna/views/widgets/score_circle_widget.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  final DiaryController controller = DiaryController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          // AppBar
          appBar: AppBar(
            title: Text(controller.dateString),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: BackButton(onPressed: () => controller.saveDiary(context)),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 12,
                children: [
                  // Weather topbar
                  if (controller.selectedWeather != null)
                    Icon(
                      Weather.weatherIcon[Weather.weatherString.indexOf(
                        controller.selectedWeather!,
                      )],
                    ),
                  // Mood topbar
                  if (controller.selectedMood != null)
                    ScoreCircleWidget(
                      index: Mood.moodInt.indexOf(controller.selectedMood!),
                    ),
                ],
              ),
            ],
          ),

          // Body
          body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                // Tags in horizontal scrollable list
                if (controller.tags.isNotEmpty)
                  ListTagsWidget(tags: controller.tags),

                // TextField Canvas
                Expanded(
                  child: TextField(
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    controller: controller.contentController,
                    autofocus: controller.isNewDiary,
                    decoration: const InputDecoration(
                      hintText: 'Type here ...',
                    ),
                  ),
                ),

                // Actions bar: Mood, Weather, Tags & Save button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Mood & Weather & Tags buttons
                    Expanded(
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => controller.showMoodMenu(context),
                            icon: const Icon(Icons.mood),
                            tooltip: 'Mood',
                          ),
                          IconButton(
                            onPressed: () =>
                                controller.showWeatherMenu(context),
                            icon: const Icon(Icons.sunny),
                            tooltip: 'Weather',
                          ),
                          IconButton(
                            onPressed: () => controller.selectTags(context),
                            icon: const Icon(Icons.tag),
                            tooltip: 'Tags',
                          ),
                        ],
                      ),
                    ),

                    // Save button
                    FilledButton(
                      onPressed: () => controller.saveDiary(context),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
