import 'package:flutter/material.dart';

class ListTagsWidget extends StatefulWidget {
  const ListTagsWidget({super.key, this.tags});

  final List<String>? tags;

  @override
  State<ListTagsWidget> createState() => _HorizontalListTagState();
}

class _HorizontalListTagState extends State<ListTagsWidget> {
  @override
  Widget build(BuildContext context) {
    // add scrollable horizontal list
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 12,
        children:
            widget.tags
                ?.map(
                  (tag) => Chip(
                    label: Text('#$tag'),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    side: BorderSide.none,
                  ),
                )
                .toList() ??
            [],
      ),
    );
  }
}
