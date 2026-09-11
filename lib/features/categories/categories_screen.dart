import 'package:flutter/material.dart';

import '../../core/app_scaffold.dart';
import '../../core/theme.dart';
import 'subcategories_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  // =========================================================
  // 📚 ALL CATEGORIES
  // =========================================================

  static const List<Map<String, dynamic>> categories = [
    {
      'id': 'Aqaaid',
      'title': 'Aqaaid',
      'icon': Icons.mosque_rounded,
    },
    {
      'id': 'Ibaadaat',
      'title': 'Ibaadaat',
      'icon': Icons.pan_tool_alt_rounded,
    },
    {
      'id': 'Munakahaat',
      'title': 'Munakahaat',
      'icon': Icons.favorite_rounded,
    },
    {
      'id': 'Muamalaat',
      'title': 'Muamalaat',
      'icon': Icons.handshake_rounded,
    },
    {
      'id': 'Imamat',
      'title': 'Imamat',
      'icon': Icons.people_alt_rounded,
    },
    {
      'id': 'Tahaaraat',
      'title': 'Tahaaraat',
      'icon': Icons.water_drop_rounded,
    },
    {
      'id': 'Quran-o-Tafseer',
      'title': "Qur'an-o-Tafseer",
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 'Hadees-o-Seerat',
      'title': 'Hadees-o-Seerat',
      'icon': Icons.auto_stories_rounded,
    },
    {
      'id': 'Akhlaaq-o-Aadaab',
      'title': 'Akhlaaq-o-Aadaab',
      'icon': Icons.favorite_border_rounded,
    },
    {
      'id': 'Wirasat-o-Wasiyyat',
      'title': 'Wirasat-o-Wasiyyat',
      'icon': Icons.account_balance_rounded,
    },
    {
      'id': 'Janaiz-o-Masail',
      'title': 'Janaiz-o-Masail',
      'icon': Icons.local_florist_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark =
        theme.brightness == Brightness.dark;

    return AppScaffold(
      notificationCount: 0,

      body: Container(
        color: isDark
            ? Colors.black
            : const Color(0xFFF5F7F8),

        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            100,
          ),

          itemCount: categories.length,

          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.95,
          ),

          itemBuilder: (context, index) {
            final category = categories[index];

            final categoryId =
            category['id'] as String;

            final categoryTitle =
            category['title'] as String;

            final icon =
            category['icon'] as IconData;

            return _CategoryCard(
              title: categoryTitle,
              icon: icon,
              isDark: isDark,

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SubCategoriesScreen(
                          category: categoryId,
                          title: categoryTitle,
                        ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// =============================================================
// 🟢 CATEGORY CARD
// =============================================================

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius:
        BorderRadius.circular(18),

        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E1E1E)
                : Colors.white,

            borderRadius:
            BorderRadius.circular(18),

            boxShadow: isDark
                ? null
                : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset:
                const Offset(0, 3),
              ),
            ],
          ),

          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,

            children: [
              Icon(
                icon,
                size: 62,
                color: AppTheme.primary,
              ),

              const SizedBox(height: 20),

              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 8,
                ),

                child: Text(
                  title,

                  textAlign: TextAlign.center,

                  maxLines: 2,

                  overflow:
                  TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 17,

                    fontWeight:
                    FontWeight.w600,

                    color: isDark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}