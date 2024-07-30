import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Spiral',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color.fromARGB(255, 0, 74, 138),
            brightness: Brightness.dark,
          ),
        ),
        home: HomePage(),
      ),
    );
  }
}


class AppState extends ChangeNotifier {
  List<String> schools = [];
  List<List<Essay>> essays = [];
  int selectedSchoolIndex = 0;

  AppState() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final schoolsData = prefs.getStringList('schools') ?? [];
    final essaysData = prefs.getStringList('essays') ?? [];

    if (schoolsData.isEmpty || essaysData.isEmpty) {
      // Initialize with default data if there's no saved data
      schools = ['Default School'];
      essays = [[]];
    } else {
      schools = schoolsData;
      essays = essaysData.map((essayListJson) {
        List<dynamic> essayList = jsonDecode(essayListJson);
        return essayList.map((essayJson) => Essay.fromJson(essayJson)).toList();
      }).toList();
    }

    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('schools', schools);
    prefs.setStringList(
      'essays',
      essays.map((essayList) => jsonEncode(essayList.map((e) => e.toJson()).toList())).toList(),
    );
  }

  void addSchool() {
    schools.add('New School');
    essays.add([]);
    _saveData();
    notifyListeners();
  }

  void addEssay(Essay essay) {
    if (selectedSchoolIndex >= 0 && selectedSchoolIndex < essays.length) {
      essays[selectedSchoolIndex].add(essay);
      _saveData();
      notifyListeners();
    }
  }

  void updateSchoolName(int index, String newName) {
    if (index >= 0 && index < schools.length) {
      schools[index] = newName;
      _saveData();
      notifyListeners();
    }
  }

  void updateEssay(int schoolIndex, int essayIndex, String newPrompt, String newResponse, {int? minWords, int? maxWords}) {
    if (schoolIndex >= 0 && schoolIndex < essays.length && essayIndex >= 0 && essayIndex < essays[schoolIndex].length) {
      essays[schoolIndex][essayIndex].prompt = newPrompt;
      essays[schoolIndex][essayIndex].response = newResponse;
      if (minWords != null) essays[schoolIndex][essayIndex].minWords = minWords;
      if (maxWords != null) essays[schoolIndex][essayIndex].maxWords = maxWords;
      _saveData();
      notifyListeners();
    }
  }

  void selectSchool(int index) {
    if (index >= 0 && index < schools.length) {
      selectedSchoolIndex = index;
      notifyListeners();
    }
  }

  void deleteEssay(int schoolIndex, int essayIndex) {
  if (schoolIndex >= 0 && schoolIndex < essays.length && essayIndex >= 0 && essayIndex < essays[schoolIndex].length) {
    essays[schoolIndex].removeAt(essayIndex);
    _saveData();
    notifyListeners();
  }
}
}


class Essay {
  String prompt;
  String response;
  int minWords;
  int maxWords;

  Essay({required this.prompt, required this.response, this.minWords = 0, this.maxWords = 0});

