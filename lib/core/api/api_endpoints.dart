class ApiEndpoints {
  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String verify = '/auth/verify';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static String updateProfile(String id) => '/auth/$id';

  // Accommodations (public)
  static const String accommodations = '/erd/accommodations';
  static String accommodationById(String id) => '/erd/accommodations/$id';

  // Experiences (public)
  static const String experiences = '/erd/experiences';
  static String experienceById(String id) => '/erd/experiences/$id';

  // Bookings (auth required)
  static const String bookings = '/erd/bookings';
  static String bookingById(String id) => '/erd/bookings/$id';
  static const String checkAvailability = '/erd/bookings/check-availability';

  // Payments
  static const String payments = '/erd/payments';
  static String paymentById(String id) => '/erd/payments/$id';
  static const String esewaInitiate = '/payment/esewa/initiate';
  static const String cancelBooking = '/payment/cancel-booking';

  // Reviews
  static const String reviews = '/erd/reviews';
  static String reviewById(String id) => '/erd/reviews/$id';

  // Host
  static const String hostMe = '/host/me';
  static const String hostApply = '/host/apply';
  static const String hostListings = '/host/listings';
  static String hostListingById(String id) => '/host/listings/$id';
  static const String hostExperiences = '/host/experiences';
  static String hostExperienceById(String id) => '/host/experiences/$id';
  static const String hostReservations = '/host/reservations';

  // Messages
  static const String conversations = '/messages/conversations';
  static const String messageThread = '/messages/thread';
  static const String sendMessage = '/messages';

  // Notifications
  static const String notifications = '/notifications';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';

  // Wishlist
  static const String wishlist = '/wishlist';
  static const String wishlistToggle = '/wishlist/toggle';

  // Admin
  static const String adminUsers = '/admin/users';
  static const String adminHosts = '/admin/hosts';
  static const String adminPendingHosts = '/admin/hosts/pending';
  static String adminApproveHost(String id) => '/admin/hosts/$id/approve';
  static String adminRejectHost(String id) => '/admin/hosts/$id/reject';

  // Reports
  static const String reports = '/reports';
  static const String adminReports = '/reports/admin';
  static String adminReportStatus(String id) => '/reports/admin/$id/status';
}
