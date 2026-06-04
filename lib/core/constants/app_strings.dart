/// KLE HOMECARE — App String Constants
class AppStrings {
  AppStrings._();

  static const String appName        = 'KLE HOMECARE';
  static const String appTagline     = 'Quality Care at Your Doorstep';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login          = 'Login';
  static const String register       = 'Register';
  static const String logout         = 'Logout';
  static const String email          = 'Email';
  static const String password       = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String firstName      = 'First Name';
  static const String lastName       = 'Last Name';
  static const String phone          = 'Phone Number';
  static const String address        = 'Address';
  static const String city           = 'City';
  static const String state          = 'State';
  static const String pincode        = 'Pincode';
  static const String alreadyHaveAccount = 'Already have an account? Login';
  static const String dontHaveAccount    = "Don't have an account? Register";

  // ── Service Request ───────────────────────────────────────────────────────
  static const String serviceRequest     = 'Service Request';
  static const String newRequest         = 'New Request';
  static const String myRequests         = 'My Requests';
  static const String patientName        = 'Patient Name';
  static const String serviceType        = 'Service Type';
  static const String description        = 'Description';
  static const String preferredDate      = 'Preferred Date';
  static const String numberOfDays       = 'Number of Days';
  static const String preferredTime      = 'Preferred Time';
  static const String urgencyLevel       = 'Urgency Level';
  static const String specialNotes       = 'Special Notes';
  static const String submitRequest      = 'Submit Request';

  // ── Status Labels ─────────────────────────────────────────────────────────
  static const String pending            = 'Pending';
  static const String assigned           = 'Assigned';
  static const String inProgress         = 'In Progress';
  static const String completed          = 'Completed';
  static const String cancelled          = 'Cancelled';

  // ── Roles ─────────────────────────────────────────────────────────────────
  static const String patient            = 'Patient';
  static const String admin              = 'Admin';
  static const String nurse              = 'Nurse';

  // ── Navigation ────────────────────────────────────────────────────────────
  static const String dashboard          = 'Dashboard';
  static const String notifications      = 'Notifications';
  static const String profile            = 'Profile';
  static const String jobs               = 'My Jobs';
  static const String alerts             = 'Job Alerts';

  // ── Errors ────────────────────────────────────────────────────────────────
  static const String networkError       = 'Network error. Please check your connection.';
  static const String serverError        = 'Server error. Please try again later.';
  static const String unauthorizedError  = 'Session expired. Please login again.';
  static const String unknownError       = 'Something went wrong. Please try again.';
  static const String noDataFound        = 'No data found.';

  // ── Validation ────────────────────────────────────────────────────────────
  static const String fieldRequired      = 'This field is required';
  static const String invalidEmail       = 'Enter a valid email address';
  static const String invalidPhone       = 'Enter a valid 10-digit phone number';
  static const String passwordTooShort   = 'Password must be at least 8 characters';
  static const String passwordMismatch   = 'Passwords do not match';
}
