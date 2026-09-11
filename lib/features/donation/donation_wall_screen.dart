import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DonationWallScreen extends StatelessWidget {
  const DonationWallScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Supporters")),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("donations")
            .orderBy("createdAt", descending: true)
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i){

              final d = docs[i];

              final name = d["hideName"] ? "Anonymous" : d["name"];
              final amount = d["amount"];

              return ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: Text(name),
                trailing: Text("₹$amount"),
              );
            },
          );
        },
      ),
    );
  }
}