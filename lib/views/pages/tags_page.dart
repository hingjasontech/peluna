import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:peluna/providers/diary_providers.dart';

class TagsPage extends ConsumerStatefulWidget {
  const TagsPage({super.key, this.initialTags});

  final List<String>? initialTags;

  @override
  ConsumerState<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends ConsumerState<TagsPage> {
  /// Keeps the suggestion list compact when there are many matches.
  static const int _maxSuggestions = 8;

  late final List<String> _tags = List<String>.from(
    widget.initialTags ?? const <String>[],
  );

  final TextEditingController _tagController = TextEditingController();
  final FocusNode _tagFocusNode = FocusNode();

  @override
  void dispose() {
    _tagController.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }

  void _addTag(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    final alreadyAdded = _tags.any(
      (tag) => tag.toLowerCase() == trimmed.toLowerCase(),
    );
    if (!alreadyAdded) {
      setState(() => _tags.add(trimmed));
    }

    // Clear the field so the next tag can be typed right away.
    _tagController.clear();
    _tagFocusNode.requestFocus();
  }

  void _removeTag(int index) {
    setState(() => _tags.removeAt(index));
  }

  /// Tags already used anywhere in the app that match [value], prefix matches
  /// first. Tags already on this entry are left out.
  Iterable<String> _suggestions(TextEditingValue value, List<String> allTags) {
    final query = value.text.trim().toLowerCase();
    if (query.isEmpty) return const <String>[];

    final taken = _tags.map((tag) => tag.toLowerCase()).toSet();
    final prefixMatches = <String>[];
    final otherMatches = <String>[];
    for (final tag in allTags) {
      final lower = tag.toLowerCase();
      if (taken.contains(lower)) continue;
      if (lower.startsWith(query)) {
        prefixMatches.add(tag);
      } else if (lower.contains(query)) {
        otherMatches.add(tag);
      }
    }

    return [...prefixMatches, ...otherMatches].take(_maxSuggestions);
  }

  @override
  Widget build(BuildContext context) {
    final allTags = ref.watch(allTagsProvider);
    final theme = Theme.of(context);

    return PopScope<List<String>>(
      // Leaving the page by system back applies the tags just like the arrow.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.pop(_tags);
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: const Text('Tags'),
          leading: BackButton(onPressed: () => context.pop(_tags)),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 6,
            children: [
              // Tags grow upwards from the input at the bottom.
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: _tags.length,
                  itemBuilder: (context, index) {
                    // `reverse` starts at the bottom, but the list keeps the
                    // order the tags were added in.
                    final tagIndex = _tags.length - 1 - index;
                    return ListTile(
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              color: theme.colorScheme.primaryContainer,
                            ),
                            child: Text('#${_tags[tagIndex]}'),
                          ),
                        ],
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeTag(tagIndex),
                      ),
                    );
                  },
                ),
              ),

              // New tags are typed here and added with Enter or a suggestion.
              RawAutocomplete<String>(
                textEditingController: _tagController,
                focusNode: _tagFocusNode,
                optionsViewOpenDirection: OptionsViewOpenDirection.up,
                optionsBuilder: (value) => _suggestions(value, allTags),
                onSelected: _addTag,
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        textInputAction: TextInputAction.done,
                        onSubmitted: _addTag,
                        decoration: InputDecoration(
                          hintText: 'example-tag',
                          prefixIcon: const Icon(Icons.tag),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          suffixIcon: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: controller,
                            builder: (context, value, _) {
                              final canAdd = value.text.trim().isNotEmpty;
                              return IconButton(
                                tooltip: 'Add tag',
                                icon: const Icon(Icons.add_circle),
                                onPressed: canAdd
                                    ? () => _addTag(controller.text)
                                    : null,
                              );
                            },
                          ),
                        ),
                      );
                    },
                optionsViewBuilder: (context, onSelected, options) {
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final tag = options.elementAt(index);
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.tag, size: 18),
                            title: Text(tag),
                            onTap: () => onSelected(tag),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
