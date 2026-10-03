import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peluna/config/constant.dart';
import 'package:peluna/config/notifier.dart';
import 'package:peluna/views/widgets/score_circle_widget.dart';

class DiaryCardWidget extends StatelessWidget {
  const DiaryCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: currentDiaryNotifier,
      builder: (context, currentDiary, child) {
        if (currentDiary == null) return SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card.filled(
            child: InkWell(
              onTap: () => context.goNamed('diary'),
              child: SizedBox(
                width: double.infinity,
                height: 150,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    spacing: 6,
                    crossAxisAlignment: .start,
                    mainAxisAlignment: .end,
                    children: [
                      Expanded(
                        child: Text(
                          currentDiary.content ?? '',
                          overflow: .ellipsis,
                        ),
                      ),

                      if (currentDiary.mood != null ||
                          currentDiary.weather != null)
                        Divider(),

                      Row(
                        spacing: 8,
                        children: [
                          if (currentDiary.mood != null)
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: FittedBox(
                                child: ScoreCircleWidget(
                                  index: Mood.getIndex(currentDiary.mood!),
                                ),
                              ),
                            ),
                          if (currentDiary.weather != null)
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: FittedBox(
                                child: Icon(
                                  Weather.weatherIcon[Weather.getIndex(
                                    currentDiary.weather!,
                                  )],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
