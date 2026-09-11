import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final AuthService _auth = AuthService();

  final TextEditingController email =
  TextEditingController();

  final TextEditingController pass =
  TextEditingController();

  bool _loading = false;

  bool _obscurePassword = true;

  bool _rememberMe = true;

  // ============================================================
  // GOOGLE LOGIN
  // ============================================================

  Future<void> _googleLogin() async {
    if (_loading) return;

    setState(() {
      _loading = true;
    });

    try {
      final user =
      await _auth.signInWithGoogle();

      if (!mounted) return;

      if (user == null) {
        _showError(
          "Google login cancelled or failed.",
        );

        setState(() {
          _loading = false;
        });

        return;
      }

      // RootScreen authStateChanges ko detect karega.
      //
      // Complete user:
      //     -> MainScreen
      //
      // Incomplete user:
      //     -> AccountSetupScreen
    } catch (e) {
      debugPrint(
        "GOOGLE LOGIN SCREEN ERROR: $e",
      );

      if (!mounted) return;

      _showError(
        "Google login failed. Please try again.",
      );

      setState(() {
        _loading = false;
      });

      return;
    }

    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

  // ============================================================
  // EMAIL LOGIN
  // ============================================================

  Future<void> _emailLogin() async {
    if (_loading) return;

    FocusScope.of(context).unfocus();

    final enteredEmail =
    email.text.trim();

    // IMPORTANT:
    // Password ko trim nahi karna.
    final enteredPassword =
        pass.text;

    if (enteredEmail.isEmpty ||
        enteredPassword.isEmpty) {
      _showError(
        "Enter email & password",
      );

      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final err =
      await _auth.login(
        email: enteredEmail,
        password: enteredPassword,
      );

      if (!mounted) return;

      if (err != null) {
        _showError(err);

        setState(() {
          _loading = false;
        });

        return;
      }

      // Successful login.
      //
      // RootScreen authStateChanges ko detect karega.
      //
      // Email verified + phone linked + screen name:
      //     -> MainScreen
      //
      // Kuch missing:
      //     -> AccountSetupScreen
    } catch (e) {
      debugPrint(
        "EMAIL LOGIN SCREEN ERROR: $e",
      );

      if (!mounted) return;

      _showError(
        "Login failed. Please try again.",
      );

      setState(() {
        _loading = false;
      });

      return;
    }

    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<void> _forgotPassword() async {
    if (_loading) return;

    final controller =
    TextEditingController(
      text: email.text.trim(),
    );

    bool dialogLoading = false;

    final result =
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
              dialogContentContext,
              setDialogState,
              ) {
            Future<void> sendReset() async {
              final enteredEmail =
              controller.text.trim();

              // --------------------------------------------------
              // EMAIL VALIDATION
              // --------------------------------------------------

              if (enteredEmail.isEmpty) {
                _showDialogMessage(
                  dialogContentContext,
                  "Enter your email address.",
                );

                return;
              }

              if (!enteredEmail.contains('@') ||
                  !enteredEmail.contains('.')) {
                _showDialogMessage(
                  dialogContentContext,
                  "Enter a valid email address.",
                );

                return;
              }

              // --------------------------------------------------
              // LOADING
              // --------------------------------------------------

              setDialogState(() {
                dialogLoading = true;
              });

              // --------------------------------------------------
              // FIREBASE PASSWORD RESET
              // --------------------------------------------------

              final error =
              await _auth
                  .sendPasswordResetEmail(
                email: enteredEmail,
              );

              // IMPORTANT:
              // Dialog context ko async gap ke baad directly
              // use nahi karna. Pehle State check.
              if (!mounted) return;

              // --------------------------------------------------
              // ERROR
              // --------------------------------------------------

              if (error != null) {
                setDialogState(() {
                  dialogLoading = false;
                });

                if (!dialogContentContext.mounted) {
                  return;
                }

                _showDialogMessage(
                  dialogContentContext,
                  error,
                  error: true,
                );

                return;
              }

              // --------------------------------------------------
              // SUCCESS
              // --------------------------------------------------

              if (!dialogContext.mounted) {
                return;
              }

              Navigator.of(
                dialogContext,
              ).pop(
                enteredEmail,
              );
            }

            return AlertDialog(
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(22),
              ),
              title: const Text(
                "Forgot Password?",
                style: TextStyle(
                  fontWeight:
                  FontWeight.w800,
                  color:
                  Color(0xFF075E61),
                ),
              ),
              content: Column(
                mainAxisSize:
                MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    "Enter your registered email address. "
                        "We will send you a password reset link.",
                    style: TextStyle(
                      color:
                      Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  TextField(
                    controller: controller,
                    keyboardType:
                    TextInputType.emailAddress,
                    textInputAction:
                    TextInputAction.done,
                    enabled:
                    !dialogLoading,
                    autofocus: true,
                    decoration:
                    const InputDecoration(
                      labelText:
                      "Email address",
                      prefixIcon:
                      Icon(
                        Icons.email_outlined,
                      ),
                      border:
                      OutlineInputBorder(),
                    ),
                    onSubmitted: (_) {
                      if (!dialogLoading) {
                        sendReset();
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                  dialogLoading
                      ? null
                      : () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child:
                  const Text(
                    "Cancel",
                  ),
                ),

                ElevatedButton(
                  onPressed:
                  dialogLoading
                      ? null
                      : sendReset,
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(
                      0xFF079B9D,
                    ),
                    foregroundColor:
                    Colors.white,
                  ),
                  child:
                  dialogLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child:
                    CircularProgressIndicator(
                      strokeWidth:
                      2,
                      color:
                      Colors.white,
                    ),
                  )
                      : const Text(
                    "Send Reset Link",
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (!mounted) return;

    if (result != null) {
      _showSuccess(
        "Password reset link sent to $result. "
            "Please check your email.",
      );
    }
  }

  // ============================================================
  // DIALOG MESSAGE
  // ============================================================

  void _showDialogMessage(
      BuildContext context,
      String message, {
        bool error = false,
      }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
          SnackBarBehavior.floating,
          backgroundColor:
          error
              ? Colors.red
              : const Color(
            0xFF006D70,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  void _showSuccess(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior:
          SnackBarBehavior.floating,
          backgroundColor:
          const Color(0xFF079B9D),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior:
        SnackBarBehavior.floating,
        backgroundColor:
        const Color(0xFF006D70),
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    email.dispose();
    pass.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final size =
        MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor:
      const Color(0xFFE9FAF9),
      body: Stack(
        children: [
          // ======================================================
          // BACKGROUND
          // ======================================================

          Container(
            width: double.infinity,
            height: double.infinity,
            decoration:
            const BoxDecoration(
              gradient:
              LinearGradient(
                begin:
                Alignment.topCenter,
                end:
                Alignment.bottomCenter,
                colors: [
                  Color(0xFFB9ECEA),
                  Color(0xFFEFFBFA),
                  Color(0xFFD5F3F1),
                ],
              ),
            ),
          ),

          // ======================================================
          // TOP DECORATION
          // ======================================================

          Positioned(
            top: -120,
            left: -80,
            right: -80,
            child: Container(
              height: 330,
              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFF079B9D,
                ).withValues(
                  alpha: .14,
                ),
                borderRadius:
                const BorderRadius.only(
                  bottomLeft:
                  Radius.circular(220),
                  bottomRight:
                  Radius.circular(220),
                ),
              ),
            ),
          ),

          // ======================================================
          // MAIN CONTENT
          // ======================================================

          SafeArea(
            child:
            SingleChildScrollView(
              physics:
              const BouncingScrollPhysics(),
              padding:
              const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 18,
              ),
              child: Column(
                children: [
                  // =================================================
                  // LOGO
                  // =================================================

                  Container(
                    width: 105,
                    height: 105,
                    padding:
                    const EdgeInsets.all(7),
                    decoration:
                    BoxDecoration(
                      shape:
                      BoxShape.circle,
                      color:
                      Colors.white
                          .withValues(
                        alpha: .90,
                      ),
                      border:
                      Border.all(
                        color:
                        const Color(
                          0xFF006D70,
                        ),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                          const Color(
                            0xFF006D70,
                          ).withValues(
                            alpha: .18,
                          ),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child:
                    ClipOval(
                      child:
                      Image.asset(
                        'assets/icons/app_icon.png',
                        fit:
                        BoxFit.cover,
                        errorBuilder:
                            (
                            context,
                            error,
                            stackTrace,
                            ) {
                          return const Icon(
                            Icons
                                .menu_book_rounded,
                            size: 55,
                            color:
                            Color(
                              0xFF006D70,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // =================================================
                  // APP NAME
                  // =================================================

                  const Text(
                    'Ask The Mufti',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      fontSize: 31,
                      fontWeight:
                      FontWeight.w800,
                      letterSpacing: .2,
                      color:
                      Color(0xFF075E61),
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  const Text(
                    'Ask  •  Learn  •  Understand',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                      FontWeight.w600,
                      letterSpacing: .7,
                      color:
                      Color(0xFF318B8C),
                    ),
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  // =================================================
                  // LOGIN CARD
                  // =================================================

                  Container(
                    width:
                    double.infinity,
                    padding:
                    const EdgeInsets.fromLTRB(
                      20,
                      27,
                      20,
                      24,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      Colors.white
                          .withValues(
                        alpha: .96,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        30,
                      ),
                      border:
                      Border.all(
                        color:
                        const Color(
                          0xFF8AD6D3,
                        ),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                          const Color(
                            0xFF006D70,
                          ).withValues(
                            alpha: .13,
                          ),
                          blurRadius: 25,
                          offset:
                          const Offset(
                            0,
                            10,
                          ),
                        ),
                      ],
                    ),
                    child:
                    Column(
                      children: [
                        // -----------------------------------------
                        // WELCOME
                        // -----------------------------------------

                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight:
                            FontWeight.w800,
                            color:
                            Color(
                              0xFF075E61,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 7,
                        ),

                        Text(
                          'Login to continue asking and learning',
                          textAlign:
                          TextAlign.center,
                          style:
                          TextStyle(
                            fontSize: 14,
                            color: Colors
                                .grey
                                .shade600,
                          ),
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        // -----------------------------------------
                        // EMAIL
                        // -----------------------------------------

                        _buildInputField(
                          controller:
                          email,
                          hint:
                          'Email address',
                          icon:
                          Icons
                              .email_outlined,
                          keyboardType:
                          TextInputType
                              .emailAddress,
                        ),

                        const SizedBox(
                          height: 13,
                        ),

                        // -----------------------------------------
                        // PASSWORD
                        // -----------------------------------------

                        _buildInputField(
                          controller:
                          pass,
                          hint:
                          'Password',
                          icon:
                          Icons
                              .lock_outline_rounded,
                          obscureText:
                          _obscurePassword,
                          suffix:
                          IconButton(
                            splashRadius:
                            22,
                            onPressed: () {
                              setState(() {
                                _obscurePassword =
                                !_obscurePassword;
                              });
                            },
                            icon:
                            Icon(
                              _obscurePassword
                                  ? Icons
                                  .visibility_outlined
                                  : Icons
                                  .visibility_off_outlined,
                              color:
                              const Color(
                                0xFF527174,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        // -----------------------------------------
                        // REMEMBER + FORGOT
                        // -----------------------------------------

                        Row(
                          children: [
                            SizedBox(
                              width: 30,
                              height: 30,
                              child:
                              Checkbox(
                                value:
                                _rememberMe,
                                activeColor:
                                const Color(
                                  0xFF079B9D,
                                ),
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    5,
                                  ),
                                ),
                                onChanged:
                                    (value) {
                                  setState(() {
                                    _rememberMe =
                                        value ??
                                            false;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(
                              width: 5,
                            ),

                            const Text(
                              'Remember me',
                              style:
                              TextStyle(
                                fontSize:
                                13.5,
                                color:
                                Color(
                                  0xFF40575A,
                                ),
                                fontWeight:
                                FontWeight
                                    .w500,
                              ),
                            ),

                            const Spacer(),

                            // ---------------------------------------
                            // FORGOT PASSWORD
                            // ---------------------------------------

                            TextButton(
                              onPressed:
                              _loading
                                  ? null
                                  : _forgotPassword,
                              style:
                              TextButton
                                  .styleFrom(
                                padding:
                                EdgeInsets
                                    .zero,
                              ),
                              child:
                              const Text(
                                'Forgot password?',
                                style:
                                TextStyle(
                                  color:
                                  Color(
                                    0xFF079B9D,
                                  ),
                                  fontWeight:
                                  FontWeight
                                      .w700,
                                  fontSize:
                                  13.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        // -----------------------------------------
                        // LOGIN BUTTON
                        // -----------------------------------------

                        SizedBox(
                          width:
                          double.infinity,
                          height: 55,
                          child:
                          ElevatedButton(
                            onPressed:
                            _loading
                                ? null
                                : _emailLogin,
                            style:
                            ElevatedButton
                                .styleFrom(
                              backgroundColor:
                              const Color(
                                0xFF079B9D,
                              ),
                              foregroundColor:
                              Colors.white,
                              elevation: 4,
                              shadowColor:
                              const Color(
                                0xFF079B9D,
                              ).withValues(
                                alpha: .35,
                              ),
                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  16,
                                ),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                              CircularProgressIndicator(
                                strokeWidth:
                                2.5,
                                color:
                                Colors
                                    .white,
                              ),
                            )
                                : const Text(
                              'Login',
                              style:
                              TextStyle(
                                fontSize:
                                17,
                                fontWeight:
                                FontWeight
                                    .w800,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 22,
                        ),

                        // -----------------------------------------
                        // OR
                        // -----------------------------------------

                        Row(
                          children: [
                            Expanded(
                              child:
                              Divider(
                                color: Colors
                                    .grey
                                    .shade300,
                              ),
                            ),

                            Padding(
                              padding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal: 12,
                              ),
                              child:
                              Text(
                                'or continue with',
                                style:
                                TextStyle(
                                  color: Colors
                                      .grey
                                      .shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                            Expanded(
                              child:
                              Divider(
                                color: Colors
                                    .grey
                                    .shade300,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        // -----------------------------------------
                        // GOOGLE + PHONE
                        // -----------------------------------------

                        Row(
                          children: [
                            Expanded(
                              child:
                              _socialButton(
                                icon: Icons
                                    .g_mobiledata_rounded,
                                text:
                                'Google',
                                onPressed:
                                _loading
                                    ? null
                                    : _googleLogin,
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child:
                              _socialButton(
                                icon: Icons
                                    .phone_outlined,
                                text:
                                'Phone',
                                onPressed:
                                _loading
                                    ? null
                                    : () {
                                  Navigator
                                      .pushNamed(
                                    context,
                                    '/phone-login',
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 22,
                        ),

                        // -----------------------------------------
                        // SIGN UP
                        // -----------------------------------------

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style:
                              TextStyle(
                                color: Colors
                                    .grey
                                    .shade600,
                                fontSize: 14,
                              ),
                            ),

                            GestureDetector(
                              onTap: () {
                                Navigator
                                    .push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) =>
                                    const SignupScreen(),
                                  ),
                                );
                              },
                              child:
                              const Text(
                                'Sign up',
                                style:
                                TextStyle(
                                  color:
                                  Color(
                                    0xFF079B9D,
                                  ),
                                  fontWeight:
                                  FontWeight
                                      .w800,
                                  fontSize:
                                  14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  // =================================================
                  // FOOTER
                  // =================================================

                  Container(
                    width:
                    double.infinity,
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                        0xFF006D70,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        25,
                      ),
                    ),
                    child:
                    Column(
                      children: [
                        const Icon(
                          Icons
                              .menu_book_rounded,
                          color:
                          Colors.white,
                          size: 34,
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        const Text(
                          'Seeking knowledge is an obligation',
                          textAlign:
                          TextAlign.center,
                          style:
                          TextStyle(
                            color:
                            Colors.white,
                            fontSize: 14,
                            fontWeight:
                            FontWeight
                                .w600,
                            fontStyle:
                            FontStyle
                                .italic,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          'upon every Muslim',
                          textAlign:
                          TextAlign.center,
                          style:
                          TextStyle(
                            color: Colors
                                .white
                                .withValues(
                              alpha: .83,
                            ),
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Container(
                          height: 1,
                          width: 80,
                          color: Colors
                              .white
                              .withValues(
                            alpha: .35,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          'Ask • Learn • Understand',
                          style:
                          TextStyle(
                            color: Colors
                                .white
                                .withValues(
                              alpha: .8,
                            ),
                            fontSize: 11,
                            letterSpacing:
                            1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height:
                    size.height * .02,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INPUT FIELD
  // ============================================================

  Widget _buildInputField({
    required TextEditingController
    controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return TextField(
      controller:
      controller,
      obscureText:
      obscureText,
      keyboardType:
      keyboardType,
      textInputAction:
      TextInputAction.next,
      style:
      const TextStyle(
        color:
        Color(0xFF183B3D),
        fontSize: 15,
      ),
      decoration:
      InputDecoration(
        hintText: hint,
        hintStyle:
        TextStyle(
          color:
          Colors.grey.shade500,
          fontSize: 14,
        ),
        prefixIcon:
        Icon(
          icon,
          color:
          const Color(
            0xFF527174,
          ),
        ),
        suffixIcon:
        suffix,
        filled: true,
        fillColor:
        const Color(
          0xFFF9FCFC,
        ),
        contentPadding:
        const EdgeInsets
            .symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            15,
          ),
          borderSide:
          const BorderSide(
            color:
            Color(0xFFC9E6E5),
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            15,
          ),
          borderSide:
          const BorderSide(
            color:
            Color(0xFF079B9D),
            width: 1.7,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SOCIAL BUTTON
  // ============================================================

  Widget _socialButton({
    required IconData icon,
    required String text,
    required VoidCallback?
    onPressed,
  }) {
    return SizedBox(
      height: 52,
      child:
      OutlinedButton(
        onPressed:
        onPressed,
        style:
        OutlinedButton.styleFrom(
          foregroundColor:
          const Color(
            0xFF21494B,
          ),
          backgroundColor:
          Colors.white,
          side:
          const BorderSide(
            color:
            Color(0xFFD5E8E7),
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              14,
            ),
          ),
        ),
        child:
        Row(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [
            Icon(
              icon,
              size: 25,
              color:
              const Color(
                0xFF08777A,
              ),
            ),

            const SizedBox(
              width: 7,
            ),

            Flexible(
              child:
              Text(
                text,
                overflow:
                TextOverflow
                    .ellipsis,
                style:
                const TextStyle(
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}