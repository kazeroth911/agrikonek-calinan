import 'package:agrikonek_calinan/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.phPhone', () {
    test('accepts 09 format', () {
      expect(Validators.phPhone('09171234567'), isNull);
    });
    test('accepts +639 format', () {
      expect(Validators.phPhone('+639171234567'), isNull);
    });
    test('rejects short numbers', () {
      expect(Validators.phPhone('0917'), isNotNull);
    });
    test('optional skips empty', () {
      expect(Validators.phPhone('', optional: true), isNull);
    });
  });

  group('Validators.toE164Ph', () {
    test('converts 09 to +639', () {
      expect(Validators.toE164Ph('09171234567'), '+639171234567');
    });
    test('keeps +63 unchanged', () {
      expect(Validators.toE164Ph('+639171234567'), '+639171234567');
    });
  });

  group('Validators.email', () {
    test('accepts valid emails', () {
      expect(Validators.email('moks@addu.edu.ph'), isNull);
    });
    test('rejects malformed emails', () {
      expect(Validators.email('not-an-email'), isNotNull);
    });
  });
}
