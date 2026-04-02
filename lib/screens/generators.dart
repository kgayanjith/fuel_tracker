import 'package:flutter/material.dart';
import '../widgets/appbar.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class GeneratorsScreen extends StatefulWidget {
  const GeneratorsScreen({super.key});

  @override
  State<GeneratorsScreen> createState() => _GeneratorsScreenState();
}

class _GeneratorsScreenState extends State<GeneratorsScreen> {
  final List<Map<String, dynamic>> generators = [
    const {
      "name": "Civil Department",
      "location": "Civil",
      "model": "CAT-18KS",
      "liters": 10,
    },
    const {
      "name": "Mechanical Dept",
      "location": "Mechanical",
      "model": "CAT-20K",
      "liters": 15,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Generators",
        leadingIconType: LeadingIconType.notification,
        showInfoIcon: true,
        avatarPath: 'assets/profile.png',
      ),

      // backgroundColor: Colors.white,
      extendBodyBehindAppBar: false,
      body: ListView.builder(
        itemCount: generators.length,
        itemBuilder: (context, index) {
          final generator = generators[index];
          return Slidable(
            key: ValueKey(index),

            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              extentRatio: 0.2,

              children: [
                SlidableAction(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  onPressed: (context) {},
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                  label: 'Delete',

                  flex: 1,
                ),
              ],
            ),

            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                // border: Border(
                //   bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                // ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/placeholder.jpeg',
                      height: 90,
                      width: 110,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          generator['name'],
                          maxLines: 1,

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Location: Civil",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          "Model: CAT-18KS",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          "10 ",
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Ltrs remain',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
