import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {

  late Razorpay _razorpay;

  // callback for payment success
  Function(PaymentSuccessResponse)? onSuccess;

  RazorpayService() {

    _razorpay = Razorpay();

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_SUCCESS,
      _handlePaymentSuccess,
    );

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_ERROR,
      _handlePaymentError,
    );

    _razorpay.on(
      Razorpay.EVENT_EXTERNAL_WALLET,
      _handleExternalWallet,
    );
  }

  // =============================
  // OPEN CHECKOUT
  // =============================

  void openCheckout({
    required int amount,
    required String name,
    required String email,
    required String phone,
  }) {

    final options = {

      'key': 'rzp_test_SN3BgoYYWTmN8s',

      'amount': amount * 100,

      'name': 'Ask The Mufti',

      'description': 'Support Donation',

      'retry': {
        'enabled': true,
        'max_count': 1
      },

      'prefill': {
        'contact': phone,
        'email': email
      },

      'notes': {
        'donor_name': name
      },

      'external': {
        'wallets': ['paytm']
      }

    };

    try {

      _razorpay.open(options);

    } catch (e) {

      debugPrint("Razorpay Open Error: $e");

    }
  }

  // =============================
  // PAYMENT SUCCESS
  // =============================

  void _handlePaymentSuccess(PaymentSuccessResponse response) {

    debugPrint("PAYMENT SUCCESS");

    debugPrint("Payment ID: ${response.paymentId}");
    debugPrint("Order ID: ${response.orderId}");
    debugPrint("Signature: ${response.signature}");

    // trigger callback to UI
    if (onSuccess != null) {
      onSuccess!(response);
    }
  }

  // =============================
  // PAYMENT FAILED
  // =============================

  void _handlePaymentError(PaymentFailureResponse response) {

    debugPrint("PAYMENT FAILED");

    debugPrint("Error Code: ${response.code}");
    debugPrint("Error Message: ${response.message}");
  }

  // =============================
  // EXTERNAL WALLET
  // =============================

  void _handleExternalWallet(ExternalWalletResponse response) {

    debugPrint("EXTERNAL WALLET USED");

    debugPrint("Wallet Name: ${response.walletName}");
  }

  // =============================
  // DISPOSE
  // =============================

  void dispose() {

    _razorpay.clear();

  }
}