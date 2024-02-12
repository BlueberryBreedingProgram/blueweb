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

class ScorePage extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const ScorePage({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : super(key: key);

  @override
  _ScorePageState createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  bool isLoading = false;
  List<String> filenames = []; 
  String? selectedFile;

  @override
  void initState() {
    super.initState();
    fetchFiles(); 
  }

  
  Future<void> fetchFiles() async {
    FirebaseStorage storage = FirebaseStorage.instance;
    ListResult result = await storage.ref('bluescore/scores/').listAll();
    List<String> files = result.items.map((e) => e.name).toList();
    setState(() {
      filenames = files;
    });
  }

  
  Future<void> downloadFile() async {
    if (selectedFile != null) {
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref('bluescore/scores/$selectedFile');
      String url = await ref.getDownloadURL();
      
      html.AnchorElement(href: url)
        ..setAttribute('download', selectedFile as Object)
        ..click();
    }
  }

  Future<void> pickFile(String type, BuildContext context) async {
    setState(() {
      isLoading = true; 
    });
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      
      List<int>? fileBytes;
      if (kIsWeb) {
        fileBytes = result.files.single.bytes!;
      } else {
        fileBytes = File(result.files.single.path!).readAsBytesSync();
      }

      
      await sendFileToStorage(fileBytes, type, context);
    }
    setState(() {
      isLoading = false; 
    });
  }

  Future<void> sendFileToStorage(List<int> fileBytes, String type, BuildContext context) async {
    try {
      
      String path = '/bluescore/database/' + type + '.csv';

      
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref(path);

      
      await ref.putData(Uint8List.fromList(fileBytes));

      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully uploaded $type CSV')),
      );
    } catch (e) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload $type CSV: $e')),
      );
    }
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 10),
              Text("Processing..."),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BlueScore'),
      ),
      body: Row(
        children: [
          NavigationRailWidget(
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: (int index) =>
                navigateToPage(index, context),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Source Files',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            '• These are the files that will be imported by BlueScore. \n• There is no file schema requirement, BlueScore will auto-adapt to new schemas.',
                            style: TextStyle(fontSize: 22),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            '• BlueScore only inputs/outputs CSV files. \n• It is recommended that you use a website (CloudConvert) to convery Excel to CSV.',
                            style: TextStyle(fontSize: 22),
                          ),
                        ),
                        
                        _buildButton(
                            'Pick Ranks (Breeding Val) CSV', 'ranks', context),
                        _buildButton(
                            'Pick Fruit Quality CSV', 'fq_scores', context),
                        _buildButton('Pick Scores CSV', 'scores', context),
                        _buildButton('Pick Yield CSV', 'yield', context),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Retrieve Scores',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            '• The Lab and Field score files are named based on several factors. \n• The name of the person who scored, the type of file (lab or field), the month, day, and year the scores were uploaded.',
                            style: TextStyle(fontSize: 22),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            '• The available files are in the dropdown below. Select the desired file and press download.',
                            style: TextStyle(fontSize: 22),
                          ),
                        ),
                        DropdownButton<String>(
                          value: selectedFile,
                          items: filenames.map((file) {
                            return DropdownMenuItem(
                              value: file,
                              child: Text(file),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedFile = value;
                            });
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.all(16),
                            ),
                            onPressed: downloadFile,
                            child: Text('Download',
                                style: TextStyle(fontSize: 22)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, String type, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.all(16), 
        ),
        onPressed: () => pickFile(type, context),
        child: Text(text, style: TextStyle(fontSize: 22)), 
      ),
    );
  }
}






