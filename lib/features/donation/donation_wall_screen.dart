import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DonationWallScreen extends StatelessWidget {
  const DonationWallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Supporters"),
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("donations")
            .orderBy("createdAt", descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];

              final name =
              d["hideName"] ? "Anonymous" : d["name"];

              final amount = d["amount"];

              return ListTile(
                leading: Icon(
                  Icons.favorite,
                  color: colorScheme.primary,
                ),
                title: Text(name),
                trailing: Text(
                  "₹$amount",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}