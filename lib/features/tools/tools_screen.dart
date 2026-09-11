import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_scaffold.dart';
import '../../routes/app_routes.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  static Widget buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 28,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
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
            child: const Text(
              'COMING SOON',
              style: TextStyle(
                fontSize: 11,
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

    return ListTile(
      leading: Icon(
        Icons.rate_review_outlined,
        size: 28,
        color: theme.colorScheme.primary,
      ),
      title: Text(
        'Reviews & Suggestions',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: const Text(
        'Rate the app or send us your suggestions',
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: theme.colorScheme.primary,
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
            'https://yourapp.link',
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: ListView(
        children: [
          buildTile(
            icon: Icons.calendar_today,
            title: 'Hijri Date',
            subtitle: 'Hijri date information',
          ),

          const Divider(),

          buildTile(
            icon: Icons.brightness_3,
            title: 'Tasbeeh Counter',
            subtitle: 'Digital tasbeeh counter',
          ),

          const Divider(),

          buildTile(
            icon: Icons.water_drop,
            title: 'Wudu Guide',
            subtitle: 'Step by step wudu method',
          ),

          const Divider(),

          buildTile(
            icon: Icons.mosque,
            title: 'Prayer Rakats',
            subtitle: 'Rakat guide for 5 daily prayers',
          ),

          const Divider(),

          buildTile(
            icon: Icons.explore,
            title: 'Qibla Direction',
            subtitle: 'Find Qibla direction',
          ),

          const Divider(),

          buildTile(
            icon: Icons.location_on,
            title: 'Masjid Finder',
            subtitle: 'Find nearby masjids',
          ),

          const Divider(),

          buildTile(
            icon: Icons.calculate,
            title: 'Zakat Calculator',
            subtitle: 'Calculate your zakat easily',
          ),

          const Divider(),

          // ====================================================
          // REVIEWS & SUGGESTIONS
          // ====================================================

          _reviewsSuggestionsTile(context),

          const Divider(),

          // ====================================================
          // SHARE TO FRIENDS
          // ====================================================

          ListTile(
            leading: const Icon(
              Icons.share,
              size: 28,
            ),
            title: const Text(
              'Share to Friends',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Invite your friends to use this app',
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
            onTap: _shareApp,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}