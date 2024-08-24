import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parking_admin/data/users.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:parking_admin/details_page.dart';
import 'package:parking_admin/model/notification_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<MapEntry<String, String>> cameraObstructions = [];
  List<MapEntry<String, String>> parkingSpaceObstructions = [];
  bool first = true;
  Future<void> fetchImages() async {
    final firestore = FirebaseFirestore.instance;

    final docSnapshot = await firestore
        .collection('admins')
        .doc('dummy')
        .snapshots()
        .listen((docSnapshot) {
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final camObstructions = data['camera'] as Map<String, dynamic>;
        final pSpaceObstacles = data['parkingObstacle'] as Map<String, dynamic>;

        final newCamObstructions = camObstructions.entries
            .map((entry) => MapEntry(entry.key, entry.value as String))
            .toList();
        final newpObstacles = pSpaceObstacles.entries
            .map((entry) => MapEntry(entry.key, entry.value as String))
            .toList();
        if (!first) {
          print('Entered first check');
          newCamObstructions.forEach((entry) {
            if (!cameraObstructions.contains(entry)) {
              print('Found new key');
              print('New key found: ${entry.key}');
              Fluttertoast.showToast(
                  gravity: ToastGravity.TOP,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 20,
                  msg: 'An obstruction found on camera ${entry.key}');

              // try {
              //   NotificationService.showInstantNotification(
              //       'An Obstruction on Camera', 'Camera : ${entry.key}');
              // } catch (e) {
              //   print('Error showing notif : ${e}');
              // }
            }
          });
          newpObstacles.forEach((entry) async {
            if (!pSpaceObstacles.containsKey(entry.key)) {
              print('Found New Parking Obstacle');
              Fluttertoast.showToast(
                  gravity: ToastGravity.TOP,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 20,
                  msg: 'An obstacle found at Parking slot: ${entry.key}');
              await NotificationService.showInstantNotification(
                  'Parking Obstacle Found', 'Obstacle at slot: ${entry.key}');
            }
          });
        }
        first = false;
        setState(() {
          cameraObstructions = newCamObstructions;
          parkingSpaceObstructions = newpObstacles;
        });
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchImages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount:
                  cameraObstructions.length + parkingSpaceObstructions.length,
              itemBuilder: (context, index) {
                if (index < cameraObstructions.length) {
                  final entry = cameraObstructions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Dismissible(
                      key: Key(entry.key),
                      onDismissed: (direction) async {
                        setState(() {
                          cameraObstructions.removeAt(index);
                        });
                        await FirebaseFirestore.instance
                            .collection('admins')
                            .doc('dummy')
                            .update({
                          'camera.${entry.key}': FieldValue.delete(),
                        });
                      },
                      child: ListTile(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => DetailsPage(
                                    url: entry.value,
                                  )));
                        },
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        tileColor: Colors.blue,
                        title: Text("Obstruction on camera: ${entry.key}"),
                        trailing: Image.network(entry.value),
                      ),
                    ),
                  );
                } else {
                  final parkingIndex = index - cameraObstructions.length;
                  final entry = parkingSpaceObstructions[parkingIndex];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Dismissible(
                      key: Key(entry.key),
                      onDismissed: (direction) async {
                        setState(() {
                          cameraObstructions.removeAt(index);
                        });
                        await FirebaseFirestore.instance
                            .collection('admins')
                            .doc('dummy')
                            .update({
                          'camera.${entry.key}': FieldValue.delete(),
                        });
                      },
                      child: Dismissible(
                        key: Key(entry.key),
                        onDismissed: (direction) async {
                          setState(() {
                            parkingSpaceObstructions.removeAt(index);
                          });
                          await FirebaseFirestore.instance
                              .collection('admins')
                              .doc('dummy')
                              .update({
                            'parkingObstacle.${entry.key}': FieldValue.delete()
                          });
                        },
                        child: ListTile(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => DetailsPage(
                                      url: entry.value,
                                    )));
                          },
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          tileColor: Colors.orange,
                          title:
                              Text('An obstacle in parking slot: ${entry.key}'),
                          trailing: Image.network(entry.value),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          )
        ],
      ),
    );
  }
}
