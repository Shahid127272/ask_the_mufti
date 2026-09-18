import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../core/app_scaffold.dart';
import '../../providers/font_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../services/settings_service.dart';
import '../../services/update_download_service.dart';
import '../../services/update_service.dart';

import '../profile/profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = "Loading...";
  bool _checkingUpdate = false;

  int _questionColor = SettingsService.defaultQuestionColor;
  int _answerColor = SettingsService.defaultAnswerColor;

  bool _questionColorSystem = true;
  bool _answerColorSystem = true;

  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  final UpdateService _updateService = UpdateService();

  final UpdateDownloadService _updateDownloadService =
  UpdateDownloadService();

  @override
  void initState() {
    super.initState();

    _loadAppVersion();
    _loadReadingSettings();
  }

  // ============================================================
  // LOAD APP VERSION
  // ============================================================

  Future<void> _loadAppVersion() async {
    try {
      final PackageInfo packageInfo =
      await PackageInfo.fromPlatform();

      if (!mounted) return;

      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _appVersion = "Unknown";
      });
    }
  }

  // ============================================================
  // LOAD READING SETTINGS
  // ============================================================

  Future<void> _loadReadingSettings() async {
    final questionColor =
    await SettingsService.getQuestionColor();

    final answerColor =
    await SettingsService.getAnswerColor();

    final questionSystem =
    await SettingsService.isQuestionColorSystem();

    final answerSystem =
    await SettingsService.isAnswerColorSystem();

    if (!mounted) return;

    setState(() {
      _questionColor = questionColor;
      _answerColor = answerColor;
      _questionColorSystem = questionSystem;
      _answerColorSystem = answerSystem;
    });
  }

  // ============================================================
  // CHECK FOR UPDATE
  // ============================================================

  Future<void> _checkForUpdate() async {
    if (_checkingUpdate) return;

    setState(() {
      _checkingUpdate = true;
    });

    try {
      final UpdateInfo updateInfo =
      await _updateService.checkForUpdate(
        _appVersion,
      );

      if (!mounted) return;

      if (updateInfo.updateAvailable) {
        await _showUpdateAvailableDialog(
          updateInfo,
        );
      } else {
        _showMessage(
          "You are using the latest version "
              "(${updateInfo.currentVersion}).",
        );
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        "Could not check for updates. Please try again.",
      );
    } finally {
      if (mounted) {
        setState(() {
          _checkingUpdate = false;
        });
      }
    }
  }

  // ============================================================
  // UPDATE AVAILABLE DIALOG
  // ============================================================

  Future<void> _showUpdateAvailableDialog(
      UpdateInfo updateInfo,
      ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.system_update,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Update Available",
                ),
              ),
            ],
          ),
          content: Text(
            "A new version of Ask The Mufti is available.\n\n"
                "Current version: "
                "${updateInfo.currentVersion}\n"
                "Latest version: "
                "${updateInfo.latestVersion}\n\n"
                "Would you like to download the latest APK?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text("Later"),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                await _downloadUpdate(
                  updateInfo.downloadUrl,
                );
              },
              child: const Text(
                "Download Update",
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DOWNLOAD UPDATE
  // ============================================================

  Future<void> _downloadUpdate(
      String url,
      ) async {
    if (!mounted) return;

    final String? filePath =
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _DownloadProgressDialog(
          downloadUrl: url,
          downloadService: _updateDownloadService,
        );
      },
    );

    if (!mounted) return;

    if (filePath == null || filePath.isEmpty) {
      _showMessage(
        "Update download failed. Please try again.",
      );
      return;
    }

    await _showInstallUpdateDialog(
      filePath,
    );
  }

  // ============================================================
  // INSTALL UPDATE DIALOG
  // ============================================================

  Future<void> _showInstallUpdateDialog(
      String filePath,
      ) async {
    if (!mounted) return;

    final bool? installNow =
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.install_mobile,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Update Ready",
                ),
              ),
            ],
          ),
          content: const Text(
            "The latest update has been downloaded.\n\n"
                "Would you like to install it now?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(false);
              },
              child: const Text("Later"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true);
              },
              child: const Text(
                "Install Now",
              ),
            ),
          ],
        );
      },
    );

    if (installNow != true) return;

    try {
      final bool opened =
      await _updateDownloadService
          .installUpdate(filePath);

      if (!opened && mounted) {
        _showMessage(
          "Could not open the APK installer.",
        );
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        "Could not start the APK installation.",
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  // ============================================================
  // FONT ITEMS
  // ============================================================

  List<DropdownMenuItem<String>> fontItems() {
    return FontProvider.availableFonts
        .map(
          (font) {
        String label;

        switch (font) {
          case FontProvider.systemDefault:
            label = "System Default";
            break;

          case "OpenSans":
            label = "Open Sans";
            break;

          case "PatrickHand":
            label = "Patrick Hand";
            break;

          case "PrimeNordic":
            label = "Prime Nordic";
            break;

          case "TaoBaso":
            label = "Tao Baso";
            break;

          case "SanToremi":
            label = "San Toremi";
            break;

          case "BiotripSerifCaps":
            label = "Biotrip Serif Caps";
            break;

          default:
            label = font;
        }

        return DropdownMenuItem<String>(
          value: font,
          child: Text(
            label,
            style: font ==
                FontProvider.systemDefault
                ? null
                : TextStyle(
              fontFamily: font,
            ),
          ),
        );
      },
    )
        .toList();
  }

  // ============================================================
  // FONT WEIGHT ITEMS
  // ============================================================

  List<DropdownMenuItem<FontWeight>>
  fontWeightItems() {
    return const [
      DropdownMenuItem(
        value: FontWeight.w300,
        child: Text("Light"),
      ),
      DropdownMenuItem(
        value: FontWeight.w400,
        child: Text("Regular"),
      ),
      DropdownMenuItem(
        value: FontWeight.w500,
        child: Text("Medium"),
      ),
      DropdownMenuItem(
        value: FontWeight.w600,
        child: Text("Semi Bold"),
      ),
      DropdownMenuItem(
        value: FontWeight.w700,
        child: Text("Bold"),
      ),
      DropdownMenuItem(
        value: FontWeight.w800,
        child: Text("Extra Bold"),
      ),
    ];
  }

  // ============================================================
  // SETTINGS CARD
  // ============================================================

  Widget settingsCard(
      List<Widget> children,
      ) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget sectionTitle(
      String title,
      IconData icon,
      ) {
    final theme = Theme.of(context);
    final fonts =
    context.read<FontProvider>();

    return ListTile(
      leading: Icon(
        icon,
        color: theme.colorScheme.primary,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium
            ?.copyWith(
          fontFamily: fonts.uiFont ==
              FontProvider.systemDefault
              ? null
              : fonts.uiFont,
          fontWeight:
          FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // COLOR TILE
  // ============================================================

  Widget colorPreview(
      int colorValue,
      bool systemDefault,
      ) {
    final theme = Theme.of(context);

    final Color previewColor =
    systemDefault
        ? theme.colorScheme.onSurface
        : Color(colorValue);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: previewColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.dividerColor,
        ),
      ),
    );
  }

  // ============================================================
  // COLOR PICKER
  // ============================================================

  Future<void> _pickQuestionColor() async {
    final color =
    await _showColorPicker(
      Color(_questionColor),
    );

    if (color == null) return;

    await SettingsService.setQuestionColor(
      color.toARGB32(),
    );

    if (!mounted) return;

    setState(() {
      _questionColor =
          color.toARGB32();
      _questionColorSystem = false;
    });
  }

  Future<void> _pickAnswerColor() async {
    final color =
    await _showColorPicker(
      Color(_answerColor),
    );

    if (color == null) return;

    await SettingsService.setAnswerColor(
      color.toARGB32(),
    );

    if (!mounted) return;

    setState(() {
      _answerColor =
          color.toARGB32();
      _answerColorSystem = false;
    });
  }

  Future<Color?> _showColorPicker(
      Color initialColor,
      ) async {
    Color selectedColor =
        initialColor;

    return showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        final theme =
        Theme.of(dialogContext);

        final colors = <Color>[
          Colors.black,
          Colors.white,
          Colors.red,
          Colors.pink,
          Colors.orange,
          Colors.amber,
          Colors.yellow,
          Colors.green,
          Colors.teal,
          Colors.cyan,
          Colors.blue,
          Colors.indigo,
          Colors.purple,
          Colors.deepPurple,
          Colors.brown,
          Colors.grey,
        ];

        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                "Choose Color",
              ),
              content: Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration:
                    BoxDecoration(
                      color:
                      selectedColor,
                      shape:
                      BoxShape.circle,
                      border: Border.all(
                        color:
                        theme.dividerColor,
                        width: 2,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                    colors.map(
                          (color) {
                        final selected =
                            selectedColor ==
                                color;

                        return InkWell(
                          onTap: () {
                            setDialogState(
                                  () {
                                selectedColor =
                                    color;
                              },
                            );
                          },
                          borderRadius:
                          BorderRadius
                              .circular(
                            30,
                          ),
                          child:
                          Container(
                            width: 42,
                            height: 42,
                            decoration:
                            BoxDecoration(
                              color: color,
                              shape:
                              BoxShape
                                  .circle,
                              border:
                              Border.all(
                                color: selected
                                    ? theme
                                    .colorScheme
                                    .primary
                                    : theme
                                    .dividerColor,
                                width:
                                selected
                                    ? 3
                                    : 1,
                              ),
                            ),
                            child: selected
                                ? const Icon(
                              Icons
                                  .check,
                              color: Colors
                                  .white,
                            )
                                : null,
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child:
                  const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop(
                      selectedColor,
                    );
                  },
                  child:
                  const Text("Apply"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // RESET READING SETTINGS
  // ============================================================

  Future<void> _resetReadingSettings() async {
    await SettingsService
        .resetReadingSettings();

    await context
        .read<FontProvider>()
        .resetFonts();

    await _loadReadingSettings();

    if (!mounted) return;

    _showMessage(
      "Reading settings reset.",
    );
  }

  // ============================================================
  // ACCOUNT
  // ============================================================

  Widget _accountSection() {
    final theme = Theme.of(context);
    final fonts =
    context.watch<FontProvider>();

    return settingsCard([
      sectionTitle(
        "Account",
        Icons.person_outline,
      ),
      ListTile(
        leading: Icon(
          Icons.edit_outlined,
          color: theme.iconTheme.color,
        ),
        title: Text(
          "Edit Profile",
          style:
          theme.textTheme.bodyMedium,
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
              const ProfileScreen(),
            ),
          );
        },
      ),
      const Divider(height: 1),
      ListTile(
        leading: Icon(
          Icons.phone_android,
          color: theme.iconTheme.color,
        ),
        title: Text(
          "Phone / Email",
          style:
          theme.textTheme.bodyMedium,
        ),
        subtitle: Text(
          "Manage your login information",
          style:
          theme.textTheme.bodySmall,
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
              const ProfileScreen(),
            ),
          );
        },
      ),
    ]);
  }

  // ============================================================
  // APPEARANCE
  // ============================================================

  Widget _appearanceSection() {
    final theme = Theme.of(context);
    final fonts =
    context.watch<FontProvider>();
    final themeProvider =
    context.watch<ThemeProvider>();

    return settingsCard([
      sectionTitle(
        "Appearance",
        Icons.palette_outlined,
      ),

      // --------------------------------------------------------
      // THEME
      // --------------------------------------------------------

      ListTile(
        leading: Icon(
          Icons.dark_mode_outlined,
          color: theme.iconTheme.color,
        ),
        title: Text(
          "Theme",
          style: theme.textTheme.bodyMedium,
        ),
        trailing:
        DropdownButton<String>(
          value:
          themeProvider.themeMode.name,
          underline:
          const SizedBox(),
          items: const [
            DropdownMenuItem(
              value: "system",
              child: Text(
                "System Default",
              ),
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
            if (value == null) return;

            context
                .read<ThemeProvider>()
                .setTheme(value);
          },
        ),
      ),

      const Divider(height: 1),

      // --------------------------------------------------------
      // FONT FAMILY
      // --------------------------------------------------------

      ListTile(
        leading: Icon(
          Icons.font_download_outlined,
          color: theme.iconTheme.color,
        ),
        title: Text(
          "Font Family",
          style: theme.textTheme.bodyMedium,
        ),
        trailing:
        DropdownButton<String>(
          value: fonts.uiFont,
          underline:
          const SizedBox(),
          items: fontItems(),
          onChanged: (value) {
            if (value == null) return;

            context
                .read<FontProvider>()
                .setUIFont(value);
          },
        ),
      ),

      const Divider(height: 1),

      // --------------------------------------------------------
      // FONT SIZE
      // --------------------------------------------------------

      ListTile(
        leading: Icon(
          Icons.format_size,
          color: theme.iconTheme.color,
        ),
        title: Text(
          "Font Size",
          style: theme.textTheme.bodyMedium,
        ),
        subtitle: Row(
          children: [
            IconButton(
              tooltip:
              "Decrease font size",
              onPressed:
              fonts.fontSize <= 12
                  ? null
                  : () {
                context
                    .read<
                    FontProvider>()
                    .decreaseFontSize();
              },
              icon: const Icon(
                Icons.remove,
              ),
            ),
            Expanded(
              child: Slider(
                value: fonts.fontSize,
                min: 12,
                max: 28,
                divisions: 16,
                label:
                fonts.fontSize
                    .toStringAsFixed(
                  0,
                ),
                onChanged: (value) {
                  context
                      .read<FontProvider>()
                      .setFontSize(
                    value,
                  );
                },
              ),
            ),
            IconButton(
              tooltip:
              "Increase font size",
              onPressed:
              fonts.fontSize >= 28
                  ? null
                  : () {
                context
                    .read<
                    FontProvider>()
                    .increaseFontSize();
              },
              icon: const Icon(
                Icons.add,
              ),
            ),
          ],
        ),
      ),

      const Divider(height: 1),

      // --------------------------------------------------------
      // FONT WEIGHT
      // --------------------------------------------------------

      ListTile(
        leading: Icon(
          Icons.format_bold,
          color: theme.iconTheme.color,
        ),
        title: Text(
          "Font Weight",
          style: theme.textTheme.bodyMedium,
        ),
        trailing:
        DropdownButton<FontWeight>(
          value: fonts.fontWeight,
          underline:
          const SizedBox(),
          items:
          fontWeightItems(),
          onChanged: (value) {
            if (value == null) return;

            context
                .read<FontProvider>()
                .setFontWeight(
              value,
            );
          },
        ),
      ),

      const Divider(height: 1),

      // --------------------------------------------------------
      // ITALIC
      // --------------------------------------------------------

      SwitchListTile(
        secondary: Icon(
          Icons.format_italic,
          color: theme.iconTheme.color,
        ),
        title: Text(
          "Italic",
          style: theme.textTheme.bodyMedium,
        ),
        value: fonts.isItalic,
        onChanged: (value) {
          context
              .read<FontProvider>()
              .setItalic(value);
        },
      ),
    ]);
  }

  // ============================================================
  // READING
  // ============================================================

  Widget _readingSection() {
    final theme = Theme.of(context);

    return settingsCard([
      sectionTitle(
        "Reading",
        Icons.menu_book_outlined,
      ),

      // --------------------------------------------------------
      // QUESTION COLOR
      // --------------------------------------------------------

      ListTile(
        leading: Icon(
          Icons.help_outline,
          color: theme.iconTheme.color,
        ),
        title: const Text(
          "Question Color",
        ),
        subtitle: Text(
          _questionColorSystem
              ? "System Default"
              : "Custom Color",
        ),
        trailing: Row(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            colorPreview(
              _questionColor,
              _questionColorSystem,
            ),
            const SizedBox(
              width: 8,
            ),
            IconButton(
              tooltip:
              "Choose question color",
              onPressed:
              _pickQuestionColor,
              icon: const Icon(
                Icons.colorize,
              ),
            ),
          ],
        ),
        onTap: _pickQuestionColor,
      ),

      const Divider(height: 1),

      // --------------------------------------------------------
      // QUESTION SYSTEM DEFAULT
      // --------------------------------------------------------

      RadioListTile<bool>(
        title: const Text(
          "System Default",
        ),
        value: true,
        groupValue:
        _questionColorSystem,
        onChanged: (value) async {
          if (value == null) return;

          await SettingsService
              .setQuestionColorSystem(
            true,
          );

          if (!mounted) return;

          setState(() {
            _questionColorSystem =
            true;
          });
        },
      ),

      RadioListTile<bool>(
        title: const Text(
          "Custom Color",
        ),
        value: false,
        groupValue:
        _questionColorSystem,
        onChanged: (value) async {
          if (value == null) return;

          if (value == false) {
            await _pickQuestionColor();
          }
        },
      ),

      const Divider(height: 1),

      // --------------------------------------------------------
      // ANSWER COLOR
      // --------------------------------------------------------

      ListTile(
        leading: Icon(
          Icons.question_answer_outlined,
          color: theme.iconTheme.color,
        ),
        title: const Text(
          "Answer Color",
        ),
        subtitle: Text(
          _answerColorSystem
              ? "System Default"
              : "Custom Color",
        ),
        trailing: Row(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            colorPreview(
              _answerColor,
              _answerColorSystem,
            ),
            const SizedBox(
              width: 8,
            ),
            IconButton(
              tooltip:
              "Choose answer color",
              onPressed:
              _pickAnswerColor,
              icon: const Icon(
                Icons.colorize,
              ),
            ),
          ],
        ),
        onTap: _pickAnswerColor,
      ),

      const Divider(height: 1),

      // --------------------------------------------------------
      // ANSWER SYSTEM DEFAULT
      // --------------------------------------------------------

      RadioListTile<bool>(
        title: const Text(
          "System Default",
        ),
        value: true,
        groupValue:
        _answerColorSystem,
        onChanged: (value) async {
          if (value == null) return;

          await SettingsService
              .setAnswerColorSystem(
            true,
          );

          if (!mounted) return;

          setState(() {
            _answerColorSystem =
            true;
          });
        },
      ),

      RadioListTile<bool>(
        title: const Text(
          "Custom Color",
        ),
        value: false,
        groupValue:
        _answerColorSystem,
        onChanged: (value) async {
          if (value == null) return;

          if (value == false) {
            await _pickAnswerColor();
          }
        },
      ),

      const Divider(height: 1),

      ListTile(
        leading: Icon(
          Icons.restart_alt,
          color: theme.iconTheme.color,
        ),
        title: const Text(
          "Reset Reading Settings",
        ),
        subtitle: const Text(
          "Reset fonts, size, weight, italic and colors",
        ),
        onTap:
        _resetReadingSettings,
      ),
    ]);
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Widget _notificationsSection() {
    final theme = Theme.of(context);

    final notifications =
    context.watch<
        NotificationProvider>();

    final bool masterNotifications =
        notifications.questionAlerts ||
            notifications.answerAlerts ||
            notifications.adminMessages;

    return settingsCard([
      sectionTitle(
        "Notifications",
        Icons.notifications_outlined,
      ),

      // --------------------------------------------------------
      // MASTER NOTIFICATIONS
      // --------------------------------------------------------

      SwitchListTile(
        secondary: Icon(
          Icons.notifications_active_outlined,
          color: theme.iconTheme.color,
        ),
        title: const Text(
          "Notifications",
        ),
        subtitle: const Text(
          "Enable or disable notification alerts",
        ),
        value: masterNotifications,
        onChanged: (value) {
          final provider = context
              .read<
              NotificationProvider>();

          provider.setQuestionAlerts(
            value,
          );

          provider.setAnswerAlerts(
            value,
          );

          provider.setAdminMessages(
            value,
          );
        },
      ),

      const Divider(height: 1),

      // --------------------------------------------------------
      // NEW ANSWER
      // --------------------------------------------------------

      SwitchListTile(
        secondary: Icon(
          Icons.check_circle_outline,
          color: theme.iconTheme.color,
        ),
        title: const Text(
          "New Answer",
        ),
        value:
        notifications.answerAlerts,
        onChanged: (value) {
          context
              .read<NotificationProvider>()
              .setAnswerAlerts(
            value,
          );
        },
      ),

      const Divider(height: 1),

      // --------------------------------------------------------
      // GENERAL
      // --------------------------------------------------------

      SwitchListTile(
        secondary: Icon(
          Icons.campaign_outlined,
          color: theme.iconTheme.color,
        ),
        title: const Text(
          "General Notifications",
        ),
        value:
        notifications.adminMessages,
        onChanged: (value) {
          context
              .read<NotificationProvider>()
              .setAdminMessages(
            value,
          );
        },
      ),

      const Divider(height: 1),

      // --------------------------------------------------------
      // SOUND
      // --------------------------------------------------------

      SwitchListTile(
        secondary: Icon(
          Icons.volume_up_outlined,
          color: theme.iconTheme.color,
        ),
        title: const Text(
          "Sound",
        ),
        value: _soundEnabled,
        onChanged: (value) {
          setState(() {
            _soundEnabled = value;
          });

          _showMessage(
            "Sound preference saved for this session.",
          );
        },
      ),

      const Divider(height: 1),

      // --------------------------------------------------------
      // VIBRATION
      // --------------------------------------------------------

      SwitchListTile(
        secondary: Icon(
          Icons.vibration,
          color: theme.iconTheme.color,
        ),
        title: const Text(
          "Vibration",
        ),
        value: _vibrationEnabled,
        onChanged: (value) {
          setState(() {
            _vibrationEnabled =
                value;
          });

          _showMessage(
            "Vibration preference saved for this session.",
          );
        },
      ),
    ]);
  }

  // ============================================================
  // PRIVACY & SECURITY
  // ============================================================

  Widget _privacySection() {
    final theme = Theme.of(context);

    return settingsCard([
      sectionTitle(
        "Privacy & Security",
        Icons.security_outlined,
      ),

      ListTile(
        leading: Icon(
          Icons.privacy_tip_outlined,
          color: theme.iconTheme.color,
        ),
        title: const Text(
          "Privacy Policy",
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: () {
          _showInfoDialog(
            "Privacy Policy",
            "Privacy Policy content can be added here.",
          );
        },
      ),

      const Divider(height: 1),

      ListTile(
        leading: Icon(
          Icons.description_outlined,
          color: theme.iconTheme.color,
        ),
        title: const Text(
          "Terms & Conditions",
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: () {
          _showInfoDialog(
            "Terms & Conditions",
            "Terms & Conditions content can be added here.",
          );
        },
      ),

      const Divider(height: 1),

      ListTile(
        leading: Icon(
          Icons.logout,
          color: theme.colorScheme.error,
        ),
        title: Text(
          "Sign Out",
          style:
          theme.textTheme.bodyMedium
              ?.copyWith(
            color:
            theme.colorScheme.error,
          ),
        ),
        onTap:
        _confirmSignOut,
      ),
    ]);
  }

  // ============================================================
  // HELP & SUPPORT
  // ============================================================

  Widget _helpSection() {
    final theme = Theme.of(context);

    return settingsCard([
      sectionTitle(
        "Help & Support",
        Icons.help_outline,
      ),

      ListTile(
        leading: Icon(
          Icons.quiz_outlined,
          color: theme.iconTheme.color,
        ),
        title: const Text(
          "FAQ",
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: () {
          _showInfoDialog(
            "FAQ",
            "Frequently asked questions can be added here.",
          );
        },
      ),

      const Divider(height: 1),

      ListTile(
        leading: Icon(
          Icons.support_agent_outlined,
          color: theme.iconTheme.color,
        ),
        title: const Text(
          "Contact Support",
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: () {
          _showInfoDialog(
            "Contact Support",
            "Support contact details can be added here.",
          );
        },
      ),

      const Divider(height: 1),

      ListTile(
        leading: Icon(
          Icons.bug_report_outlined,
          color: theme.iconTheme.color,
        ),
        title: const Text(
          "Report a Problem",
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: () {
          _showInfoDialog(
            "Report a Problem",
            "Problem reporting can be connected here.",
          );
        },
      ),

      const Divider(height: 1),

      ListTile(
        leading: Icon(
          Icons.lightbulb_outline,
          color: theme.iconTheme.color,
        ),
        title: const Text(
          "Suggest a Feature",
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: () {
          _showInfoDialog(
            "Suggest a Feature",
            "Feature suggestions can be submitted here.",
          );
        },
      ),
    ]);
  }

  // ============================================================
  // ABOUT
  // ============================================================

  Widget _aboutSection() {
    final theme = Theme.of(context);

    return settingsCard([
      sectionTitle(
        "About",
        Icons.info_outline,
      ),

      ListTile(
        leading: Icon(
          Icons.system_update_outlined,
          color: theme.iconTheme.color,
        ),
        title: const Text(
          "Check for Updates",
        ),
        trailing:
        _checkingUpdate
            ? SizedBox(
          width: 24,
          height: 24,
          child:
          CircularProgressIndicator(
            strokeWidth: 2,
            color: theme
                .colorScheme
                .primary,
          ),
        )
            : const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap:
        _checkingUpdate
            ? null
            : _checkForUpdate,
      ),

      const Divider(height: 1),

      ListTile(
        leading: Icon(
          Icons.share_outlined,
          color: theme.iconTheme.color,
        ),
        title: const Text(
          "Share App",
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: () {
          _showInfoDialog(
            "Share App",
            "App sharing can be connected here.",
          );
        },
      ),

      const Divider(height: 1),

      ListTile(
        leading: Icon(
          Icons.apps_outlined,
          color: theme.iconTheme.color,
        ),
        title: const Text(
          "About Ask The Mufti",
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: () {
          _showInfoDialog(
            "About Ask The Mufti",
            "Ask The Mufti is an Islamic Q&A application.",
          );
        },
      ),

      const Divider(height: 1),

      ListTile(
        leading: Icon(
          Icons.info_outline,
          color: theme.iconTheme.color,
        ),
        title: const Text(
          "App Version",
        ),
        subtitle: Text(
          _appVersion,
        ),
      ),
    ]);
  }

  // ============================================================
  // INFO DIALOG
  // ============================================================

  Future<void> _showInfoDialog(
      String title,
      String message,
      ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
              const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SIGN OUT CONFIRMATION
  // ============================================================

  Future<void> _confirmSignOut() async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Sign Out",
          ),
          content: const Text(
            "Are you sure you want to sign out?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
              const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child:
              const Text("Sign Out"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await AuthService().logout();

    if (!mounted) return;

    Navigator.of(context)
        .popUntil(
          (route) => route.isFirst,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      notificationCount: 0,
      body: ListView(
        padding:
        const EdgeInsets.only(
          top: 6,
          bottom: 20,
        ),
        children: [
          // ======================================================
          // ACCOUNT
          // ======================================================

          _accountSection(),

          // ======================================================
          // APPEARANCE
          // ======================================================

          _appearanceSection(),

          // ======================================================
          // READING
          // ======================================================

          _readingSection(),

          // ======================================================
          // NOTIFICATIONS
          // ======================================================

          _notificationsSection(),

          // ======================================================
          // PRIVACY & SECURITY
          // ======================================================

          _privacySection(),

          // ======================================================
          // HELP & SUPPORT
          // ======================================================

          _helpSection(),

          // ======================================================
          // ABOUT
          // ======================================================

          _aboutSection(),

          const SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// DOWNLOAD PROGRESS DIALOG
// ==================================================================

class _DownloadProgressDialog
    extends StatefulWidget {
  final String downloadUrl;
  final UpdateDownloadService
  downloadService;

  const _DownloadProgressDialog({
    required this.downloadUrl,
    required this.downloadService,
  });

  @override
  State<_DownloadProgressDialog>
  createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState
    extends State<
        _DownloadProgressDialog> {
  double _progress = 0;
  bool _started = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback(
          (_) {
        _startDownload();
      },
    );
  }

  Future<void> _startDownload() async {
    if (_started) return;

    _started = true;

    try {
      final String filePath =
      await widget.downloadService
          .downloadUpdate(
        downloadUrl:
        widget.downloadUrl,
        onProgress:
            (received, total) {
          if (!mounted) return;

          setState(() {
            if (total > 0) {
              _progress =
                  received / total;
            }
          });
        },
      );

      if (!mounted) return;

      Navigator.of(context)
          .pop(filePath);
    } catch (_) {
      if (!mounted) return;

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    final int percentage =
    (_progress * 100)
        .clamp(0, 100)
        .round();

    return AlertDialog(
      title: const Text(
        "Downloading Update",
      ),
      content: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: _progress > 0
                ? _progress
                : null,
            color:
            theme.colorScheme.primary,
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            _progress > 0
                ? "$percentage%"
                : "Starting download...",
            style: theme
                .textTheme
                .bodyMedium,
          ),
        ],
      ),
    );
  }
}