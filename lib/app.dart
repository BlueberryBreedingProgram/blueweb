import 'dart:html' as html;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'navigation_controller.dart';
import 'navigation_rail_widget.dart';

class AppPage extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppPage({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : super(key: key);

  @override
  _AppPageState createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  
  Future<void> _downloadFile(String appName) async {
    final ref = FirebaseStorage.instance.ref('apps/$appName.apk');
    final url = await ref.getDownloadURL();
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', '$appName.apk')
      ..click();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Apps'),
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
                  _buildAppRow('BlueField'),
                  _buildAppRow('BlueLab'),
                  _buildAppRow('BlueScore'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildAppRow(String appName) {
    return FutureBuilder<DateTime>(
      future: _getFileLastModifiedDate(appName),
      builder: (context, snapshot) {
        String lastModified = 'Fetching...';
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            final dateFormat = DateFormat('MM-dd-y'); 
            lastModified = 'Version: ${dateFormat.format(snapshot.data!.toLocal())}';
          } else {
            lastModified = 'Failed to fetch last modified date';
          }
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appName, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                Text(lastModified, style: TextStyle(fontSize: 12)),
              ],
            ),
            IconButton(
              icon: Icon(Icons.download),
              onPressed: () => _downloadFile(appName),
            ),
          ],
        );
      },
    );
  }

  Future<DateTime> _getFileLastModifiedDate(String appName) async {
    final ref = FirebaseStorage.instance.ref('apps/$appName.apk');
    final metadata = await ref.getMetadata();
    return Future.value(metadata.updated);
  }
}
