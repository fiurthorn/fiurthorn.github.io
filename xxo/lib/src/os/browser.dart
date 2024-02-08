import 'dart:html';

import 'os.dart';

class OperationSystem extends OS {
  static String get name => 'Browser';
  static String get version => window.navigator.appVersion;
}
