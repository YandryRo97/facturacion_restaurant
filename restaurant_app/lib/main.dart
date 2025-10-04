import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // generado por flutterfire configure
import 'app_router.dart';


Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
runApp(const ProviderScope(child: RestaurantApp()));
}


class RestaurantApp extends ConsumerWidget {
const RestaurantApp({super.key});


@override
Widget build(BuildContext context, WidgetRef ref) {
final router = ref.watch(appRouterProvider);
return MaterialApp.router(
title: 'Restaurant App',
routerConfig: router,
theme: ThemeData(
useMaterial3: true,
colorSchemeSeed: Colors.teal,
),
);
}
}