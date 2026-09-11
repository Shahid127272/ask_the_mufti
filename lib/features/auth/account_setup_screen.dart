import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  final AuthService _auth = AuthService();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _emailPasswordController =
  TextEditingController();

  final TextEditingController _emailConfirmPasswordController =
  TextEditingController();

  final TextEditingController _otpController =
  TextEditingController();

  final TextEditingController _screenNameController =
  TextEditingController();

  // ============================================================
  // PHONE
  // ============================================================

  String _phone = '';
  String? _verificationId;

  // ============================================================
  // STATE
  // ============================================================

  bool _loading = true;

  bool _emailLinked = false;
  bool _emailVerified = false;

  bool _phoneLinked = false;
  bool _phoneVerified = false;

  bool _hideEmailPassword = true;
  bool _hideEmailConfirmPassword = true;

  // 0 = Email
  // 1 = Phone
  // 2 = Screen Name
  int _step = 0;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _emailController.dispose();
    _emailPasswordController.dispose();
    _emailConfirmPasswordController.dispose();
    _otpController.dispose();
    _screenNameController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD CURRENT STATUS
  // ============================================================

  Future<void> _loadCurrentStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      return;
    }

    try {
      await user.reload();
    } catch (e) {
      debugPrint('USER RELOAD ERROR: $e');
    }

    final freshUser = FirebaseAuth.instance.currentUser;

    if (freshUser == null) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      return;
    }

    Map<String, dynamic>? data;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(freshUser.uid)
          .get();

      data = doc.data();
    } catch (e) {
      debugPrint('USER DOCUMENT ERROR: $e');
    }

    // ==========================================================
    // PROVIDERS
    // ==========================================================

    final googleLinked = freshUser.providerData.any(
          (provider) => provider.providerId == 'google.com',
    );

    final emailPasswordLinked = freshUser.providerData.any(
          (provider) => provider.providerId == 'password',
    );

    final phoneProviderLinked = freshUser.providerData.any(
          (provider) => provider.providerId == 'phone',
    );

    // ==========================================================
    // EMAIL
    // ==========================================================

    final emailLinked = googleLinked || emailPasswordLinked;

    final emailVerified = googleLinked || freshUser.emailVerified;

    // ==========================================================
    // PHONE
    // ==========================================================

    final phoneLinked =
        phoneProviderLinked &&
            freshUser.phoneNumber != null &&
            freshUser.phoneNumber!.trim().isNotEmpty;

    // Firebase phone provider means phone was OTP verified.
    final phoneVerified = phoneLinked;

    // ==========================================================
    // SCREEN NAME
    // ==========================================================

    final existingScreenName =
        data?['screenName']?.toString().trim() ?? '';

    if (!mounted) return;

    setState(() {
      _emailLinked = emailLinked;
      _emailVerified = emailVerified;

      _phoneLinked = phoneLinked;
      _phoneVerified = phoneVerified;

      if (existingScreenName.isNotEmpty) {
        _screenNameController.text = existingScreenName;
      }

      // ========================================================
      // DECIDE FIRST REQUIRED STEP
      // ========================================================

      if (!_emailLinked) {
        // Phone login:
        // Email still needs to be linked.
        _step = 0;
      } else if (!_emailVerified) {
        // Email exists but verification is pending.
        _step = 0;
      } else if (!_phoneLinked) {
        // Email ready, phone missing.
        _step = 1;
      } else {
        // Both email and phone ready.
        _step = 2;
      }

      _loading = false;
    });
  }

  // ============================================================
  // LINK EMAIL
  // ============================================================

  Future<void> _linkEmail() async {
    if (_loading) return;

    final email = _emailController.text.trim();

    // IMPORTANT:
    // Password is NOT trimmed.
    final password = _emailPasswordController.text;

    final confirmPassword =
        _emailConfirmPasswordController.text;

    // ==========================================================
    // VALIDATION
    // ==========================================================

    if (email.isEmpty) {
      _show(
        'Enter your email address.',
        error: true,
      );

      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _show(
        'Enter a valid email address.',
        error: true,
      );

      return;
    }

    if (password.length < 6) {
      _show(
        'Password must be at least 6 characters.',
        error: true,
      );

      return;
    }

    if (password != confirmPassword) {
      _show(
        'Passwords do not match.',
        error: true,
      );

      return;
    }

    setState(() {
      _loading = true;
    });

    final error = await _auth.linkEmailToCurrentUser(
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _loading = false;
      });

      _show(
        error,
        error: true,
      );

      return;
    }

    // ==========================================================
    // REFRESH USER
    // ==========================================================

    await _auth.reloadUser();

    final freshUser = FirebaseAuth.instance.currentUser;

    if (freshUser == null) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _show(
        'Session expired. Please login again.',
        error: true,
      );

      return;
    }

    final googleLinked = freshUser.providerData.any(
          (provider) => provider.providerId == 'google.com',
    );

    final emailVerified =
        googleLinked || freshUser.emailVerified;

    if (!mounted) return;

    setState(() {
      _emailLinked = true;
      _emailVerified = emailVerified;

      _emailPasswordController.clear();
      _emailConfirmPasswordController.clear();
    });

    // ==========================================================
    // GOOGLE
    // ==========================================================

    if (googleLinked) {
      await _loadCurrentStatus();
      return;
    }

    // ==========================================================
    // EMAIL/PASSWORD
    //
    // Newly linked email still needs verification.
    // ==========================================================

    final verificationError =
    await _auth.sendEmailVerification();

    if (!mounted) return;

    if (verificationError != null) {
      setState(() {
        _loading = false;
      });

      _show(
        verificationError,
        error: true,
      );

      return;
    }

    setState(() {
      _loading = false;
    });

    _show(
      'Email linked. Verification email sent.',
    );
  }

  // ============================================================
  // SEND EMAIL VERIFICATION
  // ============================================================

  Future<void> _sendEmailVerification() async {
    if (_loading) return;

    setState(() {
      _loading = true;
    });

    final error = await _auth.sendEmailVerification();

    if (!mounted) return;

    setState(() {
      _loading = false;
    });

    if (error != null) {
      _show(
        error,
        error: true,
      );

      return;
    }

    _show(
      'Verification email sent. Check your inbox.',
    );
  }

  // ============================================================
  // CHECK EMAIL VERIFICATION
  // ============================================================

  Future<void> _checkEmailVerification() async {
    if (_loading) return;

    setState(() {
      _loading = true;
    });

    final verified = await _auth.refreshEmailVerification();

    if (!mounted) return;

    if (!verified) {
      setState(() {
        _loading = false;
      });

      _show(
        'Email is not verified yet. Open the verification link first.',
        error: true,
      );

      return;
    }

    // ==========================================================
    // REFRESH FIREBASE USER
    // ==========================================================

    await _auth.reloadUser();

    final freshUser = FirebaseAuth.instance.currentUser;

    if (freshUser == null) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _show(
        'Session expired. Please login again.',
        error: true,
      );

      return;
    }

    final googleLinked = freshUser.providerData.any(
          (provider) => provider.providerId == 'google.com',
    );

    final phoneLinked = freshUser.providerData.any(
          (provider) => provider.providerId == 'phone',
    );

    final phoneVerified =
        phoneLinked &&
            freshUser.phoneNumber != null &&
            freshUser.phoneNumber!.trim().isNotEmpty;

    // ==========================================================
    // UPDATE FIRESTORE
    // ==========================================================

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(freshUser.uid)
          .set(
        {
          'emailVerified':
          googleLinked || freshUser.emailVerified,
          'phoneVerified': phoneVerified,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint(
        'VERIFICATION FIRESTORE UPDATE ERROR: $e',
      );
    }

    if (!mounted) return;

    setState(() {
      _emailLinked = true;

      _emailVerified =
          googleLinked || freshUser.emailVerified;

      _phoneLinked = phoneLinked;
      _phoneVerified = phoneVerified;

      _loading = false;

      // Phone already ready -> Name.
      // Otherwise -> Phone.
      _step = phoneVerified ? 2 : 1;
    });

    _show(
      'Email verified successfully.',
    );
  }

  // ============================================================
  // SEND PHONE OTP
  // ============================================================

  Future<void> _sendPhoneOtp() async {
    if (_loading) return;

    // ==========================================================
    // ALREADY LINKED
    //
    // NEVER SEND OTP AGAIN.
    // ==========================================================

    if (_auth.isPhoneLinked()) {
      await _loadCurrentStatus();
      return;
    }

    if (_phone.isEmpty || !_phone.startsWith('+')) {
      _show(
        'Enter a valid phone number.',
        error: true,
      );

      return;
    }

    setState(() {
      _loading = true;
      _verificationId = null;
      _otpController.clear();
    });

    // ==========================================================
    // FIREBASE PHONE AUTH
    // ==========================================================

    await _auth.signInWithPhone(
      phone: _phone,
      linkToCurrentUser: true,

      // ========================================================
      // OTP SENT
      // ========================================================

      codeSent: (verificationId) {
        if (!mounted) return;

        setState(() {
          _verificationId = verificationId;
          _loading = false;
        });

        _show(
          'OTP sent successfully.',
        );
      },

      // ========================================================
      // ERROR
      // ========================================================

      onError: (error) {
        if (!mounted) return;

        setState(() {
          _loading = false;
        });

        _show(
          error,
          error: true,
        );
      },

      // ========================================================
      // ANDROID AUTO VERIFICATION
      //
      // Android kabhi-kabhi OTP ko automatically verify
      // kar deta hai. Is case mein manual OTP enter nahi
      // karna padega.
      // ========================================================

      onVerified: (user) async {
        debugPrint(
          'PHONE AUTO VERIFIED: ${user.uid}',
        );

        try {
          await user.reload();
        } catch (e) {
          debugPrint(
            'AUTO VERIFY USER RELOAD ERROR: $e',
          );
        }

        final freshUser =
            FirebaseAuth.instance.currentUser;

        if (freshUser == null) {
          if (!mounted) return;

          setState(() {
            _loading = false;
          });

          _show(
            'Session expired. Please login again.',
            error: true,
          );

          return;
        }

        final phoneLinked = freshUser.providerData.any(
              (provider) => provider.providerId == 'phone',
        );

        final phoneVerified =
            phoneLinked &&
                freshUser.phoneNumber != null &&
                freshUser.phoneNumber!.trim().isNotEmpty;

        final googleLinked = freshUser.providerData.any(
              (provider) => provider.providerId == 'google.com',
        );

        final emailVerified =
            googleLinked || freshUser.emailVerified;

        // ======================================================
        // FIRESTORE UPDATE
        // ======================================================

        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(freshUser.uid)
              .set(
            {
              'email': freshUser.email,
              'phone': freshUser.phoneNumber,
              'emailVerified': emailVerified,
              'phoneVerified': phoneVerified,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        } catch (e) {
          debugPrint(
            'AUTO VERIFY FIRESTORE ERROR: $e',
          );
        }

        if (!mounted) return;

        setState(() {
          _phoneLinked = phoneLinked;

          _phoneVerified = phoneVerified;

          _emailVerified = emailVerified;

          _verificationId = null;

          _otpController.clear();

          _loading = false;

          // Email ready -> Screen Name.
          // Email pending -> Email step.
          _step = emailVerified ? 2 : 0;
        });

        _show(
          'Phone number verified successfully.',
        );
      },
    );
  }

  // ============================================================
  // VERIFY MANUAL PHONE OTP
  // ============================================================

  Future<void> _verifyPhoneOtp() async {
    if (_loading) return;

    final verificationId = _verificationId;

    if (verificationId == null || verificationId.isEmpty) {
      _show(
        'Request OTP first.',
        error: true,
      );

      return;
    }

    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      _show(
        'Enter the 6-digit OTP.',
        error: true,
      );

      return;
    }

    setState(() {
      _loading = true;
    });

    final user = await _auth.verifyOtp(
      verificationId: verificationId,
      otp: otp,
      linkToCurrentUser: true,
    );

    if (!mounted) return;

    if (user == null) {
      setState(() {
        _loading = false;
      });

      _show(
        'Invalid OTP or phone could not be linked.',
        error: true,
      );

      return;
    }

    // ==========================================================
    // REFRESH USER
    // ==========================================================

    try {
      await user.reload();
    } catch (e) {
      debugPrint(
        'MANUAL OTP RELOAD ERROR: $e',
      );
    }

    final freshUser =
        FirebaseAuth.instance.currentUser;

    if (freshUser == null) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _show(
        'Session expired. Please login again.',
        error: true,
      );

      return;
    }

    final phoneLinked = freshUser.providerData.any(
          (provider) => provider.providerId == 'phone',
    );

    final phoneVerified =
        phoneLinked &&
            freshUser.phoneNumber != null &&
            freshUser.phoneNumber!.trim().isNotEmpty;

    final googleLinked = freshUser.providerData.any(
          (provider) => provider.providerId == 'google.com',
    );

    final emailVerified =
        googleLinked || freshUser.emailVerified;

    // ==========================================================
    // FIRESTORE UPDATE
    // ==========================================================

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(freshUser.uid)
          .set(
        {
          'email': freshUser.email,
          'phone': freshUser.phoneNumber,
          'emailVerified': emailVerified,
          'phoneVerified': phoneVerified,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint(
        'MANUAL OTP FIRESTORE ERROR: $e',
      );
    }

    if (!mounted) return;

    setState(() {
      _phoneLinked = phoneLinked;

      _phoneVerified = phoneVerified;

      _emailVerified = emailVerified;

      _verificationId = null;

      _otpController.clear();

      _loading = false;

      // Both ready -> Name.
      // Email pending -> Email.
      _step = emailVerified ? 2 : 0;
    });

    _show(
      'Phone number verified successfully.',
    );
  }

  // ============================================================
  // SAVE SCREEN NAME
  // ============================================================

  Future<void> _saveScreenName() async {
    if (_loading) return;

    final screenName =
    _screenNameController.text.trim();

    if (screenName.length < 3) {
      _show(
        'Screen Name must be at least 3 characters.',
        error: true,
      );

      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _show(
        'Session expired. Please login again.',
        error: true,
      );

      return;
    }

    try {
      await user.reload();
    } catch (e) {
      debugPrint(
        'FINAL USER RELOAD ERROR: $e',
      );
    }

    final freshUser =
        FirebaseAuth.instance.currentUser;

    if (freshUser == null) {
      _show(
        'Session expired. Please login again.',
        error: true,
      );

      return;
    }

    // ==========================================================
    // FINAL AUTH CHECK
    // ==========================================================

    final emailVerified =
    _auth.isEmailVerified();

    final phoneVerified =
    _auth.isPhoneVerified();

    // ==========================================================
    // EMAIL CHECK
    // ==========================================================

    if (!emailVerified) {
      if (!mounted) return;

      setState(() {
        _emailVerified = false;
        _step = 0;
      });

      _show(
        'Please verify your email first.',
        error: true,
      );

      return;
    }

    // ==========================================================
    // PHONE CHECK
    // ==========================================================

    if (!phoneVerified) {
      if (!mounted) return;

      setState(() {
        _phoneVerified = false;
        _step = 1;
      });

      _show(
        'Please link and verify your phone number first.',
        error: true,
      );

      return;
    }

    // ==========================================================
    // COMPLETE PROFILE
    // ==========================================================

    setState(() {
      _loading = true;
    });

    try {
      await UserService().completeProfileSetup(
        screenName: screenName,
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _show(
        'Account setup completed successfully.',
      );

      await Future.delayed(
        const Duration(
          milliseconds: 300,
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
            (route) => false,
      );
    } catch (e) {
      debugPrint(
        'PROFILE SETUP ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _show(
        'Could not complete account setup. Please try again.',
        error: true,
      );
    }
  }

  // ============================================================
  // UI MESSAGE
  // ============================================================

  void _show(
      String message, {
        bool error = false,
      }) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        error ? Colors.red : Colors.green,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_loading &&
        !_emailLinked &&
        !_phoneLinked &&
        _verificationId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Complete Your Profile',
          ),
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Complete Your Profile',
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              const Icon(
                Icons.verified_user_rounded,
                size: 70,
              ),

              const SizedBox(height: 20),

              const Text(
                'Complete Your Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Complete the required account steps before using Ask The Mufti.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 30),

              _buildProgress(),

              const SizedBox(height: 30),

              if (_step == 0)
                _buildEmailStep(),

              if (_step == 1)
                _buildPhoneStep(),

              if (_step == 2)
                _buildScreenNameStep(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROGRESS
  // ============================================================

  Widget _buildProgress() {
    return Row(
      children: [
        _progressItem(
          0,
          'Email',
          _emailVerified,
        ),

        _progressLine(),

        _progressItem(
          1,
          'Phone',
          _phoneVerified,
        ),

        _progressLine(),

        _progressItem(
          2,
          'Name',
          false,
        ),
      ],
    );
  }

  Widget _progressItem(
      int number,
      String title,
      bool completed,
      ) {
    final active = _step == number;

    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            child: completed
                ? const Icon(
              Icons.check,
              size: 20,
            )
                : Text(
              '${number + 1}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            title,
            style: TextStyle(
              fontWeight: active
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressLine() {
    return Container(
      height: 2,
      width: 25,
      color: Colors.grey.shade300,
    );
  }

  // ============================================================
  // EMAIL STEP
  // ============================================================

  Widget _buildEmailStep() {
    // ==========================================================
    // EMAIL ALREADY LINKED + VERIFIED
    // ==========================================================

    if (_emailLinked && _emailVerified) {
      return _stepCard(
        icon: Icons.mark_email_read,
        title: 'Email Verified',
        description:
        'Your email address is already linked and verified.',
        buttonText: 'Continue',
        onPressed: () {
          setState(() {
            _step = _phoneVerified ? 2 : 1;
          });
        },
      );
    }

    // ==========================================================
    // EMAIL LINKED BUT NOT VERIFIED
    // ==========================================================

    if (_emailLinked && !_emailVerified) {
      return _stepCard(
        icon: Icons.mark_email_unread,
        title: 'Verify Your Email',
        description:
        'Open the verification link sent to your email and then return here.',
        buttonText:
        _loading
            ? 'Sending...'
            : 'Send Verification Email',
        onPressed:
        _loading
            ? null
            : _sendEmailVerification,
        secondaryText: 'I Have Verified My Email',
        secondaryPressed:
        _loading
            ? null
            : _checkEmailVerification,
      );
    }

    // ==========================================================
    // EMAIL NOT LINKED
    //
    // Normally this is the phone-login case.
    // ==========================================================

    return _stepCard(
      icon: Icons.email_outlined,
      title: 'Link Your Email',
      description:
      'Add an email address and create a password for your Ask The Mufti account.',
      customContent: Column(
        children: [
          TextField(
            controller: _emailController,
            keyboardType:
            TextInputType.emailAddress,
            autofillHints: const [
              AutofillHints.email,
            ],
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(
                Icons.email_outlined,
              ),
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller:
            _emailPasswordController,
            obscureText: _hideEmailPassword,
            decoration: InputDecoration(
              labelText: 'Create Password',
              border:
              const OutlineInputBorder(),
              prefixIcon: const Icon(
                Icons.lock_outline,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _hideEmailPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _hideEmailPassword =
                    !_hideEmailPassword;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller:
            _emailConfirmPasswordController,
            obscureText:
            _hideEmailConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              border:
              const OutlineInputBorder(),
              prefixIcon: const Icon(
                Icons.lock_outline,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _hideEmailConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _hideEmailConfirmPassword =
                    !_hideEmailConfirmPassword;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      buttonText:
      _loading
          ? 'Linking...'
          : 'Link Email',
      onPressed:
      _loading
          ? null
          : _linkEmail,
    );
  }

  // ============================================================
  // PHONE STEP
  // ============================================================

  Widget _buildPhoneStep() {
    // ==========================================================
    // PHONE ALREADY VERIFIED
    // ==========================================================

    if (_phoneLinked && _phoneVerified) {
      return _stepCard(
        icon: Icons.phone_android,
        title: 'Phone Verified',
        description:
        'Your phone number is already linked and verified.',
        buttonText: 'Continue',
        onPressed: () {
          setState(() {
            _step = 2;
          });
        },
      );
    }

    return _stepCard(
      icon: Icons.phone_android,
      title: 'Link Your Phone',
      description:
      'Your phone number will be securely linked to this account using OTP verification.',
      customContent: Column(
        children: [
          IntlPhoneField(
            initialCountryCode: 'IN',
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
            onChanged: (phone) {
              _phone = phone.completeNumber;
            },
          ),

          if (_verificationId != null) ...[
            const SizedBox(height: 15),

            TextField(
              controller: _otpController,
              keyboardType:
              TextInputType.number,
              maxLength: 6,
              decoration:
              const InputDecoration(
                labelText: 'Enter OTP',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ],
      ),
      buttonText:
      _verificationId == null
          ? 'Send OTP'
          : 'Verify OTP',
      onPressed:
      _loading
          ? null
          : (_verificationId == null
          ? _sendPhoneOtp
          : _verifyPhoneOtp),
    );
  }

  // ============================================================
  // SCREEN NAME
  // ============================================================

  Widget _buildScreenNameStep() {
    return _stepCard(
      icon: Icons.badge_outlined,
      title: 'Choose Your Screen Name',
      description:
      'This name will appear on your profile and with your questions.',
      customContent: TextField(
        controller: _screenNameController,
        textCapitalization:
        TextCapitalization.words,
        textInputAction:
        TextInputAction.done,
        decoration: const InputDecoration(
          labelText: 'Screen Name',
          hintText:
          'Enter the name you want others to see',
          border: OutlineInputBorder(),
        ),
      ),
      buttonText: 'Complete Account',
      onPressed:
      _loading
          ? null
          : _saveScreenName,
    );
  }

  // ============================================================
  // STEP CARD
  // ============================================================

  Widget _stepCard({
    required IconData icon,
    required String title,
    required String description,
    String? buttonText,
    VoidCallback? onPressed,
    String? secondaryText,
    VoidCallback? secondaryPressed,
    Widget? customContent,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(
              icon,
              size: 50,
            ),

            const SizedBox(height: 18),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            if (customContent != null) ...[
              const SizedBox(height: 25),
              customContent,
            ],

            if (buttonText != null) ...[
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onPressed,
                  child: _loading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : Text(buttonText),
                ),
              ),
            ],

            if (secondaryText != null) ...[
              const SizedBox(height: 10),

              TextButton(
                onPressed: secondaryPressed,
                child: Text(
                  secondaryText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}