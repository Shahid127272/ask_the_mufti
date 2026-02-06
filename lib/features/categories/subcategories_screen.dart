import 'package:flutter/material.dart';
import '../feeds/feeds_screen.dart';

class SubCategoriesScreen extends StatelessWidget {
  final String categoryId;
  final String title;

  const SubCategoriesScreen({
    super.key,
    required this.categoryId,
    required this.title,
  });

  static const Map<String, List<String>> subCategories = {
    'aqaaid': [
      'Tawheed',
      'Risalat',
      'Aakhirat',
      'Shafa‘at',
    ],
    'ibaadaat': [
      'Salah',
      'Roza',
      'Zakah',
      'Hajj',
    ],
    'munakahaat': [
      'Nikah',
      'Talaq',
      'Khula',
    ],
    'muamalaat': [
      'Buyu',
      'Qarz',
      'Waqf',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final list = subCategories[categoryId] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, i) {
          return ListTile(
            title: Text(list[i]),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FeedsScreen(
                    category: categoryId,
                    subCategory: list[i],
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
