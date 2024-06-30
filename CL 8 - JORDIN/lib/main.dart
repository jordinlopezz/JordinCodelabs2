import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'login.dart';

void main() {
  runApp(ShrineApp());
}

class ShrineApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shrine',
      theme: AppTheme.themeData,
      home: LoginPage(),
    );
  }
}
