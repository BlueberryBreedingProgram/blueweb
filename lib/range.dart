import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class RangePage extends StatefulWidget {
  @override
  _RangePageState createState() => _RangePageState();
}

class _RangePageState extends State<RangePage> {
  final TextEditingController _phMinController = TextEditingController();
  final TextEditingController _phMaxController = TextEditingController();
  final TextEditingController _brixMinController = TextEditingController();
  final TextEditingController _brixMaxController = TextEditingController();
  final TextEditingController _juiceMassMinController = TextEditingController();
  final TextEditingController _juiceMassMaxController = TextEditingController();
  final TextEditingController _ttaMinController = TextEditingController();
  final TextEditingController _ttaMaxController = TextEditingController();
  final TextEditingController _mlAddedMinController = TextEditingController();
  final TextEditingController _mlAddedMaxController = TextEditingController();

  final DatabaseReference databaseReference = FirebaseDatabase.instance.reference();

  
  void _saveData() async {
    try {
      Map<String, dynamic> data = {
        'ph_min': _phMinController.text,
        'ph_max': _phMaxController.text,
        'brix_min': _brixMinController.text,
        'brix_max': _brixMaxController.text,
        'juice mass_min': _juiceMassMinController.text,
        'juice mass_max': _juiceMassMaxController.text,
        'tta_min': _ttaMinController.text,
        'tta_max': _ttaMaxController.text,
        'ml added_min': _mlAddedMinController.text,
        'ml added_max': _mlAddedMaxController.text,
      };

      await databaseReference.child('accepted_ranges').set(data);

      print('Data saved successfully');

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Changes Saved to Database"),
            content: Text("The Fruit Quality Tablets will follow these ranges"),
            actions: <Widget>[
              TextButton(
                child: Text("Ok"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Failed to save data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await databaseReference.child('accepted_ranges').once().then((DatabaseEvent event) {
        if (event.snapshot.value != null) {
          var data = event.snapshot.value as Map<String, dynamic>;
          _phMinController.text = data['ph_min'];
          _phMaxController.text = data['ph_max'];
          _brixMinController.text = data['brix_min'];
          _brixMaxController.text = data['brix_max'];
          _juiceMassMinController.text = data['juice mass_min'];
          _juiceMassMaxController.text = data['juice mass_max'];
          _ttaMinController.text = data['tta_min'];
          _ttaMaxController.text = data['tta_max'];
          _mlAddedMinController.text = data['ml added_min'];
          _mlAddedMaxController.text = data['ml added_max'];
        }
      });
    } catch (e) {
      print('Failed to load data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fruit Quality App Range Parameters'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: <Widget>[
          
          ...(_createControllers().entries.map((entry) => FractionallySizedBox(
            widthFactor: 0.5,
            child: TextField(
              controller: entry.value,
              decoration: InputDecoration(
                labelText: entry.key,
              ),
              keyboardType: TextInputType.number,
            ),
          ))),
          Padding(
            padding: EdgeInsets.only(top: 16.0),  
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: ElevatedButton(
                onPressed: _saveData,
                child: Text('Save'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  Map<String, TextEditingController> _createControllers() {
    return {
      'ph_min': _phMinController,
      'ph_max': _phMaxController,
      'brix_min': _brixMinController,
      'brix_max': _brixMaxController,
      'juice_mass_min': _juiceMassMinController,
      'juice_mass_max': _juiceMassMaxController,
      'tta_min': _ttaMinController,
      'tta_max': _ttaMaxController,
      'ml added_min': _mlAddedMinController,
      'ml added_max': _mlAddedMaxController,
    };
  }
}
