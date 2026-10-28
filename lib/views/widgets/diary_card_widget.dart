import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:peluna/config/constant.dart';
import 'package:peluna/providers/app_providers.dart';
import 'package:peluna/providers/diary_providers.dart';
import 'package:peluna/views/widgets/score_circle_widget.dart';

class DiaryCardWidget extends ConsumerWidget {
  const DiaryCardWidget({super.key});

  /// Opens the card's context menu and, after confirmation, deletes the diary
  /// for [date].
  Future<void> _showDeleteMenu(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final card = context.findRenderObject()! as RenderBox;
    final anchor = card.localToGlobal(
      Offset(0, card.size.height / 2),
      ancestor: overlay,
    );

    final selected = await showMenu<bool>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(anchor, anchor),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem<bool>(
          value: true,
          child: Text(
            'Delete this diary',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
      ],
    );

    if (selected != true || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('This will delete this diary.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    await ref.read(diaryRepositoryProvider).delete(date);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Diary deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDiary = ref.watch(selectedDiaryProvider);
    if (currentDiary == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card.filled(
        child: InkWell(
          onTap: () => context.goNamed('diary'),
          onLongPress: () => _showDeleteMenu(context, ref, currentDiary.date),
          child: SizedBox(
            width: double.infinity,
            height: 145,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                spacing: 6,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      currentDiary.content ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  if (currentDiary.mood != null || currentDiary.weather != null)
                    const Divider(),

                  Row(
                    spacing: 8,
                    children: [
                      if (currentDiary.mood != null &&
                          Mood.getIndex(currentDiary.mood!) != -1)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: FittedBox(
                            child: ScoreCircleWidget(
                              index: Mood.getIndex(currentDiary.mood!),
                            ),
                          ),
                        ),
                      if (currentDiary.weather != null &&
                          Weather.getIndex(currentDiary.weather!) != -1)
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
  }
}
