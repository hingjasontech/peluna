import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peluna/controllers/tags_controller.dart';

class TagsPage extends StatefulWidget {
  const TagsPage({super.key, this.initialTags});

  final List<String>? initialTags;

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  final TagsController controller = TagsController();

  @override
  void initState() {
    super.initState();
    controller.tags = widget.initialTags;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) => Scaffold(
        // list builder to build body
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListView.builder(
            itemCount: controller.tags?.length ?? 0,
            itemBuilder: (context, index) {
              return ListTile(
                title: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      child: Text('#${controller.tags![index]}'),
                    ),
                  ],
                ),
                leading: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      controller.tags!.removeAt(index);
                    });
                  },
                ),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => controller.popAddTagDialog(context),
          child: Icon(Icons.add),
        ),
        appBar: AppBar(
          title: Text('Tags'),
          leading: BackButton(onPressed: () => context.pop(controller.tags)),
        ),
        bottomNavigationBar: Container(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: () => context.pop(controller.tags),
                  child: Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
