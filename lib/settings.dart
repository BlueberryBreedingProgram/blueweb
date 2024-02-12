import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'navigation_controller.dart';
import 'navigation_rail_widget.dart';
import 'dart:html' as html;
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';


class SettingsPage extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  const SettingsPage({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.reference();
  final TextEditingController _whitelistController = TextEditingController();
  final TextEditingController _adminController = TextEditingController();
  bool isLoading = false;


  void _assignAdminRights() {
    final accountsString = _adminController.text;
    final accountsList = accountsString.split(',').map((s) => s.trim()).toList();
    _databaseRef.child('admin_accounts').set(accountsList).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Admin accounts saved successfully')),
      );
    });
  }

  void _loadAdminRights() {
    _databaseRef.child('admin_accounts').once().then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final accountsList = event.snapshot.value as List<dynamic>;
        final accountsString = accountsList.join(', ');
        _adminController.text = accountsString;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadWhitelistedAccounts();
    _loadAdminRights();
  }


  
  void _loadWhitelistedAccounts() {
    _databaseRef.child('whitelisted_accounts').once().then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final accountsList = event.snapshot.value as List<dynamic>;
        final accountsString = accountsList.join(', ');
        _whitelistController.text = accountsString;
      }
    });
  }

  
  void _saveWhitelistedAccounts() {
    final accountsString = _whitelistController.text;
    final accountsList = accountsString.split(',').map((s) => s.trim()).toList();
    _databaseRef.child('whitelisted_accounts').set(accountsList).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Whitelisted accounts saved successfully')),
      );
    });
  }

  Future<void> _uploadFile(String appName) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk'],
    );

    if (result != null) {
      Uint8List? fileBytes = result.files.single.bytes; 
      String fileName = result.files.single.name;

      if (fileBytes != null) { 
        try {
          
          await FirebaseStorage.instance
              .ref('apps/$appName.apk')
              .putData(fileBytes); 

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$appName APK uploaded successfully')),
          );
        } catch (e) {
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload $appName APK')),
          );
        }
      }
    }
  }

  Future<void> _fetchAndUploadCSV() async {
    final List<String> fileNames = ['ranks.csv', 'fq_scores.csv', 'scores.csv', 'yield.csv'];

    for (var fileName in fileNames) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Processing $fileName...')),
      );

      await _processCSVFile(fileName);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All files processed.')),
    );
  }

  Future<void> _processCSVFile(String fileName) async {
    try {
      
      final csvFileRef = FirebaseStorage.instance.ref('bluescore/database/$fileName');
      final data = await csvFileRef.getData();

      if (data != null) {
        final rawData = Utf8Decoder().convert(data);
        final normalizedData = rawData.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
        final List<String> lines = normalizedData.split('\n');

        if (lines.length >= 2) {
          final headers = lines[0].split(',');
          final records = lines.sublist(1)
              .where((line) => line.trim().isNotEmpty)
              .map((line) => line.split(','))
              .toList();

          bool invalidLength = false;
          for (var record in records) {
            if (record.length != headers.length) {
              print("Record with differing field count found: $record");
              invalidLength = true;
              break;
            }
          }

          if (records.isEmpty || invalidLength) {
            return;
          }

          final List<Map<String, dynamic>> jsonData = records.map((record) {
            return Map.fromIterables(headers.cast<String>(), record);
          }).toList();

          await _databaseRef.child(fileName.split('.').first).set(jsonData);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully uploaded $fileName data')),
          );
        }
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload $fileName data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Row(
        children: [
          NavigationRailWidget(
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: (int index) => navigateToPage(index, context),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _whitelistController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Whitelisted Accounts',
                      border: OutlineInputBorder(),
                      hintText: 'Enter email addresses in a comma-separated format',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _saveWhitelistedAccounts,
                    child: Text('Save'),
                  ),
                  TextField(
                    controller: _adminController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Admin Accounts',
                      border: OutlineInputBorder(),
                      hintText: 'Enter email addresses in a comma-separated format',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _assignAdminRights,
                    child: Text('Save'),
                  ),
                  SizedBox(height: 30),
                  Column(
                    children: [
                      Text('Upload App Update Source Files', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => _uploadFile('BlueScore'),
                            child: Text('BlueScore'),
                          ),
                          ElevatedButton(
                            onPressed: () => _uploadFile('BlueLab'),
                            child: Text('BlueLab'),
                          ),
                          ElevatedButton(
                            onPressed: () => _uploadFile('BlueField'),
                            child: Text('BlueField'),
                          ),
                          
                        ],
                      ),
                      SizedBox(height: 30),
                      Column(
                        children: [
                          Text('Web Database File Sync', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ElevatedButton(
                            onPressed: _fetchAndUploadCSV,
                            child: Text('Auto Sync Files with BlueWeb'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
