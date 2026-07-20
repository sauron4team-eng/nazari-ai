import 'package:flutter/material.dart';

class Navbar extends StatelessWidget {
  const Navbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () {}, icon: Icon(Icons.menu)),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.search)),
          IconButton(
            onPressed: () {},
            icon: IconButton(onPressed: () {}, icon: Icon(Icons.cloud_off)),
          ),
        ],
      ),
    );
  }
}
