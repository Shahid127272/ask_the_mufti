class AppConstants {
  AppConstants._();

  // ======================================================
  // ROLES
  // ======================================================

  static const String roleOwner = 'owner';
  static const String roleAdmin = 'admin';
  static const String roleMufti = 'mufti';
  static const String roleUser = 'user';

  static const List<String> allRoles = [
    roleOwner,
    roleAdmin,
    roleMufti,
    roleUser,
  ];

  // ======================================================
  // FIRESTORE COLLECTIONS
  // ======================================================

  static const String usersCollection = 'users';
  static const String questionsCollection = 'questions';
  static const String invitationsCollection = 'invitations';
  static const String notificationsCollection = 'notifications';
  static const String donationsCollection = 'donations';

  // Reviews & Suggestions
  static const String reviewsCollection = 'reviews';
  static const String suggestionsCollection = 'suggestions';

  // ======================================================
  // FIRESTORE FIELDS
  // ======================================================

  static const String fieldRole = 'role';
  static const String fieldEmail = 'email';
  static const String fieldStatus = 'status';
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldUpdatedAt = 'updatedAt';
  static const String fieldDisplayName = 'displayName';
  static const String fieldPhotoUrl = 'photoUrl';

  // ======================================================
  // INVITATION STATUS
  // ======================================================

  static const String inviteStatusPending = 'pending';
  static const String inviteStatusAccepted = 'accepted';
  static const String inviteStatusRejected = 'rejected';

  // ======================================================
  // QUESTION STATUS
  // ======================================================

  static const String questionStatusPending = 'pending';
  static const String questionStatusAnswered = 'answered';
  static const String questionStatusRejected = 'rejected';

  // ======================================================
  // SUGGESTION STATUS
  // ======================================================

  static const String suggestionStatusNew = 'new';
  static const String suggestionStatusInReview = 'inReview';
  static const String suggestionStatusResolved = 'resolved';

  // ======================================================
  // ROUTES
  // ======================================================

  static const String routeHome = '/';
  static const String routeMainHome = '/home';
  static const String routeNotifications = '/notifications';
  static const String routeAnswerDetail = '/answerDetail';
  static const String routeLogin = '/login';
  static const String routePhoneLogin = '/phone-login';
  static const String routeSignup = '/signup';
  static const String routeEditProfile = '/edit-profile';
  static const String routeBookmarks = '/bookmarks';
  static const String routeMyQuestions = '/my-questions';
  static const String routeSettings = '/settings';
  static const String routeSearch = '/search';
  static const String routeMuftiPanel = '/mufti-panel';
  static const String routeAdminDashboard = '/admin';
  static const String routeAdminStats = '/admin/stats';
  static const String routeManageMufti = '/admin/manage-mufti';
  static const String routeOwnerDashboard = '/owner';

  // Reviews & Suggestions
  static const String routeReviewsSuggestions =
      '/reviews-suggestions';

  // ======================================================
  // STORAGE PATHS
  // ======================================================

  static const String storageUsers = 'users';
  static const String storageProfilePhoto = 'profile.jpg';

  // ======================================================
  // APP INFO
  // ======================================================

  static const String appName = 'Ask The Mufti';
  static const String appVersion = '2.0.0';

  // ======================================================
  // PAGINATION
  // ======================================================

  static const int pageSize = 20;
  static const int searchLimit = 50;
}