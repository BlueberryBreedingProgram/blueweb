import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:archive/archive.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PanelResultsPage extends StatefulWidget {
  @override
  _PanelResultsPageState createState() => _PanelResultsPageState();
}

class _PanelResultsPageState extends State<PanelResultsPage> {
  final databaseRef = FirebaseDatabase.instance.reference();
  List<String> panelDates = [];

  @override
  void initState() {
    super.initState();
    retrievePanelNodes();
  }

  void retrievePanelNodes() {
    databaseRef.once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
      values.forEach((key, value) {
        if (key.startsWith('sensorypanel_')) {
          setState(() {
            panelDates.add(key.replaceFirst('sensorypanel_', ''));
          });
        }
      });
    });
  }

  void downloadResponses(String panelDate) async {
    
    final nodeRef = databaseRef.child('sensorypanel_$panelDate');
    final DataSnapshot snapshot = (await nodeRef.once()).snapshot;

    
    if (snapshot != null) {
      
      Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;

      
      List<List<dynamic>> rows = [];

      
      if (values != null && values.isNotEmpty) {
        
        List<dynamic> headers = ["Panelist Name"];
        values.values.first.forEach((k, v) {
          headers.add(k.toString());
        });
        rows.add(headers);

        
        values.forEach((key, value) {
          List<dynamic> row = [];
          row.add(key);  

          
          for (var i = 1; i < headers.length; i++) {
            row.add(value[headers[i]]);
          }

          rows.add(row);
        });

        
        String csvData = const ListToCsvConverter().convert(rows);

        
        final blob = html.Blob([csvData]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..target = 'blank'
          ..download = '$panelDate.csv'
          ..click();
        html.Url.revokeObjectUrl(url);
      }
    }
  }

  Future<void> downloadImages(String date) async {
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preparing images for download...'),
        duration: Duration(seconds: 3),
      ),
    );

    
    List<List<int>> images = await fetchImagesFromFirebaseStorage(date); 

    
    final encoder = ZipEncoder();
    final archive = Archive();

    
    for (int i = 0; i < images.length; i++) {
      final imageBytes = images[i]; 
      archive.addFile(ArchiveFile('image_$i.jpg', imageBytes.length, imageBytes));
    }

    
    final zipFileBytes = encoder.encode(archive);

    
    final blob = html.Blob([zipFileBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..target = 'blank'
      ..download = 'SensoryImages_$date.zip'
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<List<List<int>>> fetchImagesFromFirebaseStorage(String date) async {
    List<List<int>> imageBytesList = [];

    
    Reference ref = FirebaseStorage.instance.ref('SensoryImages_$date');

    
    ListResult result = await ref.listAll();

    
    for (var item in result.items) {
      final bytes = await item.getData();
      imageBytesList.add(bytes as List<int>);
    }

    return imageBytesList;
  }

  String formatFriendlyDate(String date) {
    if (date.length != 8) return date;
    String month = date.substring(0, 2);
    String day = date.substring(2, 4);
    String year = date.substring(4, 8);
    return '$month/$day/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel Results'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sensory Panel Results",
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: panelDates.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(formatFriendlyDate(panelDates[index])),
                            onTap: () {
                              
                            },
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              InkWell(
                                onTap: () {
                                  downloadResponses(panelDates[index]);
                                },
                                child: Chip(
                                  label: Text('Responses'),
                                  avatar: Icon(Icons.download_rounded),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  downloadImages(panelDates[index]);
                                },
                                child: Chip(
                                  label: Text('Download Images'),
                                  avatar: Icon(Icons.download_rounded),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Google Cloud Process DeepFace feature is not yet configured.'),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                },
                                child: Chip(
                                  label: Text('Google Cloud Process DeepFace'),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('DeepFace Merged feature is not yet configured.'),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                },
                                child: Chip(
                                  label: Text('DeepFace Merged'),
                                  avatar: Icon(Icons.download_rounded),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


