import 'dart:convert';
import 'dart:html' as html;
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:excel/excel.dart';
import 'navigation_controller.dart';
import 'navigation_rail_widget.dart';
import 'range.dart';
import 'weekly.dart';

class FruitQuality extends StatefulWidget {
  @override
  _FruitQualityState createState() => _FruitQualityState();
}

class _FruitQualityState extends State<FruitQuality> {
  List<Map<String, dynamic>> fruitQualityData = [];
  final TextEditingController _searchController = TextEditingController();
  String? selectedGroupingAttribute;
  Map<String, List<Map<String, dynamic>>> groupedData = {};

  @override
  void initState() {
    super.initState();
    fetchData();
  }
  void refreshData() {
    setState(() {
      fetchData(); 
    });
  }

  Future<List<Map<String, dynamic>>> fetchData() async {
    int currentYear = DateTime.now().year;
    DatabaseReference ref = FirebaseDatabase.instance.reference().child('fruit_quality_$currentYear');
    DataSnapshot snapshot = (await ref.once()).snapshot;
    List<Map<String, dynamic>> fruitQualityData = [];

    if (snapshot.value != null) {
      Map<String, dynamic> dataMap = snapshot.value as Map<String, dynamic>;
      dataMap.forEach((key, value) {
        fruitQualityData.add(Map<String, dynamic>.from(value));
      });

      
      fruitQualityData.sort((a, b) => DateTime.parse(b['dateAndTime']).compareTo(DateTime.parse(a['dateAndTime'])));
    }

    this.fruitQualityData = fruitQualityData;
    groupDataByAttribute();
    return fruitQualityData;
  }

  void groupDataByAttribute() {
    if (selectedGroupingAttribute != null) {
      groupedData.clear();
      for (var item in fruitQualityData) {
        String key = item[selectedGroupingAttribute] ?? 'N/A';
        if (groupedData[key] == null) groupedData[key] = [];
        groupedData[key]!.add(item);
      }
    }
  }

