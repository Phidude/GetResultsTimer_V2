import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'dart:io';
import 'dart:convert'; // for jsonEncode and jsonDecode
import 'package:flutter/services.dart'; // for rootBundle
import 'package:path_provider/path_provider.dart'; // for getApplicationDocumentsDirectory

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Pomodoro(),
    ));

class Pomodoro extends StatefulWidget {
  @override
  _PomodoroState createState() => _PomodoroState();
}

class _PomodoroState extends State<Pomodoro> {
  double percent = 0;
  static int initialTimeInMinutes = 25;
  int timeInMinutes = initialTimeInMinutes;
  int timeInSeconds = initialTimeInMinutes * 60;
  bool isFirstTime = true; // Flag to track the first time

  late Timer timer;
  bool isTimerRunning = false;

  _toggleTimer() {
    setState(() {
      isTimerRunning = !isTimerRunning;
      if (isTimerRunning) {
        if (isFirstTime) {
          _decreaseMinutes(); // Decrease minutes only for the first time
          isFirstTime = false; // Set the flag to false after the first time
        }
        _startTimer();
      } else {
        timer.cancel();
      }
    });
  }

  _decreaseMinutes() {
    if (initialTimeInMinutes > 1) {
      setState(() {
        initialTimeInMinutes--;
        timeInMinutes = initialTimeInMinutes;
        timeInSeconds = initialTimeInMinutes * 60;
        percent = 0;
      });
    }
  }

  _startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (timeInSeconds > 0) {
          timeInSeconds--;
          percent = 1 - (timeInSeconds / (initialTimeInMinutes * 60));
        } else {
          percent = 0;
          timeInMinutes = initialTimeInMinutes;
          timeInSeconds = initialTimeInMinutes * 60;
          timer.cancel();
          isTimerRunning =
              false; // Set isTimerRunning to false when the timer completes
          isFirstTime = true; // Reset the flag for the next timer start
        }
      });
    });
  }

  _increaseTimer() {
    setState(() {
      initialTimeInMinutes++;
      timeInMinutes = initialTimeInMinutes;
      timeInSeconds = initialTimeInMinutes * 60;
      percent = 0;
    });
  }

  _decreaseTimer() {
    if (initialTimeInMinutes > 1) {
      setState(() {
        initialTimeInMinutes--;
        timeInMinutes = initialTimeInMinutes;
        timeInSeconds = initialTimeInMinutes * 60;
        percent = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey[900],
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
          ),
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                height: 300.0,
                child: CircularPercentIndicator(
                  percent: percent,
                  animation: true,
                  animateFromLastPercent: true,
                  radius: 150.0,
                  lineWidth: 10.0,
                  progressColor: Colors.cyanAccent,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "$timeInMinutes",
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 80.0,
                            ),
                          ),
                          Text(
                            ":",
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 80.0,
                            ),
                          ),
                          Text(
                            "${(timeInSeconds % 60).toString().padLeft(2, '0')}",
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 80.0,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: _decreaseTimer,
                            color: Colors.cyanAccent,
                          ),
                          SizedBox(width: 0.0),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: _increaseTimer,
                            color: Colors.cyanAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 10.0,
              ),
              ElevatedButton(
                onPressed: _toggleTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[850],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100.0),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    isTimerRunning ? "Stop" : "Start",
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 20.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => VariableRewards()),
            );
          },
          child: Icon(Icons.arrow_forward),
          backgroundColor: Colors.cyanAccent,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}

class VariableRewards extends StatefulWidget {
  @override
  _VariableRewardsState createState() => _VariableRewardsState();
}

class _VariableRewardsState extends State<VariableRewards> {
  List<String> rewardsList = [];

  @override
  void initState() {
    super.initState();
    _loadRewardsList();
  }

  Future<void> _loadRewardsList() async {
    try {
      final jsonString = await rootBundle.loadString('assets/rewards.json');
      final List<dynamic> decodedJson = jsonDecode(jsonString);
      setState(() {
        rewardsList = List<String>.from(decodedJson);
      });
    } catch (e) {
      print('Error loading rewards list: $e');
    }
  }

  Future<void> _saveRewardsList() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/rewards.json');

      // Load existing rewards from the file
      List<String> existingRewards = [];
      if (await file.exists()) {
        final content = await file.readAsString();
        existingRewards = List<String>.from(jsonDecode(content));
      }

      // Add the new reward to the list
      existingRewards.addAll(rewardsList);

      // Save the updated list to the file
      await file.writeAsString(jsonEncode(existingRewards));
    } catch (e) {
      print('Error saving rewards list: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Variable Rewards',
          style: TextStyle(color: Colors.cyanAccent),
        ),
        leading: IconButton(
          color: Colors.cyanAccent,
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
        ),
        width: double.infinity,
        child: Column(
          children: <Widget>[
            SizedBox(height: 10.0),
            Expanded(
              child: ListView.builder(
                itemCount: rewardsList.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.grey[850],
                    margin:
                        EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                    child: ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            rewardsList[index],
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 18.0,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.cyanAccent),
                            onPressed: () {
                              setState(() {
                                rewardsList.removeAt(index);
                                _saveRewardsList(); // Save after removing
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10.0),
              child: TextField(
                controller: TextEditingController(),
                decoration: InputDecoration(
                  hintText: 'Add a new reward...',
                  hintStyle: TextStyle(color: Colors.cyanAccent),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent),
                  ),
                ),
                style: TextStyle(color: Colors.cyanAccent),
                onSubmitted: (text) {
                  setState(() {
                    rewardsList.add(text);
                    _saveRewardsList(); // Save after adding
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text('Settings'),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
        ),
        width: double.infinity,
        child: Center(
          child: Text(
            'This is the settings page!',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 20.0,
            ),
          ),
        ),
      ),
    );
  }
}
