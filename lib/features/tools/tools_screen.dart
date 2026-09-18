import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_scaffold.dart';
import '../../routes/app_routes.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  static Widget buildTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        size: 28,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'COMING SOON',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REVIEWS & SUGGESTIONS
  // ============================================================

  Widget _reviewsSuggestionsTile(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(
        Icons.rate_review_outlined,
        size: 28,
        color: colorScheme.primary,
      ),
      title: Text(
        'Reviews & Suggestions',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Rate the app or send us your suggestions',
        style: theme.textTheme.bodyMedium,
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: colorScheme.primary,
      ),
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.reviewsSuggestions,
        );
      },
    );
  }

  // ============================================================
  // SHARE APP
  // ============================================================

  Future<void> _shareApp() async {
    await SharePlus.instance.share(
      ShareParams(
        text:
        'Check out this amazing Islamic app 📱\n\n'
            'Ask The Mufti — Islamic questions and answers.\n\n'
            'Download now and benefit:\n'
            'https://github.com/Shahid127272/ask_the_mufti/releases/latest/download/app-release.apk',
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      body: ListView(
        children: [
          buildTile(
            context: context,
            icon: Icons.calendar_today,
            title: 'Hijri Date',
            subtitle: 'Hijri date information',
          ),

          Divider(
            color: theme.dividerColor,
          ),

          buildTile(
            context: context,
            icon: Icons.brightness_3,
            title: 'Tasbeeh Counter',
            subtitle: 'Digital tasbeeh counter',
          ),

          Divider(
            color: theme.dividerColor,
          ),

          buildTile(
            context: context,
            icon: Icons.water_drop,
            title: 'Wudu Guide',
            subtitle: 'Step by step wudu method',
          ),

          Divider(
            color: theme.dividerColor,
          ),

          buildTile(
            context: context,
            icon: Icons.mosque,
            title: 'Prayer Rakats',
            subtitle: 'Rakat guide for 5 daily prayers',
          ),

          Divider(
            color: theme.dividerColor,
          ),

          buildTile(
            context: context,
            icon: Icons.explore,
            title: 'Qibla Direction',
            subtitle: 'Find Qibla direction',
          ),

          Divider(
            color: theme.dividerColor,
          ),

          buildTile(
            context: context,
            icon: Icons.location_on,
            title: 'Masjid Finder',
            subtitle: 'Find nearby masjids',
          ),

          Divider(
            color: theme.dividerColor,
          ),

          buildTile(
            context: context,
            icon: Icons.calculate,
            title: 'Zakat Calculator',
            subtitle: 'Calculate your zakat easily',
          ),

          Divider(
            color: theme.dividerColor,
          ),

          // ====================================================
          // REVIEWS & SUGGESTIONS
          // ====================================================

          _reviewsSuggestionsTile(context),

          Divider(
            color: theme.dividerColor,
          ),

          // ====================================================
          // SHARE TO FRIENDS
          // ====================================================

          ListTile(
            leading: Icon(
              Icons.share,
              size: 28,
              color: colorScheme.primary,
            ),
            title: Text(
              'Share to Friends',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Invite your friends to use this app',
              style: theme.textTheme.bodyMedium,
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: colorScheme.primary,
            ),
            onTap: _shareApp,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}