import 'package:flutter/material.dart';

Widget cardWidget(Color? color, Widget? child, {double height = 200}) {
  return Card(
    color: color,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    child: Padding(
      padding: const EdgeInsets.all(10.0),
      child: SizedBox(width: double.infinity, height: height, child: child),
    ),
  );
}
