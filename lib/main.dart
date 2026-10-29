import 'package:flutter/material.dart';
import 'package:taskora/app/app.dart';
import 'package:taskora/core/di/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const TaskoraApp());
}
