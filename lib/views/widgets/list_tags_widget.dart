import 'package:flutter/material.dart';

import 'package:peluna/views/widgets/tag_pill.dart';

class ListTagsWidget extends StatelessWidget {
  const ListTagsWidget({super.key, this.tags});

  final List<String>? tags;

  @override
  Widget build(BuildContext context) {
    // A scrollable horizontal row of the day's tags.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 12,
        children: [
          for (final tag in tags ?? const <String>[]) TagPill(tag: tag),
        ],
      ),
    );
  }
}
