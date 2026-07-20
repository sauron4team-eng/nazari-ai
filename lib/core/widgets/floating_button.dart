import 'package:flutter/material.dart';

Widget customFloatingButton({required VoidCallback onPressed}) {
  return FloatingActionButton(
    onPressed: onPressed,
    backgroundColor: Colors.green.shade800,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: const Icon(Icons.add, color: Colors.white, size: 28),
  );
}
