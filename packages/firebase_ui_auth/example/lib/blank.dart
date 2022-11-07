import 'package:flutter/material.dart';

class BlankScreen extends StatelessWidget {
  const BlankScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      width: 500,
      height: 500,
      color: Colors.red,
    ));
  }
}
