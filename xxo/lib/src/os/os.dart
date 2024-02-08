export 'default.dart' //
    if (dart.library.html) 'browser.dart'
    if (dart.library.io) 'platform.dart';

abstract class OS {
  static String get name => 'unknown';
  static String get version => 'unknown';
}
