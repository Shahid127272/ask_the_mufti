import 'package:flutter/material.dart';

import '../feeds/feeds_screen.dart';
import '../categories/categories_screen.dart';
import '../my_questions/my_questions_screen.dart';
import '../search/search_screen.dart';
import '../tools/tools_screen.dart';
import '../ask_question/ask_question_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  final PageController _pageController = PageController();

  final List<Widget> _pages = const [
    FeedsScreen(),
    CategoriesScreen(),
    MyQuestionsScreen(),
    SearchScreen(),
    ToolsScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // =========================================================
  // ➕ ASK QUESTION
  // =========================================================

  void _openAskQuestion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AskQuestionScreen(),
      ),
    );
  }

  // =========================================================
  // 🏠 BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,

      // =====================================================
      // 📱 BODY
      // =====================================================

      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _index = index;
          });
        },
        children: _pages,
      ),

      // =====================================================
      // ➕ FLOATING ASK BUTTON
      // =====================================================

      floatingActionButton: FloatingActionButton(
        onPressed: _openAskQuestion,
        tooltip: 'Ask Question',
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add_comment_rounded,
          size: 27,
        ),
      ),

      // =====================================================
      // 📍 ASK BUTTON = TOOLS KE UPAR
      // =====================================================

      floatingActionButtonLocation:
      const _AskAboveToolsLocation(),

      // =====================================================
      // 🔽 BOTTOM NAVIGATION
      // =====================================================

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
        child: BottomAppBar(
          color: colorScheme.surface,
          child: SizedBox(
            height: 65,
            child: Row(
              children: [
                _navItem(
                  icon: Icons.home_rounded,
                  label: 'Feed',
                  index: 0,
                ),
                _navItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Category',
                  index: 1,
                ),
                _navItem(
                  icon: Icons.question_answer_rounded,
                  label: 'My Questions',
                  index: 2,
                ),
                _navItem(
                  icon: Icons.search_rounded,
                  label: 'Search',
                  index: 3,
                ),
                _navItem(
                  icon: Icons.build_circle_rounded,
                  label: 'Tools',
                  index: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // 🔘 NAV ITEM
  // =========================================================

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final active = _index == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_index == index) {
            return;
          }

          setState(() {
            _index = index;
          });

          _pageController.animateToPage(
            index,
            duration: const Duration(
              milliseconds: 250,
            ),
            curve: Curves.easeOut,
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),

            const SizedBox(height: 4),

            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                color: active
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: active
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// ➕ CUSTOM ASK BUTTON LOCATION
//    Tools tab ke exact upar
// =============================================================

class _AskAboveToolsLocation
    extends FloatingActionButtonLocation {
  const _AskAboveToolsLocation();

  @override
  Offset getOffset(
      ScaffoldPrelayoutGeometry geometry,
      ) {
    final scaffoldWidth = geometry.scaffoldSize.width;

    final fabSize = geometry.floatingActionButtonSize;

    // =========================================================
    // TOOLS 5TH NAVIGATION ITEM HAI
    // ISKA CENTER SCREEN WIDTH KA 90% HAI
    // =========================================================

    final toolsCenterX = scaffoldWidth * 0.9;

    final x = toolsCenterX - (fabSize.width / 2);

    // =========================================================
    // BOTTOM NAVIGATION KE UPAR FAB
    // =========================================================

    final y = geometry.contentBottom -
        fabSize.height -
        8;

    return Offset(
      x,
      y,
    );
  }

  @override
  String toString() => '_AskAboveToolsLocation';
}