import 'dart:io';

import '../os.dart';

class OperationSystem extends OS {
  static String get name => Platform.operatingSystem;
  static String get version => Platform.operatingSystemVersion;
}
