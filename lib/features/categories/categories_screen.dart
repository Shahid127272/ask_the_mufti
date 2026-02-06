import 'package:flutter/material.dart';
import 'subcategories_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  final categories = const [
    {'id': 'aqaaid', 'title': 'Aqaaid'},
    {'id': 'ibaadaat', 'title': 'Ibaadaat'},
    {'id': 'munakahaat', 'title': 'Munakahaat'},
    {'id': 'muamalaat', 'title': 'Muamalaat'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final c = categories[i];

          return ListTile(
            title: Text(c['title']!),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubCategoriesScreen(
                    categoryId: c['id']!,
                    title: c['title']!,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
