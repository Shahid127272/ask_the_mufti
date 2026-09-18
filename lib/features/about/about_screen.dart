import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_scaffold.dart';
import '../../providers/font_provider.dart';
import '../donation/donation_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fonts = context.watch<FontProvider>();

    final headingFont =
    fonts.resolveFontFamily(fonts.headingFont);

    final uiFont =
    fonts.resolveFontFamily(fonts.uiFont);

    final bodyStyle = TextStyle(
      fontFamily: uiFont,
      fontSize: fonts.fontSize,
      fontWeight: fonts.fontWeight,
      fontStyle:
      fonts.isItalic ? FontStyle.italic : FontStyle.normal,
    );

    final headingStyle = TextStyle(
      fontFamily: headingFont,
      fontWeight: FontWeight.bold,
      fontStyle:
      fonts.isItalic ? FontStyle.italic : FontStyle.normal,
    );

    return AppScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Ask The Mufti',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: headingFont,
                fontWeight: FontWeight.bold,
                fontStyle:
                fonts.isItalic ? FontStyle.italic : FontStyle.normal,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Ask The Mufti is an Islamic question-answer platform where users can ask religious questions and receive authentic guidance from qualified scholars.',
              style: bodyStyle,
            ),

            const SizedBox(height: 24),

            Text(
              'Our Mission',
              style: headingStyle.copyWith(
                fontSize: theme.textTheme.titleLarge?.fontSize,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'To provide a reliable and accessible platform for the Muslim community to seek knowledge and clarify religious matters in light of authentic Islamic teachings.',
              style: bodyStyle,
            ),

            const SizedBox(height: 16),

            Text(
              'Service Description',
              style: headingStyle.copyWith(
                fontSize: theme.textTheme.titleLarge?.fontSize,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Users can post questions across various categories such as Aqaaid, Ibaadaat, and more. Qualified Muftis review and provide detailed answers to help guide users.',
              style: bodyStyle,
            ),

            const SizedBox(height: 24),

            Text(
              'Support Us',
              style: headingStyle.copyWith(
                fontSize: theme.textTheme.titleLarge?.fontSize,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'This project is a community effort. Your support helps us maintain the platform and reach more people with authentic guidance.',
              style: bodyStyle,
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.volunteer_activism),
                label: Text(
                  'Support This Project',
                  style: TextStyle(
                    fontFamily: uiFont,
                    fontSize: fonts.fontSize,
                    fontWeight: fonts.fontWeight,
                    fontStyle: fonts.isItalic
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DonationScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}