  Future<void> generateCsv() async {
    int currentYear = DateTime.now().year;
    DatabaseReference ref = FirebaseDatabase.instance.reference().child('fruit_quality_$currentYear');
    DatabaseEvent snapshot = await ref.once();

    List<List<dynamic>> rows = <List<dynamic>>[
      [
        'dummyCode',
        'genotype',
        'site',
        'block',
        'stage',
        'project',
        'box',
        'bush',
        'notes',
        'mass',
        'xBerryMass',
        'numOfBerries',
        'pH',
        'Brix',
        'Juice Mass',
        'TTA',
        'ml Added',
        'dateAndTime',
        'week',
        'avgFirmness',
        'avgDiameter',
        'sdFirmness',
        'sdDiameter',
      ],
    ];

    if (snapshot.snapshot != null) {
      Map<String, dynamic> dataMap = snapshot.snapshot.value as Map<String, dynamic>;
      dataMap.forEach((key, value) {
        Map<String, dynamic> fruitQualityMap = Map<String, dynamic>.from(value);

        List<dynamic> row = [];
        row.add(fruitQualityMap['dummyCode']);
        row.add(fruitQualityMap['genotype']);
        row.add(fruitQualityMap['site']);
        row.add(fruitQualityMap['block']);
        row.add(fruitQualityMap['stage']);
        row.add(fruitQualityMap['project']);
        row.add(fruitQualityMap['box']);
        row.add(fruitQualityMap['bush']);
        row.add(fruitQualityMap['notes']);
        row.add(fruitQualityMap['mass']);
        row.add(fruitQualityMap['xBerryMass']);
        row.add(fruitQualityMap['numOfBerries']);
        row.add(fruitQualityMap['pH']);
        row.add(fruitQualityMap['Brix']);
        row.add(fruitQualityMap['Juice Mass']);
        row.add(fruitQualityMap['TTA']);
        row.add(fruitQualityMap['ml Added']);
        row.add(fruitQualityMap['dateAndTime']);
        row.add(fruitQualityMap['week']);
        row.add(fruitQualityMap['avgFirmness'] ?? ''); 
        row.add(fruitQualityMap['avgDiameter'] ?? ''); 
        row.add(fruitQualityMap['sdFirmness'] ?? '');  
        row.add(fruitQualityMap['sdDiameter'] ?? '');  
        rows.add(row);
      });
    }

    String csv = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor =
    html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = 'fruit_quality.csv';
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  dynamic convertToNumber(dynamic value) { 
    if (value == null) return null; 
    var number = num.tryParse(value.toString());
    return number ?? value;
  }

  Future<void> generateExcel() async {
    int currentYear = DateTime.now().year;
    DatabaseReference ref = FirebaseDatabase.instance.reference().child('fruit_quality_$currentYear');
    DatabaseEvent event = await ref.once(); 
    DataSnapshot snapshot = event.snapshot;

    var excel = Excel.createExcel(); 
    Sheet sheet = excel[excel.getDefaultSheet()!]!;

    List<List<dynamic>> rows = <List<dynamic>>[
      [
        'dummyCode',
        'genotype',
        'site',
        'block',
        'stage',
        'project',
        'box',
        'bush',
        'notes',
        'mass',
        'xBerryMass',
        'numOfBerries',
        'pH',
        'Brix',
        'Juice Mass',
        'TTA',
        'ml Added',
        'dateAndTime',
        'week',
        'avgFirmness',
        'avgDiameter',
        'sdFirmness',
        'sdDiameter',
      ],
    ];

    if (snapshot.value != null) {
      print('Snapshot value exists!');
      Map<String, dynamic> dataMap = snapshot.value as Map<String, dynamic>;
      print('DataMap: $dataMap');
      dataMap.forEach((key, value) {
        Map<String, dynamic> fruitQualityMap = Map<String, dynamic>.from(value);
        List<dynamic> row = []; 
        row.add(convertToNumber(fruitQualityMap['dummyCode']));
        row.add(fruitQualityMap['genotype']);
        row.add(fruitQualityMap['site']);
        row.add(fruitQualityMap['block']);
        row.add(fruitQualityMap['stage']);
        row.add(fruitQualityMap['project']);
        row.add(convertToNumber(fruitQualityMap['box']));
        row.add(convertToNumber(fruitQualityMap['bush']));
        row.add(fruitQualityMap['notes']);
        row.add(convertToNumber(fruitQualityMap['mass']));
        row.add(convertToNumber(fruitQualityMap['xBerryMass']));
        row.add(convertToNumber(fruitQualityMap['numOfBerries']));
        row.add(convertToNumber(fruitQualityMap['pH']));
        row.add(convertToNumber(fruitQualityMap['Brix']));
        row.add(convertToNumber(fruitQualityMap['Juice Mass']));
        row.add(convertToNumber(fruitQualityMap['TTA']));
        row.add(convertToNumber(fruitQualityMap['ml Added']));
        row.add(convertToNumber(fruitQualityMap['dateAndTime']));
        row.add(convertToNumber(fruitQualityMap['week']));
        row.add(convertToNumber(fruitQualityMap['avgFirmness']) ?? '');
        row.add(convertToNumber(fruitQualityMap['avgDiameter']) ?? '');
        row.add(convertToNumber(fruitQualityMap['sdFirmness']) ?? '');
        row.add(convertToNumber(fruitQualityMap['sdDiameter']) ?? '');
        rows.add(row);
      });
    }

    
    for (int i = 0; i < rows.length; i++) {
      List row = rows[i];
      for (int j = 0; j < row.length; j++) {
        sheet.cell(CellIndex.indexByString('${String.fromCharCode(65 + j)}${i + 1}')).value = row[j]; 
      }
    }

    excel.save(fileName: 'fruit_quality.xlsx');
  }

  List<List<dynamic>> rows = <List<dynamic>>[
    [
      'dummyCode',
      'genotype',
      'site',
      'block',
      'stage',
      'project',
      'box',
      'bush',
      'notes',
      'mass',
      'xBerryMass',
      'numOfBerries',
      'pH',
      'Brix',
      'Juice Mass',
      'TTA',
      'ml Added',
      'dateAndTime',
      'week',
      'avgFirmness',
      'avgDiameter',
      'sdFirmness',
      'sdDiameter',
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fruit Quality'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: refreshData,
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_view_week, color: Colors.white),
                SizedBox(width: 4.0),
                Text(
                  'Weekly Yield',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Weekly()),
              );
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.data_usage, color: Colors.white),
                SizedBox(width: 4.0),
                Text(
                  'Accepted Ranges',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RangePage()),
              );
            },
          ),
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
        padding: EdgeInsets.fromLTRB(0.0, 20.0, 16.0, 20.0),
        child: Row(
          children: [
            NavigationRailWidget(
              selectedIndex: 1,
              onDestinationSelected: (int index) => navigateToPage(index, context),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchData(),
                builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    return Column(
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
                            Padding(
                              padding: const EdgeInsets.only(left: 10.0),  
                              child: Text('Group By: '),
                            ),
                            DropdownButton<String>(
                              hint: Text('None'),
                              value: selectedGroupingAttribute,
                              items: rows[0]
                                  .map<DropdownMenuItem<String>>(
                                      (attribute) => DropdownMenuItem<String>(
                                    value: attribute,
                                    child: Text(attribute),
                                  ))
                                  .toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedGroupingAttribute = newValue;
                                  groupDataByAttribute();
                                });
                              },
                            ),
                          ],
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            showCheckboxColumn: false,
                            columns: rows[0].map<DataColumn>((item) =>
                                DataColumn(label: Text('$item', style: TextStyle(fontWeight: FontWeight.bold)))).toList(),
                            rows: selectedGroupingAttribute == null
                                ? snapshot.data!
                                .where((item) {
                              final searchQuery = _searchController.text.toLowerCase();
                              return item['dummyCode'].toLowerCase().contains(searchQuery) ||
                                  item['genotype'].toLowerCase().contains(searchQuery) ||
                                  item['site'].toLowerCase().contains(searchQuery) ||
                                  item['block'].toLowerCase().contains(searchQuery) ||
                                  item['stage'].toLowerCase().contains(searchQuery) ||
                                  item['project'].toLowerCase().contains(searchQuery);
                            })
                                .map<DataRow>((item) {
                              return DataRow(
                                cells: rows[0]
                                    .map<DataCell>((column) =>
                                    DataCell(Text('${item[column] ?? 'N/A'}')))
                                    .toList(),
                                onSelectChanged: (bool? selected) {
                                  if (selected ?? false) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Edit Row'),
                                              TextButton.icon(
                                                icon: Icon(Icons.delete, color: Colors.red),
                                                label: Text('Delete Entry', style: TextStyle(color: Colors.red)),
                                                onPressed: () async {
                                                  
                                                  int currentYear = DateTime.now().year;
                                                  DatabaseReference ref = FirebaseDatabase.instance.reference().child('fruit_quality_$currentYear');
                                                  await ref.child(item['dummyCode']).remove();
                                                  Navigator.of(context).pop(); 
                                                  fruitQualityData = await fetchData();
                                                  setState(() {});
                                                },
                                              ),
                                            ],
                                          ),
                                          content: Container(
                                            height: 350,
                                            width: 300,
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: rows[0].length,
                                              itemBuilder: (BuildContext context, int index) {
                                                return TextField(
                                                  controller: TextEditingController()..text = (item[rows[0][index]] ?? 'N/A'),
                                                  decoration: InputDecoration(labelText: rows[0][index]),
                                                  onChanged: (value) {
                                                    item[rows[0][index]] = value;
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              child: Text('Save'),
                                              onPressed: () async {
                                                int currentYear = DateTime.now().year;
                                                DatabaseReference ref = FirebaseDatabase.instance.reference().child('fruit_quality_$currentYear');
                                                ref.child(item['dummyCode']).set(item);
                                                Navigator.of(context).pop();
                                                fruitQualityData = await fetchData();
                                                setState(() {});
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                },
                              );
                            })
                                .toList()
                                : groupedData.entries
                                .expand((entry) {
                              return entry.value.where((item) {
                                final searchQuery = _searchController.text.toLowerCase();
                                return item['dummyCode'].toLowerCase().contains(searchQuery) ||
                                    item['genotype'].toLowerCase().contains(searchQuery) ||
                                    item['site'].toLowerCase().contains(searchQuery) ||
                                    item['block'].toLowerCase().contains(searchQuery) ||
                                    item['stage'].toLowerCase().contains(searchQuery) ||
                                    item['project'].toLowerCase().contains(searchQuery);
                                
                              }).map<DataRow>((item) {
                                return DataRow(
                                  cells: rows[0]
                                      .map<DataCell>((column) => DataCell(Text('${item[column] ?? 'N/A'}')))
                                      .toList(),
                                  onSelectChanged: (bool? selected) {
                                    if (selected ?? false) {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('Edit Row'),
                                                TextButton.icon(
                                                  icon: Icon(Icons.delete, color: Colors.red),
                                                  label: Text('Delete Entry', style: TextStyle(color: Colors.red)),
                                                  onPressed: () async {
                                                    int currentYear = DateTime.now().year;
                                                    DatabaseReference ref = FirebaseDatabase.instance.reference().child('fruit_quality_$currentYear');
                                                    await ref.child(item['dummyCode']).remove();
                                                    Navigator.of(context).pop(); 
                                                    fruitQualityData = await fetchData();
                                                    setState(() {});
                                                  },
                                                ),
                                              ],
                                            ),
                                            content: Container(
                                              height: 350,
                                              width: 300,
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                itemCount: rows[0].length,
                                                itemBuilder: (BuildContext context, int index) {
                                                  return TextField(
                                                    controller: TextEditingController()..text = (item[rows[0][index]] ?? 'N/A'),
                                                    decoration: InputDecoration(labelText: rows[0][index]),
                                                    onChanged: (value) {
                                                      item[rows[0][index]] = value;
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text('Save'),
                                                onPressed: () async {
                                                  int currentYear = DateTime.now().year;
                                                  DatabaseReference ref = FirebaseDatabase.instance.reference().child('fruit_quality_$currentYear');
                                                  ref.child(item['dummyCode']).set(item);
                                                  Navigator.of(context).pop();
                                                  fruitQualityData = await fetchData();
                                                  setState(() {});
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  },
                                );
                              });
                            })
                                .toList(),
                          ),
                        ),

                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
