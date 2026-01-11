import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  dotenv.load(fileName: '.env');
  runApp(ProviderScope(child: const MyApp()));
}
