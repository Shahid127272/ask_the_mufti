import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/razorpay_service.dart';

class DonationScreen extends StatelessWidget {
  const DonationScreen({super.key});

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    final razorpay = RazorpayService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Support This Project"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Support Ask The Mufti",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "Ask The Mufti is a free Islamic service. "
                  "Running this platform requires server costs, SMS verification charges, "
                  "development and maintenance expenses.",
              style: TextStyle(fontSize: 16, height: 1.6),
            ),

            const SizedBox(height: 10),

            const Text(
              "If you benefit from this project, consider supporting it with a donation.",
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 30),

            // -----------------------
            // QUICK DONATION BUTTONS
            // -----------------------

            const Text(
              "Quick Donation",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Row(
              children: [

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      razorpay.openCheckout(
                        amount: 100,
                        name: "Supporter",
                        email: "donor@askthemufti.app",
                        phone: "0000000000",
                      );
                    },
                    child: const Text("₹100"),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      razorpay.openCheckout(
                        amount: 500,
                        name: "Supporter",
                        email: "donor@askthemufti.app",
                        phone: "0000000000",
                      );
                    },
                    child: const Text("₹500"),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      razorpay.openCheckout(
                        amount: 1000,
                        name: "Supporter",
                        email: "donor@askthemufti.app",
                        phone: "0000000000",
                      );
                    },
                    child: const Text("₹1000"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // INDIA DONATION

            _donationCard(
              context,
              title: "Donate from India",
              subtitle: "UPI / Razorpay",
              color: Colors.orange,
              icon: Icons.currency_rupee,
              onTap: () {
                _openLink("https://your-razorpay-link.com");
              },
            ),

            const SizedBox(height: 15),

            // INTERNATIONAL

            _donationCard(
              context,
              title: "International Donation",
              subtitle: "Stripe / PayPal",
              color: Colors.blue,
              icon: Icons.public,
              onTap: () {
                _openLink("https://your-stripe-link.com");
              },
            ),

            const SizedBox(height: 15),

            // BANK TRANSFER

            _donationCard(
              context,
              title: "Bank Transfer",
              subtitle: "Direct bank support",
              color: Colors.green,
              icon: Icons.account_balance,
              onTap: () {
                _openLink("https://your-bank-page.com");
              },
            ),

            const SizedBox(height: 15),

            // MONTHLY SUPPORT

            _donationCard(
              context,
              title: "Monthly Support",
              subtitle: "Become a supporter",
              color: Colors.purple,
              icon: Icons.favorite,
              onTap: () {
                _openLink("https://your-monthly-support-link.com");
              },
            ),

            const SizedBox(height: 30),

            const Divider(),

            const SizedBox(height: 15),

            const Text(
              "Transparency",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "All donations are used strictly for app development, hosting, "
                  "SMS charges, and expanding this Islamic service.",
              style: TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 40),

            const Center(
              child: Text(
                "May Allah reward you for supporting this effort.",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _donationCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required Color color,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}