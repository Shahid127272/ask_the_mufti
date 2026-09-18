import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/invite_service.dart';

class InviteMuftiScreen extends StatefulWidget {
  const InviteMuftiScreen({super.key});

  @override
  State<InviteMuftiScreen> createState() => _InviteMuftiScreenState();
}

class _InviteMuftiScreenState extends State<InviteMuftiScreen> {
  final TextEditingController emailController =
  TextEditingController();

  final InviteService service = InviteService();

  String? inviteLink;
  String? invitedEmail;
  bool _loading = false;

  /// ----------------------------------------
  /// CREATE INVITE
  /// ----------------------------------------

  Future<void> createInvite() async {
    final email = emailController.text.trim().toLowerCase();

    if (email.isEmpty || !email.contains("@")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Enter valid email"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_loading) return;

    setState(() {
      _loading = true;
      inviteLink = null;
      invitedEmail = null;
    });

    try {
      final id = await service.createInvite(email);

      if (!mounted) return;

      if (id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Invite already exists"),
            backgroundColor:
            Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      setState(() {
        invitedEmail = email;
        inviteLink =
        "https://askthemufti.app/invite?id=$id";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Mufti invitation created"),
          backgroundColor:
          Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not create invite: $e"),
          backgroundColor:
          Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// ----------------------------------------
  /// OPEN URL
  /// ----------------------------------------

  Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Could not open link"),
          backgroundColor:
          Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// ----------------------------------------
  /// WHATSAPP
  /// ----------------------------------------

  Future<void> openWhatsApp() async {
    if (inviteLink == null) return;

    final text =
        "You are invited to join Ask The Mufti as Mufti.\n\n"
        "Please use this invitation link to sign up:\n"
        "$inviteLink";

    final url =
        "https://wa.me/?text=${Uri.encodeComponent(text)}";

    await openUrl(url);
  }

  /// ----------------------------------------
  /// EMAIL
  /// ----------------------------------------

  Future<void> openEmail() async {
    if (inviteLink == null) return;

    final email =
        invitedEmail ?? emailController.text.trim();

    final subject = Uri.encodeComponent(
      "Invitation to join Ask The Mufti as Mufti",
    );

    final body = Uri.encodeComponent(
      "السلام علیکم ورحمۃ اللہ و برکاتہ,\n\n"
          "You are invited to join Ask The Mufti as a Mufti.\n\n"
          "Please use the following invitation link to sign up "
          "and join as a Mufti:\n\n"
          "$inviteLink\n\n"
          "Download the Ask The Mufti Android app:\n"
          "https://github.com/Shahid127272/ask_the_mufti/releases/latest/download/app-release.apk\n\n"
          "جزاک اللہ خیرا.",
    );

    final url =
        "mailto:$email?subject=$subject&body=$body";

    await openUrl(url);
  }

  /// ----------------------------------------
  /// SMS
  /// ----------------------------------------

  Future<void> openSMS() async {
    if (inviteLink == null) return;

    final body = Uri.encodeComponent(
      "You are invited to join Ask The Mufti as Mufti.\n\n"
          "Please use this invitation link to sign up:\n"
          "$inviteLink",
    );

    final url = "sms:?body=$body";

    await openUrl(url);
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Invite Mufti"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              /// EMAIL FIELD
              TextField(
                controller: emailController,
                keyboardType:
                TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: "Mufti Email",
                  hintText: "Enter Mufti email address",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              /// CREATE INVITE
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                  _loading ? null : createInvite,
                  child: _loading
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                      colorScheme.onPrimary,
                    ),
                  )
                      : Text(
                    "Create Invite",
                    style: TextStyle(
                      color:
                      colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),

              if (inviteLink != null) ...[
                const SizedBox(height: 30),

                Text(
                  "Invitation created",
                  style:
                  textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                if (invitedEmail != null)
                  Text(
                    invitedEmail!,
                    style: textTheme.bodyMedium,
                  ),

                const SizedBox(height: 16),

                Text(
                  "Send invitation via",
                  style:
                  textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      tooltip: "Email",
                      icon: Icon(
                        Icons.email,
                        color: colorScheme.primary,
                      ),
                      onPressed: openEmail,
                    ),
                    IconButton(
                      tooltip: "SMS",
                      icon: Icon(
                        Icons.sms,
                        color: colorScheme.primary,
                      ),
                      onPressed: openSMS,
                    ),
                    IconButton(
                      tooltip: "WhatsApp",
                      icon: Icon(
                        Icons.chat,
                        color: colorScheme.primary,
                      ),
                      onPressed: openWhatsApp,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                SelectableText(
                  inviteLink!,
                  style:
                  textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}