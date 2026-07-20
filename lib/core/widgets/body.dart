import 'package:flutter/material.dart';
import 'package:nazariai/core/widgets/card.dart';
import 'package:nazariai/core/widgets/card_doc.dart';
import 'package:nazariai/core/widgets/floating_button.dart';
import 'package:nazariai/core/widgets/text_field.dart';
import 'package:nazariai/core/widgets/footer.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ----------------------Add the app bar------------------------
      appBar: AppBar(
        title: Text('NazariAI', style: TextStyle(color: Colors.green.shade800)),
        leading: IconButton(onPressed: () {}, icon: Icon(Icons.menu)),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: Icon(Icons.cloud_off)),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
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
              SizedBox(height: 10),
              searchFiled(),
              SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'All',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'PDFs',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Documents',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              ),
              SizedBox(height: 10),
              // --------------------Cards-----------------------------------
              cardWidget(
                Colors.green.shade600,
                Text('AI Readiness'),
                height: 180,
              ),
              SizedBox(height: 10),
              cardWidget(Colors.white, Text('Weekly Progress'), height: 180),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recently Added',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              // --------------------Document Cards-----------------------------------
              cardDocWidget(
                title: 'Document Title',
                subtitle: 'Document Subtitle',
                color: Colors.lightBlue,
                icon: Icons.insert_drive_file,
              ),
              SizedBox(height: 10),
              cardDocWidget(
                title: 'Document Title',
                subtitle: 'Document Subtitle',
                color: Colors.lightBlue,
                icon: Icons.insert_drive_file,
              ),
              SizedBox(height: 10),
              cardDocWidget(
                title: 'Document Title',
                subtitle: 'Document Subtitle',
                color: Colors.lightBlue,
                icon: Icons.insert_drive_file,
              ),
            ],
          ),
        ),
      ),

      // ----------------------Add the floating action button------------------------
      floatingActionButton: customFloatingButton(
        onPressed: () {
          // Handle button press
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // ----------------------Add the custom footer--------
      bottomNavigationBar: customFooter(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
