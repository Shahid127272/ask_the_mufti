import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/razorpay_service.dart';

class DonationFormScreen extends StatefulWidget {
  const DonationFormScreen({super.key});

  @override
  State<DonationFormScreen> createState() => _DonationFormScreenState();
}

class _DonationFormScreenState extends State<DonationFormScreen> {

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  int _amount = 100;
  bool _hideName = false;

  late RazorpayService _razorpay;

  @override
  void initState() {
    super.initState();

    _razorpay = RazorpayService();

    _razorpay.onSuccess = (response) {
      _saveDonation(response.paymentId ?? '');
    };
  }

  Future<void> _saveDonation(String paymentId) async {

    await FirebaseFirestore.instance.collection("donations").add({
      "name": _name.text,
      "email": _email.text,
      "phone": _phone.text,
      "amount": _amount,
      "paymentId": paymentId,
      "hideName": _hideName,
      "createdAt": Timestamp.now(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Donation successful ❤️")),
    );

    Navigator.pop(context);
  }

  void _startPayment() {

    _razorpay.openCheckout(
      amount: _amount,
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Support Ask The Mufti"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: "Name"),
            ),

            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: "Phone"),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                _amountButton(100),
                _amountButton(500),
                _amountButton(1000),

              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [

                Checkbox(
                  value: _hideName,
                  onChanged: (v){
                    setState(() {
                      _hideName = v!;
                    });
                  },
                ),

                const Text("Hide my name"),

              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: _startPayment,
                child: Text("Donate ₹$_amount"),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _amountButton(int value) {

    return ElevatedButton(
      onPressed: (){
        setState(() {
          _amount = value;
        });
      },
      child: Text("₹$value"),
    );

  }
}