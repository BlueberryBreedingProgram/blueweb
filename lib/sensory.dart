import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'navigation_controller.dart';
import 'navigation_rail_widget.dart';
import 'panel.dart';

class SensoryPage extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const SensoryPage({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : super(key: key);

  @override
  _SensoryPageState createState() => _SensoryPageState();
}

class DataCardModel {
  String? attributeTested;
  String? question;
  String? selectedQuestionType;
  String? customAnswerChoices;
  bool videoCapture = false;

  Map<String, dynamic> toJson() => {
    'attributeTested': attributeTested,
    'question': question,
    'selectedQuestionType': selectedQuestionType,
    'customAnswerChoices': customAnswerChoices,
    'videoCapture': videoCapture,
  };
}

class _SensoryPageState extends State<SensoryPage> {
  final databaseRef = FirebaseDatabase.instance.reference();
  TextEditingController sampleController = TextEditingController();
  TextEditingController samplesPerPanelistController = TextEditingController();
  int selectedIndex = 3; 
  List<Widget> dataCards = [];
  String? selectedQuestionType; 
  List<String?> selectedQuestionTypes = [];
  List<DataCardModel> dataCardModels = [];

  @override
  void initState() {
    super.initState();

    
    databaseRef.child("sensory_sample_nums").once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        String samples = snapshot.value.toString();
        sampleController.text = samples;
      }
    });

    databaseRef.child("samples_per_panelist").once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        String samplesPerPanelist = snapshot.value.toString();
        samplesPerPanelistController.text = samplesPerPanelist;
      }
    });

    databaseRef.child("sensory_questions").once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        
        if (snapshot.value is List<dynamic>) {
          List<dynamic> questionMaps = snapshot.value as List<dynamic>;
          for (Map<dynamic, dynamic> questionMap in questionMaps) {
            DataCardModel model = DataCardModel()
              ..attributeTested = questionMap['attributeTested']
              ..question = questionMap['question']
              ..selectedQuestionType = questionMap['selectedQuestionType']
              ..customAnswerChoices = questionMap['customAnswerChoices']
              ..videoCapture = questionMap['videoCapture'];
            dataCardModels.add(model);
          }
          setState(() {});
        }
      }
    });
  }

  void saveQuestionsToFirebase() {
    List<Map<String, dynamic>> jsonData = [];
    for (DataCardModel model in dataCardModels) {
      jsonData.add(model.toJson());
    }
    databaseRef.child("sensory_questions").set(jsonData);
    final snackBar = SnackBar(content: Text('Questions saved successfully!'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget createDataCard(int index) {
    DataCardModel model = dataCardModels[index];
    
    TextEditingController attributeTestedController = TextEditingController(text: model.attributeTested);
    TextEditingController questionController = TextEditingController(text: model.question);
    TextEditingController customAnswerChoicesController = TextEditingController(text: model.customAnswerChoices);

    return Card(
      key: ValueKey(index),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Question ${index + 1}"),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => removeDataCard(index),
                ),
              ],
            ),
            TextField(
              controller: attributeTestedController,
              decoration: InputDecoration(
                labelText: 'Attribute to be tested ex: Sweetness',
              ),
              onChanged: (String value) {
                model.attributeTested = value; 
              },
            ),
            TextField(
              controller: questionController,
              decoration: InputDecoration(
                labelText: 'Question ex: How much do you LIKE or DISLIKE the Sweetness of the sample',
              ),
              onChanged: (String value) {
                model.question = value; 
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            DropdownButton<String>(
              value: model.selectedQuestionType,
              items: [
                "Rating 1-9 - Dislike to Like",
                "Slider 0-100 - Low to High",
                "Long Form Text Response",
                "Custom Multiple Choice",
                "Non Question Panelist Instruction",
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  model.selectedQuestionType = newValue;
                });
              },
              hint: Text('Question Type'),
            ),
                SizedBox(width: 20),
                if (index != 0) ...[
                Text("Capture Video for AI"),
                Checkbox(
                  value: model.videoCapture,
                  onChanged: (bool? value) {
                    setState(() {
                      model.videoCapture = value ?? false;
                    });
                  },
                ),
                ],
              ],
            ),
            TextField(
              controller: customAnswerChoicesController,
              decoration: InputDecoration(
                labelText: 'Custom Answer Choices - Comma Separated ex: Sweet, Tangy, Sour',
              ),
              onChanged: (String value) {
                model.customAnswerChoices = value;  
              },
            ),
            SizedBox(height:20),
            
          ],
        ),
      ),
    );
  }

  void removeDataCard(int index) {
    setState(() {
      dataCardModels.removeAt(index);
    });
    saveQuestionsToFirebase();
  }


  @override
  Widget build(BuildContext context) {
    final int externalSelectedIndex = widget.selectedIndex;
    return Scaffold(
      appBar: AppBar(
        title: Text('Sensory Panels'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: Colors.green, 
              onPrimary: Colors.white, 
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PanelResultsPage()));
            },
            child: Text('Panel Results'),
          ),
        ],
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
                    controller: sampleController,
                    decoration: InputDecoration(
                      labelText: 'List of Samples Numbers ex:(123, 234, 334, 556)',
                    ),
                  ),
                  SizedBox(height:20),
                  TextField(
                    controller: samplesPerPanelistController,
                    decoration: InputDecoration(
                      labelText: 'Number of Samples Per Panelist ex:(5)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height:20),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:[
                  ElevatedButton(
                    onPressed: () {
                      String formattedSampleNumbers = sampleController.text.replaceAll(RegExp(r"\s+\b|\b\s"), "");
                      databaseRef.child("sensory_sample_nums").set(formattedSampleNumbers);
                      databaseRef.child("samples_per_panelist").set(samplesPerPanelistController.text);
                      final snackBar = SnackBar(content: Text('Data saved successfully!'));
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    },
                    child: Text('Save Sample Information'),
                  ),
                        SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      
                      saveQuestionsToFirebase();
                    },
                    child: Text('Save Question Changes'),
                  ),
                  ]
                  ),
                  SizedBox(height:30),
                  Expanded(
                    child: ListView(
                      children: [
                        
                        for (int index = 0; index < dataCardModels.length; index++)
                          createDataCard(index),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              dataCardModels.add(DataCardModel());
                            });
                          },
                          child: Text('Add a Question'),
                        ),
                        SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () {
                            
                            saveQuestionsToFirebase();
                          },
                          child: Text('Save Question Changes'),
                        ),
                        SizedBox(height: 50),
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
}
