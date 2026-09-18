import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/admin_stats_screen.dart';
import '../features/admin/manage_mufti_screen.dart';
import '../features/answer_detail/answer_detail_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/phone_login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/mufti/mufti_dashboard_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/owner/owner_dashboard_screen.dart';
import '../features/profile/bookmarks_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/my_questions_screen.dart';
import '../features/root/root_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/reviews/reviews_suggestions_screen.dart';
import '../models/question_model.dart';

class AppRoutes {
  // ============================================================
  // ROUTE NAMES
  // ============================================================

  static const String home = AppConstants.routeHome;

  static const String mainHome =
      AppConstants.routeMainHome;

  static const String notifications =
      AppConstants.routeNotifications;

  static const String answerDetail =
      AppConstants.routeAnswerDetail;

  static const String login =
      AppConstants.routeLogin;

  static const String phoneLogin =
      AppConstants.routePhoneLogin;

  static const String signup =
      AppConstants.routeSignup;

  static const String editProfile =
      AppConstants.routeEditProfile;

  static const String bookmarks =
      AppConstants.routeBookmarks;

  static const String myQuestions =
      AppConstants.routeMyQuestions;

  static const String settings =
      AppConstants.routeSettings;

  static const String search =
      AppConstants.routeSearch;

  static const String muftiPanel =
      AppConstants.routeMuftiPanel;

  static const String adminDashboard =
      AppConstants.routeAdminDashboard;

  static const String adminStats =
      AppConstants.routeAdminStats;

  static const String manageMufti =
      AppConstants.routeManageMufti;

  static const String ownerDashboard =
      AppConstants.routeOwnerDashboard;

  static const String reviewsSuggestions =
      AppConstants.routeReviewsSuggestions;

  // ============================================================
  // ROUTES
  // ============================================================

  static final Map<String, WidgetBuilder> routes = {
    home: (_) => const RootScreen(),

    mainHome: (_) => const RootScreen(),

    notifications: (_) =>
    const NotificationsScreen(),

    // ==========================================================
    // ANSWER DETAIL
    // ==========================================================

    answerDetail: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments;

      if (args is QuestionModel) {
        return AnswerDetailScreen(
          question: args,
        );
      }

      if (args is String && args.isNotEmpty) {
        return _AnswerDetailLoader(
          questionId: args,
        );
      }

      return const RootScreen();
    },

    // ==========================================================
    // AUTH
    // ==========================================================

    login: (_) => const LoginScreen(),

    phoneLogin: (_) =>
    const PhoneLoginScreen(),

    signup: (_) => const SignupScreen(),

    // ==========================================================
    // PROFILE
    // ==========================================================

    editProfile: (_) =>
    const EditProfileScreen(),

    bookmarks: (_) =>
    const BookmarksScreen(),

    myQuestions: (_) =>
    const MyQuestionsScreen(),

    // ==========================================================
    // OTHER
    // ==========================================================

    settings: (_) =>
    const SettingsScreen(),

    search: (_) =>
    const SearchScreen(),

    // ==========================================================
    // REVIEWS & SUGGESTIONS
    // ==========================================================

    reviewsSuggestions: (_) =>
    const ReviewsSuggestionsScreen(),

    // ==========================================================
    // ROLE PANELS
    // ==========================================================

    muftiPanel: (_) =>
    const MuftiDashboardScreen(),

    adminDashboard: (_) =>
    const AdminDashboardScreen(),

    adminStats: (_) =>
    const AdminStatsScreen(),

    manageMufti: (_) =>
    const ManageMuftiScreen(),

    ownerDashboard: (_) =>
    const OwnerDashboardScreen(),
  };

  // ============================================================
  // UNKNOWN ROUTE
  // ============================================================

  static Route<dynamic> onUnknownRoute(
      RouteSettings routeSettings,
      ) {
    return MaterialPageRoute(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: colorScheme.outline,
                ),

                const SizedBox(height: 16),

                Text(
                  '404',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Page not found: '
                      '${routeSettings.name ?? "unknown"}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// ANSWER DETAIL LOADER
// ============================================================

class _AnswerDetailLoader
    extends StatelessWidget {
  final String questionId;

  const _AnswerDetailLoader({
    required this.questionId,
  });

  Future<QuestionModel?> _loadQuestion() async {
    try {
      final doc = await FirebaseFirestore
          .instance
          .collection(
        AppConstants.questionsCollection,
      )
          .doc(questionId)
          .get();

      if (!doc.exists) return null;

      return QuestionModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<QuestionModel?>(
      future: _loadQuestion(),
      builder: (context, snapshot) {
        // ======================================================
        // LOADING
        // ======================================================

        if (snapshot.connectionState !=
            ConnectionState.done) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            ),
          );
        }

        // ======================================================
        // ERROR
        // ======================================================

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.error,
                    size: 48,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Sawal load nahi ho saka',
                    style: theme.textTheme.titleMedium,
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(),
                    child: const Text(
                      'Wapas Jao',
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ======================================================
        // QUESTION NOT FOUND
        // ======================================================

        final question = snapshot.data;

        if (question == null) {
          return const RootScreen();
        }

        // ======================================================
        // SUCCESS
        // ======================================================

        return AnswerDetailScreen(
          question: question,
        );
      },
    );
  }
}