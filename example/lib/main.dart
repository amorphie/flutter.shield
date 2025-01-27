import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shield_example/DeviceInfoProvider.dart';
import 'package:flutter_shield_example/ProxiedHttpOverrides.dart';
import 'package:flutter_shield_example/dashboard.dart';
import 'package:provider/provider.dart';

final _messangerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeviceInfoProvider()),
      ],
      child: MyApp(),
    ),
  );

  if(!kIsWeb){
    ProxiedHttpOverrides.addSystemProxy();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _messangerKey,
      home: const Dashboard(),
    );
  }
}
