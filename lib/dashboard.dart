import 'dart:async';
import 'dart:html';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'fq.dart';
import 'navigation_controller.dart';
import 'navigation_rail_widget.dart';
import 'package:pie_chart/pie_chart.dart';
import 'dart:math';



class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int totalSamples = 0;
  double avgPh = 0.0;
  double avgBrix = 0.0;
  int totalWaldo = 0;
  int totalCitra = 0;
  int totalWindsor = 0;
  double avgMass = 0.0;
  int totalOther = 0;
  double totalMassWaldo = 0.0;
  double totalMassCitra = 0.0;
  double totalMassWindsor = 0.0;
  double totalMassOther = 0.0;
  Map<String, double> genoSiteMasses = {};

  StreamSubscription<DatabaseEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = fetchFruitQualityData();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  StreamSubscription<DatabaseEvent> fetchFruitQualityData() {
    int currentYear = DateTime
        .now()
        .year;
    DatabaseReference ref = FirebaseDatabase.instance.reference().child(
        'fruit_quality_$currentYear');

    return ref.onValue.listen((DatabaseEvent event) {
      DataSnapshot dataSnapshot = event.snapshot;
      Map<dynamic, dynamic>? dataMap = dataSnapshot.value as Map<
          dynamic,
          dynamic>?;

      if (dataMap != null) {
        List<dynamic> dataList = dataMap.values.toList();
        totalSamples = dataList.length;
        double totalPh = 0.0,
            totalBrix = 0.0;
        int countPh = 0,
            countBrix = 0;
        totalWaldo = 0;
        totalCitra = 0;
        totalWindsor = 0;
        double totalMass = 0.0;
        int countMass = 0;


        dataList.forEach((dynamic data) {
          if (data != null) {
            Map<String, dynamic> value = data as Map<String, dynamic>;

            
            var pH = value['pH'];
            var Brix = value['Brix'];

            if (pH != null && pH != "" && pH != "N/A") {
              try {
                totalPh += pH is String ? double.parse(pH) : pH;
                countPh++;
              } catch (e) {
                print('Error parsing pH value: $pH');
              }
            }

            if (Brix != null && Brix != "" && Brix != "N/A") {
              try {
                totalBrix += Brix is String ? double.parse(Brix) : Brix;
                countBrix++;
              } catch (e) {
                print('Error parsing Brix value: $Brix');
              }
            }

            String? mass = value['mass'];
            double? massValue = 0.0;
            if (mass != null && mass != "" && mass != "N/A") {
              try {
                massValue = (mass is String ? double.parse(mass) : mass) as double?;
                totalMass += massValue!;
                countMass++;
              } catch (e) {
                print('Error parsing mass value: $mass');
              }
            }

            String site = value['site'];
            switch (site) {
              case "Waldo":
                totalWaldo++;
                totalMassWaldo += massValue!;
                print('Waldo: $totalWaldo');
                break;
              case "Citra":
                totalCitra++;
                totalMassCitra += massValue!;
                print('Citra: $totalCitra');
                break;
              case "Windsor":
                totalWindsor++;
                totalMassWindsor += massValue!;
                print('Windsor: $totalWindsor');
                break;
              default:
                totalOther++;
                totalMassOther += massValue!;
                print('Other: $totalOther');
                break;
            }

            String? genotype = value['genotype'];
            String? site1 = value['site'];
            if (genotype != null && site1 != null && massValue != null) {
              String key = '$genotype - $site1';
              genoSiteMasses.update(key, (oldValue) => oldValue + massValue!, ifAbsent: () => massValue!);
            }
          }

        });

        setState(() {
          avgPh = countPh > 0 ? totalPh / countPh : 0;
          avgBrix = countBrix > 0 ? totalBrix / countBrix : 0;
          avgMass = countMass > 0 ? totalMass / countMass : 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    int columnCount = width >= 800 ? 2 : 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: Row(
        children: [
          NavigationRailWidget(
            selectedIndex: 0,
            onDestinationSelected: (int index) => navigateToPage(index, context),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    '${DateTime.now().year} Live Season Summary',
                    style: TextStyle(fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columnCount,
                        childAspectRatio: columnCount == 2 ? 3 / 2 : 4 / 2,
                      ),
                      itemCount: 4,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) return buildSummaryCard();
                        if (index == 1) return buildSiteCard();
                        if (index == 2) return buildBarChartCard();
                        if (index == 3) return buildPieChartCard();
                        return Container();  
                      },
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

  Widget buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  children: [
                    TableRow(
                      children: [
                        Text('Total Samples:',
                            style: TextStyle(
                                fontSize: 25, fontWeight: FontWeight.bold)),
                        Center(
                          child: Text('$totalSamples',
                              style:
                              TextStyle(fontSize: 30, color: Colors.green)),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        Text('Average pH:',
                            style: TextStyle(
                                fontSize: 25, fontWeight: FontWeight.bold)),
                        Center(
                          child: Text('${avgPh.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 30, color: Colors.red)),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        Text('Average Brix:',
                            style: TextStyle(
                                fontSize: 25, fontWeight: FontWeight.bold)),
                        Center(
                          child: Text('${avgBrix.toStringAsFixed(2)}',
                              style:
                              TextStyle(fontSize: 30, color: Colors.purple)),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        Text('Average Yield:',
                            style: TextStyle(
                                fontSize: 25, fontWeight: FontWeight.bold)),
                        Center(
                          child: Text('${avgMass.toStringAsFixed(2)}',
                              style:
                              TextStyle(fontSize: 30, color: Colors.brown)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSiteCard() {
    Color getCellColor(int value) {
      if (value == totalWaldo && value == totalCitra && value == totalWindsor)
        return Colors.green; 
      if (value >= totalWaldo && value >= totalCitra && value >= totalWindsor)
        return Colors.green; 
      if (value <= totalWaldo && value <= totalCitra && value <= totalWindsor)
        return Colors.blue; 
      return Colors.black; 
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Samples by Site',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Table(
              children: [
                TableRow(
                  children: [
                    Center(child: Text('Waldo', style: TextStyle(
                        fontSize: 23, fontWeight: FontWeight.bold))),
                    Center(child: Text('Citra', style: TextStyle(
                        fontSize: 23, fontWeight: FontWeight.bold))),
                    Center(child: Text('Windsor', style: TextStyle(
                        fontSize: 23, fontWeight: FontWeight.bold))),
                    Center(child: Text('Other', style: TextStyle(
                        fontSize: 23, fontWeight: FontWeight.bold))),
                    
                  ],
                ),
                TableRow(
                  children: [
                    Center(child: Text('$totalWaldo', style: TextStyle(
                        fontSize: 25, color: getCellColor(totalWaldo)))),
                    Center(child: Text('$totalCitra', style: TextStyle(
                        fontSize: 25, color: getCellColor(totalCitra)))),
                    Center(child: Text('$totalWindsor', style: TextStyle(
                        fontSize: 25, color: getCellColor(totalWindsor)))),
                    Center(child: Text('$totalOther', style: TextStyle(
                        fontSize: 25, color: getCellColor(totalOther)))),
                    
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBarChartCard() {
    
    List<String> sortedKeys = genoSiteMasses.keys.toList()
      ..sort((k1, k2) => (genoSiteMasses[k2] ?? 0).compareTo(genoSiteMasses[k1] ?? 0));

    
    int maxItems = 6;
    Map<String, double> topData = {};
    for (int i = 0; i < maxItems && i < sortedKeys.length; i++) {
      topData[sortedKeys[i]] = genoSiteMasses[sortedKeys[i]]!;
    }

    
    List<Color> colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.brown,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Genotypes by Mass',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: topData.length,
                itemBuilder: (BuildContext context, int index) {
                  String key = sortedKeys[index];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        key,
                        style: TextStyle(
                          fontSize: 25,
                          color: colors[index % colors.length],
                        ),
                      ),
                      Text(
                        topData[key].toString(),
                        style: TextStyle(
                          fontSize: 25,
                          color: colors[index % colors.length],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPieChartCard() {
    double totalMass = totalMassWaldo + totalMassCitra + totalMassWindsor + totalMassOther;
    print(totalMass);
    
    if (totalMass == 0) {
      totalMass = 1; 
    }

    Map<String, double> dataMap = {
      "Waldo": totalMassWaldo / totalMass * 100,
      "Citra": totalMassCitra / totalMass * 100,
      "Windsor": totalMassWindsor / totalMass * 100,
      "Other": totalMassOther / totalMass * 100,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mass by Site',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Center( 
                child: Container(
                  
                  width: 600, 
                  height: 600, 
                  child: PieChart(
                    dataMap: dataMap,
                    chartType: ChartType.ring,
                    legendOptions: LegendOptions(showLegendsInRow: false),
                    chartValuesOptions: ChartValuesOptions(showChartValueBackground: true),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
