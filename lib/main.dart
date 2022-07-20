import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bloc/scan_bloc.dart';
import 'screens/scan.dart';

void main() async {
  GetIt.I.registerLazySingletonAsync(() => SharedPreferences.getInstance());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhatsApp Cleaner',
      theme: ThemeData.from(
        colorScheme: const ColorScheme.dark(),
        useMaterial3: true,
      ).copyWith(appBarTheme: const AppBarTheme(centerTitle: true)),
      home: BlocProvider(
        create: (context) => ScanBloc(),
        child: const ScanPage(),
      ),
    );
  }
}
