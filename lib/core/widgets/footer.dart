import 'package:flutter/material.dart';

Widget customFooter({
  required int selectedIndex,
  required Function(int) onTap,
}) {
  return BottomNavigationBar(
    currentIndex: selectedIndex,
    onTap: onTap,
    type: BottomNavigationBarType.fixed,
    backgroundColor: Colors.white,
    selectedItemColor: Colors.green.shade800,
    unselectedItemColor: Colors.grey[600],
    showSelectedLabels: true,
    showUnselectedLabels: true,
    elevation: 8,
    items: [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(
        icon: Icon(Icons.description),
        label: 'Documents',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.smart_toy),
        label: 'AI Assistant',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Study Tools'),
    ],
  );
}
