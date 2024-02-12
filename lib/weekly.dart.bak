import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'navigation_rail_widget.dart';
import 'dart:math';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:csv/csv.dart';


class Weekly extends StatefulWidget {
  @override
  _WeeklyState createState() => _WeeklyState();
}

class _WeeklyState extends State<Weekly> {
  Map<String, Map<int, dynamic>> weeklyData = {};
  final TextEditingController _searchController = TextEditingController();
  int minWeek = 1;
  int maxWeek = 52;
  Future<void>? fetchFuture;

  @override
  void initState() {
    super.initState();
    fetchFuture = fetchData();
  }

  String getMass(dynamic value) {
    if (value != null) {
      Map<String, dynamic> fruitData = value as Map<String, dynamic>;
      String? massValue = fruitData['mass'];
      if (massValue != null && massValue.isNotEmpty) {
        return massValue;
      }
    }
    return 'N/A';
  }

  void generateCsv() {
    List<List<dynamic>> rows = <List<dynamic>>[];
    List<String> columns = ['Genotype', 'Site'];

    for (int i = minWeek; i <= maxWeek; i++) {
      columns.add('Week $i');
    }
    columns.add('Cumulative');
    rows.add(columns);

    for (var entry in weeklyData.entries) {
      List<dynamic> row = <dynamic>[];
      double cumulative = 0;
      final genotypeSite = entry.key.split('*');
      row.add(genotypeSite[0]);
      row.add(genotypeSite[1]);

      for (int week = minWeek; week <= maxWeek; week++) {
        var value = entry.value[week];
        String mass = getMass(value) ?? 'N/A';

        if (mass != 'N/A') {
          cumulative += double.parse(mass);
        }
        row.add(mass);
      }
      row.add(cumulative.toString());
      rows.add(row);
    }

    String csv = const ListToCsvConverter().convert(rows);

    final blob = html.Blob([csv]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..setAttribute('download', 'weekly_yields.csv');
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  void generateExcel() {
    var excel = Excel.createExcel();
    Sheet sheet = excel[excel.getDefaultSheet()!]!;

    List<List<dynamic>> rows = <List<dynamic>>[];
    List<String> columns = ['Genotype', 'Site'];


    for (int i = minWeek; i <= maxWeek; i++) {
      columns.add('Week $i');
    }
    columns.add('Cumulative');
    rows.add(columns);

    for (var entry in weeklyData.entries) {
      List<dynamic> row = <dynamic>[];
      double cumulative = 0; 
      final genotypeSite = entry.key.split('*'); 
      row.add(genotypeSite[0]); 
      row.add(genotypeSite[1]); 

      for (int week = minWeek; week <= maxWeek; week++) {
        var value = entry.value[week];
        String mass = getMass(value) ?? 'N/A';

        if (mass != 'N/A') {
          cumulative += double.parse(mass);
        }
        row.add(mass);
      }
      row.add(cumulative.toString()); 
      rows.add(row);
    }

    
    for (int i = 0; i < rows.length; i++) {
      List<dynamic> row = rows[i];
      for (int j = 0; j < row.length; j++) {
        var cell = sheet.cell(CellIndex.indexByString('${String.fromCharCode(65 + j)}${i + 1}'));
        if (i == 0) { 
          cell.value = row[j].toString();
        } else if (j < 2) { 
          cell.value = row[j].toString();
        } else { 
          var value = row[j];
          if (value != 'N/A') {
            var numberValue = double.tryParse(value);
            cell.value = numberValue ?? value;
          } else {
            cell.value = value;
          }
        }
      }
    }

    
    excel.save(fileName: 'weekly_yields.xlsx');
  }


  Future<void> fetchData() async {
    int currentYear = DateTime.now().year;
    DatabaseReference ref = FirebaseDatabase.instance.reference().child('fruit_quality_$currentYear');
    DataSnapshot snapshot = (await ref.once()).snapshot;

    if (snapshot.value != null) {
      Map<String, dynamic> dataMap = snapshot.value as Map<String, dynamic>;

      minWeek = 0;
      maxWeek = 55;

      dataMap.forEach((key, value) {
        Map<String, dynamic> fruitData = Map<String, dynamic>.from(value);
        String genotype = fruitData['genotype'];
        String site = fruitData['site'];
        int week = int.parse(fruitData['week']);

        String genotypeSiteKey = '$genotype*$site';

        if (!weeklyData.containsKey(genotypeSiteKey)) {
          weeklyData[genotypeSiteKey] = {};
        }

        weeklyData[genotypeSiteKey]![week] = fruitData;

        minWeek = minWeek == 0 ? week : min(minWeek, week);
        maxWeek = maxWeek == 55 ? week : max(maxWeek, week);
      });

      setState(() {});
    }
  }

  int getWeekNumber(DateTime date) {
    int dayOfYear = int.parse(DateFormat('D').format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: fetchFuture,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            int currentWeek = getWeekNumber(DateTime.now());
            List<String> columns = ['Genotype', 'Site'];

            for (int i = minWeek; i <= maxWeek; i++) {
              columns.add('Week $i');
            }

            return Scaffold(
              appBar: AppBar(
                title: Text('Weekly Yield'),
                actions: <Widget>[
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.download, color: Colors.white),
                        SizedBox(width: 4.0),
                        Text(
                          'Download Excel',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    onPressed: generateExcel,
                  ),
                ],
              ),
              body: Padding(
                padding: EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 20.0),
                child: Row(
                  children: [
                    NavigationRailWidget(
                      selectedIndex: 1,
                      onDestinationSelected: (int index) {
                        if (index != 1) Navigator.pop(context, index);
                      },
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Flexible(
                                flex: 6,
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    labelText: 'Search',
                                    border: OutlineInputBorder(),
                                  ),
                                  onSubmitted: (value) {
                                    setState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              showCheckboxColumn: false,
                              columns: columns.map<DataColumn>((item) =>
                                  DataColumn(
                                      label: Text('$item', style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: item == 'Week $currentWeek'
                                              ? Colors.blue
                                              : null))),
                              ).toList()
                                ..add(DataColumn(label: Text('Cumulative'))),
                              
                              rows: weeklyData.entries.map<DataRow?>((entry) {
                                double cumulative = 0; 
                                final searchQuery = _searchController.text.toLowerCase();
                                final genotypeSite = entry.key.split('*'); 
                                if (genotypeSite[0].toLowerCase().contains(searchQuery) || genotypeSite[1].toLowerCase().contains(searchQuery)) {
                                  List<DataCell> dataCells = columns.map<DataCell>((column) {
                                    if (column == 'Genotype') {
                                      return DataCell(Text('${genotypeSite[0]}')); 
                                    } else if (column == 'Site') {
                                      return DataCell(Text('${genotypeSite[1]}')); 
                                    } else {
                                      int week = int.parse(column.split(' ')[1]);
                                      var value = entry.value[week];
                                      String mass = getMass(value); 

                                      if (mass != 'N/A') {
                                        cumulative += double.parse(mass); 
                                      }

                                      return DataCell(
                                        Container(
                                          color: mass == 'N/A' && week == currentWeek ? Colors.yellow : null,
                                          child: Text('$mass'),
                                        ),
                                      );
                                    }
                                  }).toList();

                                  dataCells.add(DataCell(Text(cumulative.toString()))); 

                                  return DataRow(cells: dataCells);
                                }
                                return null; 
                              }).where((item) => item != null).cast<DataRow>().toList(),

                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
    );
  }
}

