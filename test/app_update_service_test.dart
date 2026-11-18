import 'package:flutter_test/flutter_test.dart';

import 'package:tims/app/services/app_update_service.dart';

void main() {
  test('compares versions numerically, not as strings', () {
    expect(compareVersions('1.0.10', '1.0.9'), greaterThan(0));
    expect(compareVersions('1.0.1', '1.0.1'), 0);
    expect(compareVersions('1.0.0', '1.0.1'), lessThan(0));
  });

  test('ignores build and pre-release suffixes', () {
    expect(compareVersions('1.0.1+2', '1.0.1'), 0);
    expect(compareVersions('1.0.2-beta', '1.0.1+5'), greaterThan(0));
  });

  test('treats missing components as zero', () {
    expect(compareVersions('1.1', '1.0.9'), greaterThan(0));
    expect(compareVersions('1.0', '1.0.0'), 0);
  });
}
