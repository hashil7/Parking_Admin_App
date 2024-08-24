import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRPage extends StatelessWidget {
  QRPage({super.key});
  int num = 1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MobileScanner(
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          returnImage: true,
        ),
        onDetect: (capture) async {
          final List<Barcode> barcodes = capture.barcodes;
          final Uint8List? image = capture.image;

          if (barcodes.isNotEmpty) {
            final String uid = barcodes.first.rawValue?.trim() ?? '';

            if (uid.isNotEmpty) {
              final FirebaseFirestore firestore = FirebaseFirestore.instance;

              try {
                final DocumentSnapshot document =
                    await firestore.collection('users').doc(uid).get();

                if (document.exists) {
                  Timestamp? bookingTime =
                      (document.data() as Map<String, dynamic>)['bookingTime'];
                  int? timeParked =
                      (document.data() as Map<String, dynamic>)['timeParked'];
                  if (bookingTime != null) {
                    Duration timeToScan =
                        DateTime.timestamp().difference(bookingTime.toDate());
                    try {
                      await firestore.collection('users').doc(uid).update({
                        'bookingTime': FieldValue.delete(),
                      });
                      if (timeToScan.inMinutes < 30) {
                        await firestore.collection('users').doc(uid).update({
                          'parkingTime': FieldValue.serverTimestamp(),
                        });
                      } else {
                        Fluttertoast.showToast(msg: 'Scanned after 30 mins');
                      }
                      await firestore
                          .collection('admins')
                          .doc('dummy')
                          .update({'$num': '$uid'});
                      
                      print('Updated user $uid with parking time.');
                      Fluttertoast.showToast(
                          msg: 'Updated user $uid with parking time.');
                    } catch (error) {
                      print('Error updating document: $error');
                      Fluttertoast.showToast(
                          msg: 'Error updating document: $error');
                    }

                    Timestamp parkingTime = (document.data()
                        as Map<String, dynamic>)['parkingTime'];
                    Duration timeParked =
                        DateTime.timestamp().difference(parkingTime.toDate());

                    try {
                      await firestore
                          .collection('users')
                          .doc(uid)
                          .update({'timeParked': timeParked.inSeconds});
                      Fluttertoast.showToast(msg: 'Added $uid timeParked ');
                    } catch (e) {
                      print('Error updating document: $e');
                      Fluttertoast.showToast(
                          msg: 'Error updating document: $e');
                    }
                  } else if (timeParked != null) {
                    await firestore.collection('users').doc(uid).update({
                      'secondScan': true,
                    });
                  } else {
                    print('No booking time found for user $uid');
                    Fluttertoast.showToast(
                        msg: 'No booking time found for user $uid');
                  }
                } else {
                  print('No user found with uid $uid');
                  Fluttertoast.showToast(msg: 'No user found with uid $uid');
                }
              } catch (error) {
                print('Error fetching user document: $error');
                Fluttertoast.showToast(
                    msg: 'Error fetching user document: $error');
              }
            }
            if (image != null) {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(uid),
                    content: Image(image: MemoryImage(image)),
                  );
                },
              );
            }
          }
        },
      ),
    );
  }
}
