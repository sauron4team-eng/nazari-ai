import 'package:flutter/material.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
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
      body: Column(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Library',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              Text('Manage and summarize your study materials offline'),
              Row(children: [Text('24 Files | 1.2 GB ')]),
            ],
          ),
        ],
      ),
    );
  }
}
