import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:peluna/config/constant.dart';
import 'package:peluna/models/diary_draft.dart';
import 'package:peluna/models/diary_model.dart';
import 'package:peluna/providers/app_providers.dart';
import 'package:peluna/providers/diary_providers.dart';
import 'package:peluna/utils/utils.dart';
import 'package:peluna/views/widgets/list_tags_widget.dart';
import 'package:peluna/views/widgets/mood_menu_widget.dart';
import 'package:peluna/views/widgets/score_circle_widget.dart';
import 'package:peluna/views/widgets/weather_menu_widget.dart';

class DiaryPage extends ConsumerStatefulWidget {
  const DiaryPage({super.key});

  @override
  ConsumerState<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends ConsumerState<DiaryPage> {
  /// Index of the page showing the day the diary was opened for.
  ///
  /// Days are infinite, but a [PageController] needs a starting index. This one
  /// leaves room for ~270 years of past days.
  static const int _initialPage = 100000;

  late final DateTime _anchorDate;
  late final PageController _pageController;
  late DateTime _date;

  /// Only the first frame may open the keyboard. Swiping back to the day the
  /// page was opened for should not pop the keyboard up again.
  bool _autofocusInitialDay = true;

  @override
  void initState() {
    super.initState();
    final selected = ref.read(selectedDateProvider);
    _anchorDate = DateTime(selected.year, selected.month, selected.day);
    _date = _anchorDate;
    _pageController = PageController(initialPage: _initialPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autofocusInitialDay = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _dateForPage(int page) => DateTime(
    _anchorDate.year,
    _anchorDate.month,
    _anchorDate.day + page - _initialPage,
  );

  DiaryEditorNotifier get _editor =>
      ref.read(diaryEditorProvider(_date).notifier);

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    await _editor.save();
    if (!mounted) return;
    context.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Saved !'), duration: Duration(seconds: 1)),
    );
  }

  /// Persists the day the user swiped away from, so moving between days never
  /// drops edits. Days that were never written to stay untouched, so browsing
  /// does not create blank diary entries.
  void _saveIfChanged(DateTime date) {
    final draft = ref.read(diaryEditorProvider(date));
    final existing = ref.read(diaryRepositoryProvider).getByDate(date);
    if (!_hasChanges(draft, existing)) return;
    ref.read(diaryEditorProvider(date).notifier).save();
  }

  void _onPageChanged(int page) {
    final next = _dateForPage(page);
    if (next == _date) return;

    _saveIfChanged(_date);
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(selectedDateProvider.notifier).select(next);
    setState(() => _date = next);
  }

  Future<void> _pickMood() async {
    final selected = await showDialog<int?>(
      context: context,
      builder: (_) => MoodMenuWidget(
        selectedMood: ref.read(diaryEditorProvider(_date)).mood,
      ),
    );
    if (selected != null) {
      _editor.setMood(selected);
    }
  }

  Future<void> _pickWeather() async {
    final selected = await showDialog<String?>(
      context: context,
      builder: (_) => WeatherMenuWidget(
        selectedWeather: ref.read(diaryEditorProvider(_date)).weather,
      ),
    );
    if (selected != null) {
      _editor.setWeather(selected);
    }
  }

  Future<void> _pickTags() async {
    final result = await context.pushNamed<List<String>>(
      'tags',
      extra: ref.read(diaryEditorProvider(_date)).tags,
    );
    if (result != null) {
      _editor.setTags(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(diaryEditorProvider(_date));

    return PopScope(
      // The system back gesture must not drop the day being edited either.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _save();
      },
      child: Scaffold(
        // AppBar
        appBar: AppBar(
          centerTitle: false,
          title: Text(dateToString(_date)),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: BackButton(onPressed: _save),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 12,
              children: [
                // Weather topbar
                if (draft.weather != null)
                  Icon(
                    Weather.weatherIcon[Weather.weatherString.indexOf(
                      draft.weather!,
                    )],
                  ),
                // Mood topbar
                if (draft.mood != null)
                  ScoreCircleWidget(index: Mood.moodInt.indexOf(draft.mood!)),
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
              // Swipeable days: previous day on the right swipe, next on the left.
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, page) {
                    final date = _dateForPage(page);
                    return _DiaryDayEditor(
                      key: ValueKey(date),
                      date: date,
                      anchorDate: _anchorDate,
                      pageController: _pageController,
                      autofocus: page == _initialPage && _autofocusInitialDay,
                    );
                  },
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
                          onPressed: _pickMood,
                          icon: const Icon(Icons.mood),
                          tooltip: 'Mood',
                        ),
                        IconButton(
                          onPressed: _pickWeather,
                          icon: const Icon(Icons.sunny),
                          tooltip: 'Weather',
                        ),
                        IconButton(
                          onPressed: _pickTags,
                          icon: const Icon(Icons.tag),
                          tooltip: 'Tags',
                        ),
                      ],
                    ),
                  ),

                  // Save button
                  FilledButton(onPressed: _save, child: const Text('Save')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The editor for a single day, used as one page of the day [PageView].
class _DiaryDayEditor extends ConsumerStatefulWidget {
  const _DiaryDayEditor({
    super.key,
    required this.date,
    required this.anchorDate,
    required this.pageController,
    this.autofocus = false,
  });

  final DateTime date;

  /// The day the diary page was opened for. It is always a valid swipe target,
  /// even when it has no diary yet, so swiping away never traps the user.
  final DateTime anchorDate;

  final PageController pageController;

  /// Whether to open the keyboard when this day has no diary yet. Only the day
  /// the page was opened for does this, so swiping through days stays quiet.
  final bool autofocus;

  @override
  ConsumerState<_DiaryDayEditor> createState() => _DiaryDayEditorState();
}

class _DiaryDayEditorState extends ConsumerState<_DiaryDayEditor> {
  late final TextEditingController _contentController;
  late final bool _isNewDiary;

  /// Page range this drag is allowed to reach, so a day without a diary is a
  /// hard stop in that direction.
  int? _dragMinPage;
  int? _dragMaxPage;

  @override
  void initState() {
    super.initState();
    _isNewDiary =
        ref.read(diaryRepositoryProvider).getByDate(widget.date) == null;
    _contentController = TextEditingController(
      text: ref.read(diaryEditorProvider(widget.date)).content,
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  bool _hasDiaryOn(DateTime date) =>
      date == widget.anchorDate ||
      ref.read(diaryRepositoryProvider).getByDate(date) != null;

  DateTime _dayOffset(int days) =>
      DateTime(widget.date.year, widget.date.month, widget.date.day + days);

  /// Stops any page snap still running, so the finger takes over immediately.
  void _onSwipeStart(DragStartDetails details) {
    final position = widget.pageController.position;
    position.jumpTo(position.pixels);

    final page = (position.pixels / position.viewportDimension).round();
    _dragMinPage = _hasDiaryOn(_dayOffset(-1)) ? page - 1 : page;
    _dragMaxPage = _hasDiaryOn(_dayOffset(1)) ? page + 1 : page;
  }

  void _onSwipeUpdate(DragUpdateDetails details) {
    final position = widget.pageController.position;
    final min = (_dragMinPage ?? 0) * position.viewportDimension;
    final max = (_dragMaxPage ?? 0) * position.viewportDimension;
    final next = (position.pixels - details.delta.dx)
        .clamp(min, max)
        .toDouble();
    position.jumpTo(next);
  }

  void _onSwipeEnd(DragEndDetails details) =>
      _settlePage(details.primaryVelocity ?? 0);

  void _onSwipeCancel() => _settlePage(0);

  /// Snaps to the nearest allowed page, or to the next/previous one on a fling.
  void _settlePage(double velocity) {
    final controller = widget.pageController;
    final page = controller.page;
    if (page == null) return;

    var target = velocity.abs() > 300
        ? (velocity < 0 ? page.floor() + 1 : page.ceil() - 1)
        : page.round();

    final min = _dragMinPage;
    final max = _dragMaxPage;
    if (min != null && target < min) target = min;
    if (max != null && target > max) target = max;

    controller.animateToPage(
      target < 0 ? 0 : target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(diaryEditorProvider(widget.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        // Tags in horizontal scrollable list
        if (draft.tags.isNotEmpty) ListTagsWidget(tags: draft.tags),

        // TextField Canvas
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: TextField(
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  controller: _contentController,
                  autofocus: widget.autofocus && _isNewDiary,
                  onChanged: ref
                      .read(diaryEditorProvider(widget.date).notifier)
                      .setContent,
                  decoration: const InputDecoration(hintText: 'Type here ...'),
                ),
              ),

              // A text field swallows horizontal drags, so this transparent
              // layer handles the day swipe itself while letting taps, text
              // selection and vertical scrolling reach the field below.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: _onSwipeStart,
                  onHorizontalDragUpdate: _onSwipeUpdate,
                  onHorizontalDragEnd: _onSwipeEnd,
                  onHorizontalDragCancel: _onSwipeCancel,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Whether [draft] holds anything that differs from the stored [existing] day.
///
/// A day with no stored entry and an empty draft is considered unchanged, so
/// swiping past empty days does not save them.
bool _hasChanges(DiaryDraft draft, Diary? existing) {
  if (existing == null) {
    return draft.content.isNotEmpty ||
        draft.mood != null ||
        draft.weather != null ||
        draft.tags.isNotEmpty;
  }
  return draft.content != (existing.content ?? '') ||
      draft.mood != existing.mood ||
      draft.weather != existing.weather ||
      !listEquals(draft.tags, existing.tags ?? const <String>[]);
}
