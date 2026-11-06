import 'dart:async';

import 'package:agrikonek_calinan/core/constants/app_constants.dart';
import 'package:agrikonek_calinan/services/listing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Offline notice timing (offline-cached feed)', () {
    const delay = Duration(milliseconds: 60);

    test('a short cache-first moment never shows the notice', () async {
      final source = StreamController<bool>();
      final seen = <bool>[];
      final sub = source.stream
          .transform(ListingRepository.delayTrue(delay))
          .listen(seen.add);
      source.add(true); // app start: served from the phone first
      await Future<void>.delayed(const Duration(milliseconds: 20));
      source.add(false); // the server answers quickly
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(seen, [false]);
      await sub.cancel();
      await source.close();
    });

    test('staying offline shows the notice, and coming back hides it',
        () async {
      final source = StreamController<bool>();
      final seen = <bool>[];
      final sub = source.stream
          .transform(ListingRepository.delayTrue(delay))
          .listen(seen.add);
      source.add(true);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(seen, [true]);
      source.add(false);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(seen, [true, false]);
      await sub.cancel();
      await source.close();
    });
  });

  test('profiling barangays are the 19 in Appendix B', () {
    const list = AppConstants.calinanBarangays;
    expect(list.length, 19);
    expect(list.toSet().length, 19);
    expect(list, containsAll(['Biao Joaquin', 'Lampianao', 'Wangan']));
    expect(list, isNot(contains('Wines')));
  });
}
