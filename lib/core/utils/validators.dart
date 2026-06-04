/// KLE HOMECARE — Form Validators
class Validators {
  Validators._();

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional on service request
    final regex = RegExp(r'^\d{10}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid 10-digit phone number';
    return null;
  }

  static String? phoneRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final regex = RegExp(r'^\d{10}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid 10-digit phone number';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'\d'))) {
      return 'Password must contain at least one digit';
    }
    if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  static String? Function(String?) confirmPassword(String? original) {
    return (String? value) {
      if (value == null || value.isEmpty) return 'Please confirm your password';
      if (value != original) return 'Passwords do not match';
      return null;
    };
  }

  static String? pincode(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'Pincode must be 6 digits';
    }
    return null;
  }

  static String? minLength(String? value, int min, [String? label]) {
    if (value == null || value.trim().isEmpty) return '${label ?? 'Field'} is required';
    if (value.trim().length < min) return '${label ?? 'Field'} must be at least $min characters';
    return null;
  }

  static String? positiveInt(String? value, {int min = 1, int max = 365}) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    final n = int.tryParse(value.trim());
    if (n == null) return 'Enter a valid number';
    if (n < min || n > max) return 'Value must be between $min and $max';
    return null;
  }
}
