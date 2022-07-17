import 'package:flutter/material.dart';
import 'package:maps_app/pages/view_map_page.dart';
import 'package:provider/provider.dart';

import '../models/user_map.dart';
import '../utils.dart';

class ListMapsPage extends StatelessWidget {
  ListMapsPage({Key? key}) : super(key: key);
  final String appBarTitle = "My saved maps";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(appBarTitle),
      ),
      body: ChangeNotifierProvider<UserMapService>.value(
          value: UserMapService.getInstanceForProvider(),
          child: _ListViewWrapper()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showTitleDialog(context).then((title) {
            if (title == null) return;
            Navigator.push<void>(
                context,
                MaterialPageRoute(
                    builder: (context) => ViewMapPage(userMapTitle: title)));
          });
        },
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class _ListViewWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Provider.of<UserMapService>(context);
    final userFut = UserMapService.findAll();
    return FutureBuilder(
        future: userFut,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }
          final maps = snapshot.data as List<UserMap>;
          return ListView.builder(
              itemCount: maps.length,
              itemBuilder: (context, index) {
                final k = GlobalKey();
                return ListTile(
                  key: k,
                  title: Text(maps[index].title),
                  onTap: () {
                    Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ViewMapPage(userMapId: maps[index].id)));
                  },
                  onLongPress: () {
                    _showPopupMenu(context, k).then((option) {
                      if (option == 1) {
                        final userMap = maps[index];
                        _showTitleDialog(context).then((title) {
                          if (title != null && !title.isEmpty)
                            UserMapService.update(
                                UserMap(title, userMap.places, userMap.id));
                        });
                      } else if (option == 2) {
                        UserMapService.delete(maps[index].id!);
                      }
                    });
                  },
                );
              });
        });
  }
}

Future<String?> _showTitleDialog(BuildContext context) {
  final formKey = GlobalKey<FormState>();
  String title = '';
  return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('title for the new map'),
          insetPadding: const EdgeInsets.symmetric(horizontal: 40.0),
          titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <TextFormField>[
                TextFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'title',
                    ),
                    onChanged: (val) => title = val,
                    validator: Utils.emptyCheck)
              ],
            ),
          ),
          actions: <TextButton>[
            TextButton(
              onPressed: () => Navigator.pop<String>(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop<String>(context, title);
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      });
}

Future<int?> _showPopupMenu(BuildContext context, GlobalKey key) {
  final renderBox = (key.currentContext!.findRenderObject())! as RenderBox;
  final targetPosition = renderBox.localToGlobal(Offset.zero);
  final targetSize = renderBox.size;
  final rect = targetPosition & targetSize;
  final menuEntries = <PopupMenuEntry<int>>[
    const PopupMenuItem<int>(
      value: 1,
      child: Text('edit'),
    ),
    const PopupMenuDivider(),
    const PopupMenuItem<int>(
      value: 2,
      child: Text('remove'),
    )
  ];
  double menuHeight = 0;
  for (var e in menuEntries) menuHeight += e.height;
  final menuPosition = RelativeRect.fromLTRB(rect.left + 16, rect.top + 16,
      rect.right - 16, rect.top + 16 + menuHeight);
  return showMenu<int>(
      context: context, position: menuPosition, items: menuEntries);
}
