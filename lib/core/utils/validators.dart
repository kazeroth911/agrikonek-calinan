/// Pure-Dart form validators — unit-testable per the testing plan
/// (70% coverage target on non-UI business logic).
class Validators {
  Validators._();

  static String? requiredField(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? email(String? value, {bool optional = false}) {
    if (value == null || value.trim().isEmpty) {
      return optional ? null : 'Email is required';
    }
    final re = RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$');
    if (!re.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  /// Accepts PH mobile formats: 09XXXXXXXXX or +639XXXXXXXXX.
  static String? phPhone(String? value, {bool optional = false}) {
    if (value == null || value.trim().isEmpty) {
      return optional ? null : 'Phone number is required';
    }
    final v = value.replaceAll(RegExp(r'[\s\-]'), '');
    final re = RegExp(r'^(09\d{9}|\+639\d{9})$');
    if (!re.hasMatch(v)) return 'Use 09XXXXXXXXX or +639XXXXXXXXX';
    return null;
  }

  /// Normalizes a PH number to E.164 (+639XXXXXXXXX) for Firebase Auth.
  static String toE164Ph(String value) {
    final v = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (v.startsWith('+63')) return v;
    if (v.startsWith('0')) return '+63${v.substring(1)}';
    return '+63$v';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }
}
