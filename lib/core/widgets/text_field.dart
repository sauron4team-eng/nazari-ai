import 'package:flutter/material.dart';

Widget searchFiled() {
  return TextField(
    decoration: InputDecoration(
      hintText: 'Filter by name or topic',
      prefixIcon: Icon(Icons.filter_list),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.grey[200],
    ),
  );
}
