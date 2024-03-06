import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';

class BarcodePage extends StatefulWidget {
  @override
  _BarcodePageState createState() => _BarcodePageState();
}

class _BarcodePageState extends State<BarcodePage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _genotypeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _massController = TextEditingController();
  final TextEditingController _numOfBerriesController = TextEditingController();
  final TextEditingController _xBerryMassController = TextEditingController();
  String? _selectedSite;
  List<String> _siteOptions = [];
  String? _selectedStage;
  List<String> _stageOptions = [];
  String? _selectedBlock;
  List<String> _blockOptions = [];
  String? _selectedProject;
  List<String> _projectOptions = [];
  String? _selectedPostHarvest;
  String? _bush;
  final FocusNode _barcodeFocusNode = FocusNode();
  final FocusNode _genotypeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _barcodeController.addListener(_onBarcodeChange);
    _fetchSiteOptions();
    _fetchStageOptions();
    _fetchBlockOptions();
    _fetchProjectOptions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_barcodeFocusNode);
    });
  }

  String _getCurrentYear() {
    return DateTime
        .now()
        .year
        .toString();
  }

  void _onBarcodeChange() async {
    if (_barcodeController.text.length == 7) {
      final barcode = _barcodeController.text;
      final year = _getCurrentYear();
      final dataSnapshot = await _dbRef.child('fruit_quality_$year/$barcode')
          .get();

      // Trigger UI update to show rest of the form fields regardless of data availability.
      setState(() {
        // Default/reset values for the form fields can be set here if needed
        // This ensures that the fields are ready for input even if no data is found
      });

      if (dataSnapshot.exists) {
        final data = dataSnapshot.value as Map<dynamic, dynamic>;
        // Populate form fields with data from the database
        setState(() {
          _genotypeController.text = data['genotype'] ?? '';
          _notesController.text = data['notes'] ?? '';
          _massController.text = data['mass'] ?? '';
          _numOfBerriesController.text = data['numOfBerries'] ?? '';
          _xBerryMassController.text = data['xBerryMass'] ?? '';
          // Dropdowns: Temporarily add nonpersistent option if not in existing options
          _selectedStage = data['stage'] ?? '';
          if (!_stageOptions.contains(_selectedStage)) {
            _stageOptions.add(_selectedStage!); // Temporarily add option
          }
          _selectedSite = data['site'] ?? '';
          if (!_siteOptions.contains(_selectedSite)) {
            _siteOptions.add(_selectedSite!); // Temporarily add option
          }
          _selectedBlock = data['block'] ?? '';
          if (!_blockOptions.contains(_selectedBlock)) {
            _blockOptions.add(_selectedBlock!); // Temporarily add option
          }
          _selectedProject = data['project'] ?? '';
          if (!_projectOptions.contains(_selectedProject)) {
            _projectOptions.add(_selectedProject!); // Temporarily add option
          }
          _selectedPostHarvest = data['postHarvest'] ?? '';
          _bush = data['bush'] ?? '';
        });
      } else {
        Future.delayed(Duration(milliseconds: 100), () {
          if (this.mounted) {
            FocusScope.of(context).requestFocus(_genotypeFocusNode);
          }
        });
      }
    } else {
      // If less than 7 digits are entered, consider resetting form or handling as needed
    }
  }

  void _fetchBlockOptions() async {
    final dataSnapshot = await _dbRef.child('barcode_shortcuts/block').get();
    if (dataSnapshot.exists) {
      final blockString = dataSnapshot.value as String;
      final blocks = blockString.split(',');
      setState(() {
        _blockOptions = blocks;
        if (!_blockOptions.contains(_selectedBlock)) {
          _selectedBlock = null;
        }
      });
    }
  }

  void _fetchProjectOptions() async {
    final dataSnapshot = await _dbRef.child('barcode_shortcuts/project').get();
    if (dataSnapshot.exists) {
      final projectString = dataSnapshot.value as String;
      final projects = projectString.split(',');
      setState(() {
        _projectOptions = projects;
        if (!_projectOptions.contains(_selectedProject)) {
          _selectedProject = null;
        }
      });
    }
  }

  void _fetchSiteOptions() async {
    final dataSnapshot = await _dbRef.child('barcode_shortcuts/site').get();
    if (dataSnapshot.exists) {
      final siteString = dataSnapshot.value as String;
      final sites = siteString.split(',');
      setState(() {
        _siteOptions = sites;
        if (!_siteOptions.contains(_selectedSite)) {
          _selectedSite = null;
        }
      });
    }
  }

  void _fetchStageOptions() async {
    final dataSnapshot = await _dbRef.child('barcode_shortcuts/stage').get();
    if (dataSnapshot.exists) {
      final stageString = dataSnapshot.value as String;
      final stages = stageString.split(',');
      setState(() {
        _stageOptions = stages;
        if (!_stageOptions.contains(_selectedStage)) {
          _selectedStage = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _barcodeController.removeListener(_onBarcodeChange);
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    _genotypeFocusNode.dispose();
    super.dispose();
  }

  String getCurrentTimestamp() {
    final now = DateTime.now();
    return now.toIso8601String(); // This returns a string in the format "2024-01-18T15:40:47.469Z"
  }

  int getWeekOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1, 0, 0);
    final firstMonday = startOfYear.weekday;
    final daysInFirstWeek = 8 - firstMonday;
    final diff = date.difference(startOfYear);
    var days = diff.inDays - daysInFirstWeek;
    var weeks = ((days / 7).ceil());
    if (daysInFirstWeek > 3) {
      weeks += 1;
    }
    return weeks;
  }

  void _updateDatabaseEntry() async {
    if (_barcodeController.text.isEmpty || _barcodeController.text.length != 7 ||
        _genotypeController.text.trim().isEmpty ||
        _selectedStage == null || _selectedStage!.trim().isEmpty ||
        _selectedSite == null || _selectedSite!.trim().isEmpty) {
      // Show a Snackbar with an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode, Genotype, Stage, and Site are required.'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Exit the function to prevent the update
    }

    final String barcode = _barcodeController.text;
    final String year = _getCurrentYear();
    final DateTime now = DateTime.now();
    final int currentWeek = getWeekOfYear(now);
    final String currentTimestamp = getCurrentTimestamp();
    if (barcode.isEmpty || barcode.length != 7) {
      // Handle error: Show an alert dialog or a Snackbar to inform the user.
      return;
    }

    // Prepare the data to be updated.
    Map<String, dynamic> dataToUpdate = {
      'dummyCode': _barcodeController.text,
      'genotype': _genotypeController.text,
      'stage': _selectedStage,
      'site': _selectedSite,
      'block': _selectedBlock,
      'project': _selectedProject,
      'postHarvest': _selectedPostHarvest,
      'bush': _bush,
      'notes': _notesController.text,
      'mass': _massController.text,
      'numOfBerries': _numOfBerriesController.text,
      'xBerryMass': _xBerryMassController.text,
      'dateAndTime': currentTimestamp,
      'week': currentWeek,
    };

    // Update the database entry.
    await _dbRef.child('fruit_quality_$year/$barcode').update(dataToUpdate).then((_) {
      setState(() {
        _barcodeController.clear();
        _genotypeController.clear();
        _massController.clear();
        _numOfBerriesController.clear();
        _xBerryMassController.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus(_barcodeFocusNode);
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Data successfully updated."),
          backgroundColor: Colors.green,
        ),
      );

    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _showSettingsDialog(BuildContext initialContext) async {
    // Fetch data outside of the showDialog to avoid async gap with context.
    final dataSnapshot = await _dbRef.child('barcode_shortcuts').get();
    Map<String, dynamic> values = dataSnapshot.value != null
        ? Map<String, dynamic>.from(dataSnapshot.value as Map)
        : {};

    // Use 'initialContext' only for 'showDialog', which is safe.
    showDialog(
      context: initialContext,
      builder: (dialogContext) {
        // Use 'dialogContext' for references within the dialog
        TextEditingController stageController =
        TextEditingController(text: values['stage'] ?? '');
        TextEditingController siteController =
        TextEditingController(text: values['site'] ?? '');
        TextEditingController blockController =
        TextEditingController(text: values['block'] ?? '');
        TextEditingController projectController =
        TextEditingController(text: values['project'] ?? '');

        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Shortcuts"),
              SizedBox(
                  height:
                  8), // Adds a small space between the title and subtitle
              Text(
                "Create shortcuts for the barcode creation with comma separation.",
                style: TextStyle(
                  fontSize: 12, // Makes the subtitle text small
                  color: Colors
                      .grey, // Optional: Changes the color to make it less prominent than the title
                ),
              ),
              Text(
                "ex: Waldo, Citra, Windsor",
                style: TextStyle(
                  fontSize: 12, // Makes the subtitle text small
                  color: Colors
                      .grey, // Optional: Changes the color to make it less prominent than the title
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                    controller: stageController,
                    decoration: InputDecoration(labelText: "Stage Options")),
                SizedBox(height: 20),
                TextField(
                    controller: siteController,
                    decoration: InputDecoration(labelText: "Site Options")),
                SizedBox(height: 20),
                TextField(
                    controller: blockController,
                    decoration: InputDecoration(labelText: "Block Options")),
                SizedBox(height: 20),
                TextField(
                    controller: projectController,
                    decoration: InputDecoration(labelText: "Project Options")),
                SizedBox(height: 20),
              ],
            ),
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                _dbRef.child('barcode_shortcuts').set({
                  'stage': stageController.text.replaceAll(" ", ""),
                  'site': siteController.text.replaceAll(" ", ""),
                  'block': blockController.text.replaceAll(" ", ""),
                  'project': projectController.text.replaceAll(" ", ""),
                });
                Navigator.of(dialogContext).pop();
                // Reload the dropdown options
                _fetchStageOptions();
                _fetchSiteOptions();
                _fetchBlockOptions();
                _fetchProjectOptions();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showBarcodeWidgets = _barcodeController.text.length != 7;
    return Scaffold(
      appBar: AppBar(
        title: Text("Barcode Menu"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                mainAxisAlignment: showBarcodeWidgets
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 20),
                  if (showBarcodeWidgets) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.barcode_reader,
                            size:
                            200),
                        // Adjusted to qr_code_scanner for demonstration
                        SizedBox(width: 10),
                        // Spacing between icon and text
                        Text(
                          "Please Scan or Enter a Barcode",
                          style: TextStyle(fontSize: 40), // Large text
                        ),
                      ],
                    ),
                    SizedBox(height: 20), // Spacing between text and TextField
                  ],
                  Container(
                    width: 250, // Fixed width for the barcode text field
                    child: TextField(
                      controller: _barcodeController,
                      focusNode: _barcodeFocusNode,
                      decoration: InputDecoration(
                        labelText: "Barcode",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ], // Optional: Only allow numbers
                    ),
                  ),
                  if (!showBarcodeWidgets) ...[
                    SizedBox(height: 20),
                    Container(
                      width: 250,
                      child: TextField(
                        controller: _genotypeController,
                        focusNode: _genotypeFocusNode,
                        decoration: InputDecoration(
                          labelText: "Genotype",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: 250,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration( // Use InputDecoration for labelText
                          labelText: "Stage",
                          // Correct placement of labelText
                          border: OutlineInputBorder(),
                        ), // Stage dropdown
                        value: _selectedStage,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedStage = newValue;
                          });
                        },
                        items: _stageOptions
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: 250,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration( // Use InputDecoration for labelText
                          labelText: "Site",
                          // Correct placement of labelText
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedSite,
                        items: _siteOptions
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSite = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: 250,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration( // Use InputDecoration for labelText
                          labelText: "Block",
                          // Correct placement of labelText
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedBlock,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedBlock = newValue;
                          });
                        },
                        items: _blockOptions
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: 250,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration( // Use InputDecoration for labelText
                          labelText: "Project",
                          // Correct placement of labelText
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedProject,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedProject = newValue;
                          });
                        },
                        items: _projectOptions
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: 250,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration( // Use InputDecoration for labelText
                          labelText: "Post Harvest",
                          // Correct placement of labelText
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedPostHarvest,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedPostHarvest = newValue;
                          });
                        },
                        items: <String>['T1', 'T2']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: 250,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration( // Use InputDecoration for labelText
                          labelText: "Bush",
                          // Correct placement of labelText
                          border: OutlineInputBorder(),
                        ),
                        value: _bush,
                        onChanged: (String? newValue) {
                          setState(() {
                            _bush = newValue;
                          });
                        },
                        items: <String>['1', '2']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: 250,
                      child: TextField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: "Notes",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: 250,
                      child: TextField(
                        controller: _massController,
                        decoration: InputDecoration(
                          labelText: "Mass",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.numberWithOptions(
                            decimal: true), // Enable decimal input
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(
                              r'^\d*\.?\d*')), // Allow digits and decimal point
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: 250,
                      child: TextField(
                        controller: _numOfBerriesController,
                        decoration: InputDecoration(
                          labelText: "Number of Berries",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: 250,
                      child: TextField(
                        controller: _xBerryMassController,
                        decoration: InputDecoration(
                          labelText: "xBerry Mass",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.numberWithOptions(
                            decimal: true), // Enable decimal input
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(
                              r'^\d*\.?\d*')), // Allow digits and decimal point
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 0.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Use min to fit the content of the column
                        mainAxisAlignment: MainAxisAlignment.center, // Center the button vertically
                        children: [
                          SizedBox(height:20),
                          ElevatedButton(
                            onPressed: _updateDatabaseEntry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, // Set the background color to green.
                              padding: EdgeInsets.symmetric(horizontal: 70, vertical: 30), // Make the button extra large
                              textStyle: TextStyle(
                                fontSize: 20, // Increase font size for the text
                                color: Colors.white, // This will be overridden by the Text widget color
                              ),
                            ),
                            child: Text(
                              'Save Code',
                              style: TextStyle(
                                color: Colors.white, // Ensure text color is white
                                fontSize: 30, // Optional, if you want to explicitly set the text size again
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}