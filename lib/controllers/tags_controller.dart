import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final class TagsController extends ChangeNotifier {
  List<String>? tags;

  final textController = TextEditingController();

  // pop a dialog to add tag
  void popAddTagDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Tag'),
        content: TextField(
          autofocus: true,
          controller: textController,
          decoration: InputDecoration(hintText: 'example-tag'),
          onSubmitted: (value) => addTagToList(context, value),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text('Cancel')),
          TextButton(
            onPressed: () => addTagToList(context, textController.text),
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  // add tag to list
  void addTagToList(BuildContext context, String tag) {
    tags ??= [];
    tags!.add(tag);
    context.pop();
    textController.clear();
    notifyListeners();
  }
}
