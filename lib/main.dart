

import 'package:flutter/material.dart';
import 'package:accredit/app.dart';
import 'package:accredit/core/settings.dart';



void main() async {



  WidgetsFlutterBinding.ensureInitialized();

  await Settings.loadEnv();
  await Settings().init();


  runApp(const App());
}
