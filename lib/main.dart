import 'package:flutter/material.dart';
import 'package:mobile/src/app.dart';
import 'package:mobile/src/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  runApp(SupportApp(config: config));
}