  factory Essay.fromJson(Map<String, dynamic> json) {
    return Essay(
      prompt: json['prompt'],
      response: json['response'],
      minWords: json['minWords'],
      maxWords: json['maxWords'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prompt': prompt,
      'response': response,
      'minWords': minWords,
      'maxWords': maxWords,
    };
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer.withAlpha(150),
      body: Row(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: SizedBox(
                width: 200,
                child: Column(
                  children: [
                    Expanded(
                      
                      child: ListView.builder(
                        
                        itemCount: context.watch<AppState>().schools.length,
                        itemBuilder: (context, index) {
                          var school = context.watch<AppState>().schools[index];
                          var isSelected = context.watch<AppState>().selectedSchoolIndex == index;
                          
                          return InkWell(
                            onTap: () {
                              context.read<AppState>().selectSchool(index);
                            },
                            child: Container(
                              color: isSelected ? Theme.of(context).primaryColor: Colors.transparent,
                              padding: const EdgeInsets.all(15.0),
                              child: Text(
                                school,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FloatingActionButton(
                        onPressed: () {
                          context.read<AppState>().addSchool();
                        },
                        child: Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).primaryColor,
              child: EssaysView(),
            ),
          ),
        ],
      ),
    );
  }
}


class EssaysView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    // Initialize essays as an empty list
    List<Essay> essays = [];

    // Check if selectedSchoolIndex is within bounds
    if (appState.schools.isNotEmpty &&
        appState.selectedSchoolIndex >= 0 &&
        appState.selectedSchoolIndex < appState.essays.length) {
      essays = appState.essays[appState.selectedSchoolIndex];
    }

    // Use a default value if the school name is out of bounds
    var schoolName = appState.schools.isNotEmpty
        ? appState.schools[appState.selectedSchoolIndex]
        : 'Default School';
    
    var schoolNameController = TextEditingController(text: schoolName);

    return Expanded(
      child: ListView.builder(
        itemCount: essays.length + 2, // +2 for the school name and the "Add Essay" button
        itemBuilder: (context, index) {
          if (index == 0) {
  // First item is the school name text field
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Focus(
                  onFocusChange: (hasFocus) {
                    if (!hasFocus) {
                      context.read<AppState>().updateSchoolName(
                        appState.selectedSchoolIndex,
                        schoolNameController.text,
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity, // Makes the TextField take up the full width of its parent
                    child: TextField(
                      style: TextStyle(fontSize: 40.0, height: 2.0),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.0), // Adds horizontal padding inside the TextField
                      ),
                      controller: schoolNameController,
                      textAlign: TextAlign.center, // Centers the text inside the TextField
                    ),
                  ),
                ),
              ),
            );
          }

          if (index == essays.length + 1) {
            // Last item is the "Add Essay" button
            return Padding(
              padding: const EdgeInsets.fromLTRB(16 + 30, 8, 16 + 30, 0),
              child: FloatingActionButton(
                onPressed: () {
                  _showEditPromptDialog(context, appState, -1); // Show dialog for adding a new essay
                },
                child: Icon(Icons.add),
              ),
            );
          }

          // Adjust the index for accessing essays
          var essay = essays[index - 1];
          var responseController = TextEditingController(text: essay.response);
          int wordCount = essay.response.split(' ').where((word) => word.isNotEmpty).length;

          return Padding(
            padding: const EdgeInsets.fromLTRB(13 + 30, 5.5, 13 + 30, 5.5),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            essay.prompt,
                            style: TextStyle(fontSize: 20.0),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            _showEditPromptDialog(context, appState, index - 1);
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Min: ${essay.minWords}, Max: ${essay.maxWords}',
                          style: TextStyle(fontSize: 12.0, color: Colors.grey),
                        ),
                        SizedBox(width: 15),
                        Text(
                          '$wordCount',
                          style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 30.0),
                    Focus(
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) {
                          context.read<AppState>().updateEssay(
                            appState.selectedSchoolIndex,
                            index - 1,
                            essay.prompt,
                            responseController.text,
                          );
                        }
                      },
                      child: TextField(
                        controller: responseController,
                        maxLines: null,
                        decoration: InputDecoration(
                          border: InputBorder.none, // Removes the underline
                          contentPadding: EdgeInsets.zero, // Optional: Adjusts padding if needed
                        ),
                      ),
                    )

                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditPromptDialog(BuildContext context, AppState appState, int essayIndex) {
    // Create or get the essay based on the index
    var essay = essayIndex >= 0 ? appState.essays[appState.selectedSchoolIndex][essayIndex] : Essay(prompt: '', response: '');
    var promptController = TextEditingController(text: essay.prompt);
    var minWordsController = TextEditingController(text: essay.minWords.toString());
    var maxWordsController = TextEditingController(text: essay.maxWords.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(essayIndex >= 0 ? 'Edit Prompt' : 'Add Essay'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Prompt'),
                  controller: promptController,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextField(
                        decoration: InputDecoration(labelText: 'Min Words'),
                        keyboardType: TextInputType.number,
                        controller: minWordsController,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                    SizedBox(width: 16.0),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        decoration: InputDecoration(labelText: 'Max Words'),
                        keyboardType: TextInputType.number,
                        controller: maxWordsController,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            if (essayIndex >= 0) // Only show delete button if editing an existing essay
              TextButton(
                onPressed: () {
                  context.read<AppState>().deleteEssay(appState.selectedSchoolIndex, essayIndex);
                  Navigator.of(context).pop();
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                var newPrompt = promptController.text;
                var newMinWords = int.tryParse(minWordsController.text) ?? 0;
                var newMaxWords = int.tryParse(maxWordsController.text) ?? 0;

                if (essayIndex >= 0) {
                  appState.updateEssay(
                    appState.selectedSchoolIndex,
                    essayIndex,
                    newPrompt,
                    essay.response,
                    minWords: newMinWords,
                    maxWords: newMaxWords,
                  );
                } else {
                  appState.addEssay(Essay(
                    prompt: newPrompt,
                    response: '',
                    minWords: newMinWords,
                    maxWords: newMaxWords,
                  ));
                }

                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}


