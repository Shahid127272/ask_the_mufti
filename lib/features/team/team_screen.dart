import 'package:flutter/material.dart';
import '../../core/app_scaffold.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      notificationCount: 0,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Mufti Ahmad Sahab'),
            subtitle: Text('Darul Ifta – Fiqh & Answer'),
          ),
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Mufti Bilal Sahab'),
            subtitle: Text('Quran & Hadith'),
          ),
        ],
      ),
    );
  }
}