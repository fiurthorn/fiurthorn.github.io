export 'src/platform.dart' if (dart.library.html) 'src/browser.dart';

abstract class OS {
  static String get name => 'unknown';
  static String get version => 'unknown';
}
