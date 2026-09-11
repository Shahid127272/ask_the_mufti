import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_scaffold.dart';

import '../../providers/font_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notification_provider.dart';

import '../../services/auth_service.dart';

import '../donation/donation_screen.dart';
import '../profile/profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  bool dataSaver = false;
  String language = "English";

  List<DropdownMenuItem<String>> fontItems() {
    return const [

      DropdownMenuItem(value: "Inter", child: Text("Inter")),
      DropdownMenuItem(value: "OpenSans", child: Text("Open Sans")),
      DropdownMenuItem(value: "Roboto", child: Text("Roboto")),
      DropdownMenuItem(value: "Norwester", child: Text("Norwester")),
      DropdownMenuItem(value: "PatrickHand", child: Text("Patrick Hand")),
      DropdownMenuItem(value: "Playfair", child: Text("Playfair")),

    ];
  }

  Widget settingsCard(List<Widget> children) {

    final theme = Theme.of(context);

    return Card(

      color: theme.colorScheme.surface,

      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    final fonts = context.watch<FontProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final notifications = context.watch<NotificationProvider>();

    return AppScaffold(

      notificationCount: 0,

      body: ListView(
        children: [

          /// PROFILE
          settingsCard([
            ListTile(
              leading: Icon(
                Icons.person_outline,
                color: theme.iconTheme.color,
              ),
              title: Text(
                "Profile",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontFamily: fonts.uiFont),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.iconTheme.color,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ]),

          /// FONT SETTINGS
          settingsCard([

            ExpansionTile(
              leading: Icon(
                Icons.text_fields,
                color: theme.iconTheme.color,
              ),

              title: Text(
                "Font Settings",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontFamily: fonts.uiFont),
              ),

              children: [

                ListTile(
                  leading: Icon(
                    Icons.restart_alt,
                    color: theme.iconTheme.color,
                  ),
                  title: Text(
                    "Reset to Default",
                    style: theme.textTheme.bodyMedium,
                  ),
                  onTap: () {
                    context.read<FontProvider>().resetFonts();
                  },
                ),

                Divider(color: theme.dividerColor),

                ListTile(
                  title: Text(
                    "Question Font",
                    style: theme.textTheme.bodyMedium,
                  ),
                  trailing: DropdownButton<String>(
                    value: fonts.questionFont,
                    underline: const SizedBox(),
                    items: fontItems(),
                    onChanged: (value) {
                      context.read<FontProvider>().setQuestionFont(value!);
                    },
                  ),
                ),

                ListTile(
                  title: Text(
                    "Answer Font",
                    style: theme.textTheme.bodyMedium,
                  ),
                  trailing: DropdownButton<String>(
                    value: fonts.answerFont,
                    underline: const SizedBox(),
                    items: fontItems(),
                    onChanged: (value) {
                      context.read<FontProvider>().setAnswerFont(value!);
                    },
                  ),
                ),

                ListTile(
                  title: Text(
                    "UI Font",
                    style: theme.textTheme.bodyMedium,
                  ),
                  trailing: DropdownButton<String>(
                    value: fonts.uiFont,
                    underline: const SizedBox(),
                    items: fontItems(),
                    onChanged: (value) {
                      context.read<FontProvider>().setUIFont(value!);
                    },
                  ),
                ),

                ListTile(
                  title: Text(
                    "Heading Font",
                    style: theme.textTheme.bodyMedium,
                  ),
                  trailing: DropdownButton<String>(
                    value: fonts.headingFont,
                    underline: const SizedBox(),
                    items: fontItems(),
                    onChanged: (value) {
                      context.read<FontProvider>().setHeadingFont(value!);
                    },
                  ),
                ),

                Divider(color: theme.dividerColor),

                ListTile(
                  title: Text(
                    "Font Size",
                    style: theme.textTheme.bodyMedium,
                  ),
                  subtitle: Slider(
                    value: fonts.fontSize,
                    min: 12,
                    max: 28,
                    divisions: 8,
                    label: fonts.fontSize.toString(),
                    onChanged: (value) {
                      context.read<FontProvider>().setFontSize(value);
                    },
                  ),
                ),

              ],
            ),

          ]),

          /// THEME
          settingsCard([
            ListTile(
              leading: Icon(
                Icons.dark_mode,
                color: theme.iconTheme.color,
              ),
              title: Text(
                "Theme",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontFamily: fonts.uiFont),
              ),
              trailing: DropdownButton<String>(
                value: themeProvider.themeMode.name,
                underline: const SizedBox(),
                items: const [

                  DropdownMenuItem(
                    value: "system",
                    child: Text("System"),
                  ),

                  DropdownMenuItem(
                    value: "light",
                    child: Text("Light"),
                  ),

                  DropdownMenuItem(
                    value: "dark",
                    child: Text("Dark"),
                  ),

                ],
                onChanged: (value) {
                  context.read<ThemeProvider>().setTheme(value!);
                },
              ),
            ),
          ]),

          /// NOTIFICATIONS
          settingsCard([

            SwitchListTile(
              secondary: Icon(
                Icons.question_answer,
                color: theme.iconTheme.color,
              ),
              title: Text(
                "New Question Alerts",
                style: theme.textTheme.bodyMedium,
              ),
              value: notifications.questionAlerts,
              onChanged: (v) {
                context.read<NotificationProvider>().setQuestionAlerts(v);
              },
            ),

            Divider(color: theme.dividerColor),

            SwitchListTile(
              secondary: Icon(
                Icons.check_circle,
                color: theme.iconTheme.color,
              ),
              title: Text(
                "New Answer Alerts",
                style: theme.textTheme.bodyMedium,
              ),
              value: notifications.answerAlerts,
              onChanged: (v) {
                context.read<NotificationProvider>().setAnswerAlerts(v);
              },
            ),

            Divider(color: theme.dividerColor),

            SwitchListTile(
              secondary: Icon(
                Icons.admin_panel_settings,
                color: theme.iconTheme.color,
              ),
              title: Text(
                "Admin Messages",
                style: theme.textTheme.bodyMedium,
              ),
              value: notifications.adminMessages,
              onChanged: (v) {
                context.read<NotificationProvider>().setAdminMessages(v);
              },
            ),

          ]),

          /// LANGUAGE
          settingsCard([
            ListTile(
              leading: Icon(
                Icons.language,
                color: theme.iconTheme.color,
              ),
              title: Text(
                "Language",
                style: theme.textTheme.bodyMedium,
              ),
              trailing: DropdownButton<String>(
                value: language,
                underline: const SizedBox(),
                items: const [

                  DropdownMenuItem(
                    value: "English",
                    child: Text("English"),
                  ),

                  DropdownMenuItem(
                    value: "Urdu",
                    child: Text("Urdu"),
                  ),

                  DropdownMenuItem(
                    value: "Arabic",
                    child: Text("Arabic"),
                  ),

                ],
                onChanged: (v) {
                  setState(() {
                    language = v!;
                  });
                },
              ),
            ),
          ]),

          /// DATA SAVER
          settingsCard([
            SwitchListTile(
              secondary: Icon(
                Icons.data_usage,
                color: theme.iconTheme.color,
              ),
              title: Text(
                "Data Saver",
                style: theme.textTheme.bodyMedium,
              ),
              value: dataSaver,
              onChanged: (v) {
                setState(() {
                  dataSaver = v;
                });
              },
            ),
          ]),

          /// VERSION
          settingsCard([
            ListTile(
              leading: Icon(
                Icons.info,
                color: theme.iconTheme.color,
              ),
              title: Text(
                "App Version",
                style: theme.textTheme.bodyMedium,
              ),
              subtitle: Text(
                "1.0.0",
                style: theme.textTheme.bodySmall,
              ),
              trailing: TextButton(
                child: Text(
                  "Check Update",
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "App is up to date",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  );
                },
              ),
            ),
          ]),

          /// DONATE
          settingsCard([
            ListTile(
              leading: Icon(
                Icons.volunteer_activism,
                color: theme.iconTheme.color,
              ),
              title: Text(
                "Support / Donate",
                style: theme.textTheme.bodyMedium,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DonationScreen(),
                  ),
                );
              },
            ),
          ]),

          /// LOGOUT
          settingsCard([
            ListTile(
              leading: Icon(
                Icons.logout,
                color: theme.colorScheme.error,
              ),
              title: Text(
                "Logout",
                style: TextStyle(
                  color: theme.colorScheme.error,
                ),
              ),
              onTap: () {
                AuthService().logout();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ]),

          const SizedBox(height: 20),

        ],
      ),
    );
  }
}