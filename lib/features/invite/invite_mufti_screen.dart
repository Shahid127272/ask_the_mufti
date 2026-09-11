import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'invite_service.dart';

class InviteMuftiScreen extends StatefulWidget {
  const InviteMuftiScreen({super.key});

  @override
  State<InviteMuftiScreen> createState() => _InviteMuftiScreenState();
}

class _InviteMuftiScreenState extends State<InviteMuftiScreen> {

  final TextEditingController emailController = TextEditingController();
  final InviteService service = InviteService();

  String? inviteLink;

  /// ----------------------------------------
  /// CREATE INVITE
  /// ----------------------------------------

  Future<void> createInvite() async {

    final email = emailController.text.trim();

    if (email.isEmpty || !email.contains("@")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter valid email"),
        ),
      );
      return;
    }

    final id = await service.createInvite(email);

    /// async gap safety
    if (!mounted) return;

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invite already exists"),
        ),
      );
      return;
    }

    setState(() {
      inviteLink = "https://askthemufti.app/invite?id=$id";
    });
  }

  /// ----------------------------------------
  /// OPEN URL
  /// ----------------------------------------

  Future<void> openUrl(String url) async {

    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not open link"),
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
        "You are invited to join Ask The Mufti as Mufti.\n\n$inviteLink";

    final url =
        "https://wa.me/?text=${Uri.encodeComponent(text)}";

    await openUrl(url);
  }

  /// ----------------------------------------
  /// EMAIL
  /// ----------------------------------------

  Future<void> openEmail() async {

    if (inviteLink == null) return;

    final subject = Uri.encodeComponent("Mufti Invitation");
    final body = Uri.encodeComponent(inviteLink!);

    final url = "mailto:?subject=$subject&body=$body";

    await openUrl(url);
  }

  /// ----------------------------------------
  /// SMS
  /// ----------------------------------------

  Future<void> openSMS() async {

    if (inviteLink == null) return;

    final body = Uri.encodeComponent(inviteLink!);

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

    return Scaffold(

      appBar: AppBar(
        title: const Text("Invite Mufti"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: SingleChildScrollView(

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              /// EMAIL FIELD
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Mufti Email",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              /// CREATE INVITE
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: createInvite,
                  child: const Text("Create Invite"),
                ),
              ),

              if (inviteLink != null) ...[

                const SizedBox(height: 30),

                const Text(
                  "Send invitation via",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 10),

                Row(

                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                  children: [

                    IconButton(
                      icon: const Icon(Icons.email),
                      onPressed: openEmail,
                    ),

                    IconButton(
                      icon: const Icon(Icons.sms),
                      onPressed: openSMS,
                    ),

                    IconButton(
                      icon: const Icon(Icons.chat),
                      onPressed: openWhatsApp,
                    ),

                  ],
                ),

                const SizedBox(height: 10),

                SelectableText(
                  inviteLink!,
                  style: const TextStyle(
                    color: Colors.blue,
                  ),
                ),

              ]
            ],
          ),
        ),
      ),
    );
  }
}