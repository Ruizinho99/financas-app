import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financas/update/update_checker.dart';

void main() {
  test('atualização por APK só no Android; iOS tem texto próprio', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(selfUpdateSupported, isFalse);
    expect(isIosPlatform, isTrue);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(selfUpdateSupported, isTrue);
    expect(isIosPlatform, isFalse);
    debugDefaultTargetPlatformOverride = null;
  });
}
