

import 'package:flutter/material.dart';
import 'package:lazycopy/app.dart';
import 'package:lazycopy/core/settings.dart';



void main() async {



  WidgetsFlutterBinding.ensureInitialized();

  await Settings.loadEnv();
  await Settings().init();


  runApp(const App());
}
