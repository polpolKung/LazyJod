import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'features/ingestion/providers/sync_queue_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Activate the background sync connectivity listener before the widget tree.
  // This ensures any queued offline slips are retried as soon as the first
  // connectivity event fires after launch.
  final container = ProviderContainer();
  container.read(syncQueueProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const LazyJodApp(),
    ),
  );
}
