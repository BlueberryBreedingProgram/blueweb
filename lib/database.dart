import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'navigation_controller.dart';
import 'navigation_rail_widget.dart';

class DatabasePage extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const DatabasePage({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : super(key: key);

  @override
  _DatabasePageState createState() => _DatabasePageState();
}

class _DatabasePageState extends State<DatabasePage> {
  TextEditingController _controller = TextEditingController();
  List<List<String>> ranks = [];
  List<List<String>> scores = [];
  List<List<String>> yields = [];
  List<List<String>> fqScores = [];
  List<String> headersRanks = [];
  List<String> headersScores = [];
  List<String> headersYield = [];
  List<String> headersFqScores = [];

  Future<void> searchRanks(String searchQuery) async {
    await searchFirebaseNode('ranks', searchQuery, ranks, headersRanks);
    await searchFirebaseNode('scores', searchQuery, scores, headersScores);
    await searchFirebaseNode('yield', searchQuery, yields, headersYield);
    await searchFirebaseNode(
        'fq_scores', searchQuery, fqScores, headersFqScores);

    setState(() {});
  }

  Future<void> searchFirebaseNode(String nodeName, String searchQuery,
      List<List<String>> data, List<String> headers) async {
    DatabaseReference ref = FirebaseDatabase.instance.reference().child(
        nodeName);

    DataSnapshot snapshot = await ref.once().then((event) => event.snapshot);

    
    headers.clear();
    data.clear();

    
    if (snapshot.value is! List<dynamic>) {
      print('Data format is not a list of maps for node: $nodeName');
      return;
    }

    
    List<dynamic> listData = snapshot.value as List<dynamic>;

    
    if (listData.isNotEmpty && listData.first is Map<dynamic, dynamic>) {
      Map<dynamic, dynamic> headerData = listData.first as Map<dynamic,
          dynamic>;
      headers.addAll(headerData.keys.cast<String>());
    }

    
    for (var value in listData) {
      if (value is Map<dynamic, dynamic>) {
        
        if (value.containsKey('genotype') &&
            value['genotype'].toString().toLowerCase().contains(
                searchQuery.toLowerCase())) {
          List<String> row = [];
          value.forEach((k, v) {
            row.add(v.toString());
          });
          data.add(row);
        }
      }
    }
  }

  Widget buildTable(String title, List<String> headers,
      List<List<String>> data) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 25),
        ),
        data.isNotEmpty
            ? SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            children: [
              
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: headers.map((header) {
                  return Container(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      header,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    width: 100, 
                  );
                }).toList(),
              ),
              
              ...data.map((row) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: row.map((cellContent) {
                    var content = cellContent;
                    try {
                      double numberValue = double.parse(content);
                      if (numberValue == numberValue.toInt()) {
                        content = numberValue.toInt().toString();
                      } else {
                        content = numberValue.toStringAsFixed(2);
                      }
                    } catch (e) {}
                    return Container(
                      padding: EdgeInsets.all(8.0),
                      child: Text(content),
                      width: 100, 
                    );
                  }).toList(),
                );
              }).toList(),
            ],
          ),
        )
            : Container(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Database'),
      ),
      body: Row(
        children: [
          
          NavigationRailWidget(
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: (int index) => navigateToPage(index, context),
          ),
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (value) =>
                        searchRanks(_controller.text.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search by Genotype',
                      suffixIcon: IconButton(
                        onPressed: () => searchRanks(_controller.text.trim()),
                        icon: Icon(Icons.search),
                      ),
                    ),
                    autofocus: false,
                  ),
                ),
                buildTable(
                    'Ranks - ${_controller.text.trim()}', headersRanks, ranks),
                SizedBox(height: 20),
                buildTable('Scores - ${_controller.text.trim()}', headersScores,
                    scores),
                SizedBox(height: 20),
                buildTable(
                    'Yield - ${_controller.text.trim()}', headersYield, yields),
                SizedBox(height: 20),
                buildTable(
                    'FQ Scores - ${_controller.text.trim()}', headersFqScores,
                    fqScores),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}