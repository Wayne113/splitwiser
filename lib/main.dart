import 'package:flutter/material.dart';
import 'splitwiser/Group/group_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Delay launch screen
  await Future.delayed(Duration(seconds: 2));

  runApp(
    MaterialApp(
      home: GroupPage(),
      theme: ThemeData(primaryColor: Color(0xFF7F55FF)),
      debugShowCheckedModeBanner: false,
    ),
  );
}
