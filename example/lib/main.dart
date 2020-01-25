import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

enum TtsState { playing, stopped }

class _MyAppState extends State<MyApp> {
  FlutterTts flutterTts;
  dynamic languages;
  dynamic voices;
  String language;
  String voice;
  int silencems;
  int current_paragraph;
  String ttsIsAtWord;
  int ttsIsAtIndexStart;
  int ttsIsAtIndexEnd;

  List<String> paragraphList;
  int paragraphCount = 0;
  int paragraphListLength = 0;

  String _platformVersion = 'Unknown';
  String _newVoiceText = getArticle();
  int newParaFromIndex;

  TtsState ttsState = TtsState.stopped;

  get isPlaying => ttsState == TtsState.playing;

  get isStopped => ttsState == TtsState.stopped;

  bool stopIsClicked = false;

  @override
  initState() {
    super.initState();
    initPlatformState();
    initTts();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
    flutterTts = FlutterTts();

    paragraphList = _newVoiceText.split(".");

    paragraphListLength = paragraphList.length;
    debugPrint('PARAGRAPH LIST LENGTH -> $paragraphListLength');

    if (Platform.isAndroid) {
      flutterTts.ttsInitHandler(() {
        _getLanguages();
        _getVoices();
      });
    } else if (Platform.isIOS) {
      _getLanguages();
      _getVoices();
    }

    flutterTts.setStartHandler(() {
      setState(() {
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        ttsState = TtsState.stopped;
      });
    });

    flutterTts
        .setProgressHandler((String words, int start, int end, String word) {
      setState(() {
        _platformVersion = word;
      });
      ttsIsAtWord = word;
      ttsIsAtIndexStart = start;
      ttsIsAtIndexEnd = end;
      //  print('PROGRESS: $word => $start - $end');
    });
  }

  initTts() {}

  Future _getLanguages() async {
    languages = await flutterTts.getLanguages;
    if (languages != null) setState(() => languages);
  }

  Future _getVoices() async {
    voices = await flutterTts.getVoices;
    if (voices != null) setState(() => voices);
  }

  Future _speak() async {
    debugPrint(
        ' TTS SPEAK $ttsIsAtWord $ttsIsAtIndexStart $ttsIsAtIndexEnd $newParaFromIndex ');
    if (_newVoiceText != null) {
      if (_newVoiceText.isNotEmpty) {
        /// this logic will work when pause is clicked and again play is clicked
        if (ttsIsAtWord != null &&
            ttsIsAtIndexStart != null &&
            ttsIsAtIndexEnd != null && stopIsClicked == false ) {
          newParaFromIndex = _newVoiceText.indexOf(ttsIsAtWord ?? "");
          debugPrint('$newParaFromIndex');
          paragraphList = _newVoiceText.substring(newParaFromIndex).split(".");
          stopIsClicked = false;
          for (var i = 0; i < paragraphList.length; i++) {
            var result =
                flutterTts.speak(paragraphList[i], queue: QUEUE.QUEUE_ADD);
            if (result == 1)
              setState(() {
                TtsState.playing;
              });
            else {
              TtsState.stopped;
            }
          }
        }

        /// this is the logic when tts starts from beginning first time when play is clicked
        else {
          newParaFromIndex = _newVoiceText.indexOf(ttsIsAtWord ?? "");
          stopIsClicked = false;
          for (var i = 0; i < paragraphList.length; i++) {
            var result =
                flutterTts.speak(paragraphList[i], queue: QUEUE.QUEUE_ADD);
            if (result == 1)
              setState(() {
                TtsState.playing;
              });
            else {
              TtsState.stopped;
            }
          }
        }
      }
    }
  }

  Future _pause() async {
    var result = await flutterTts.stop();
    flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  Future _stop() async {

   stopIsClicked = true;
    var result = await flutterTts.stop();
    _newVoiceText = getArticle();
    paragraphList = _newVoiceText.split(".");
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  List<DropdownMenuItem<String>> getLanguageDropDownMenuItems() {
    var items = List<DropdownMenuItem<String>>();
    for (String type in languages) {
      items.add(DropdownMenuItem(value: type, child: Text(type)));
    }
    return items;
  }

  List<DropdownMenuItem<String>> getVoiceDropDownMenuItems() {
    var items = List<DropdownMenuItem<String>>();
    for (String type in voices) {
      items.add(DropdownMenuItem(value: type, child: Text(type)));
    }
    return items;
  }

  List<DropdownMenuItem<int>> getSilenceDropDownMenuItems() {
    var items = List<DropdownMenuItem<int>>();
    items.add(
        DropdownMenuItem(value: null, child: Text("No Silence before TTS")));
    items.add(DropdownMenuItem(
        value: 1000, child: Text("1 Second Silence before TTS")));
    items.add(DropdownMenuItem(
        value: 5000, child: Text("5 Seconds Silence before TTS")));
    return items;
  }

  void changedLanguageDropDownItem(String selectedType) {
    setState(() {
      language = selectedType;
      flutterTts.setLanguage(language);
    });
  }

  void changedVoiceDropDownItem(String selectedType) {
    setState(() {
      voice = selectedType;
      flutterTts.setVoice(voice);
    });
  }

  void changedSilenceDropDownItem(int selectedType) {
    setState(() {
      silencems = selectedType;
      flutterTts.setSilence(silencems);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: Text('Flutter TTS'),
            ),
            body: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(children: [
                  btnSection(),
                  languages != null ? languageDropDownSection() : Text(""),
                  voices != null ? voiceDropDownSection() : Text(""),
                  Platform.isAndroid ? silenceDropDownSection() : Text("")
                ]))));
  }

  Widget btnSection() => Container(
      padding: EdgeInsets.only(top: 50.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _buildButtonColumn(
            Colors.green,
            Colors.greenAccent,
            (isPlaying as bool) ? Icons.pause : Icons.play_circle_filled,
            (isPlaying as bool) ? 'PAUSE' : 'PLAY ',
            (isPlaying as bool) ? _pause : _speak),
        _buildButtonColumn(
            Colors.red, Colors.redAccent, Icons.stop, 'STOP', _stop)
      ]));

  Widget languageDropDownSection() => Container(
      padding: EdgeInsets.only(top: 50.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        DropdownButton(
          value: language,
          items: getLanguageDropDownMenuItems(),
          onChanged: changedLanguageDropDownItem,
        )
      ]));

  Widget voiceDropDownSection() => Container(
      padding: EdgeInsets.only(top: 30.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        DropdownButton(
          value: voice,
          items: getVoiceDropDownMenuItems(),
          onChanged: changedVoiceDropDownItem,
        )
      ]));

  Widget silenceDropDownSection() => Container(
      padding: EdgeInsets.only(top: 30.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        DropdownButton(
          value: silencems,
          items: getSilenceDropDownMenuItems(),
          onChanged: changedSilenceDropDownItem,
        )
      ]));

  Column _buildButtonColumn(Color color, Color splashColor, IconData icon,
      String label, Function func) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
              icon: Icon(icon),
              color: color,
              splashColor: splashColor,
              onPressed: () => func()),
          Container(
              margin: const EdgeInsets.only(top: 8.0),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                      color: color)))
        ]);
  }

  static String getArticle() {
    return """  
Understanding suspend function of Kotlin Coroutines
By Elyeelye.project4 min
View Original
When we talk about coroutine, Suspend Functions is like its backbone. So it is very important to know what it is before one could really appreciate coroutines in full.
However, to understanding what Suspend Functions is, even after reading from various writing found in internet, it not that straightforward, especially how could it it not blocking the Thread? How is coroutine really different from Thread
Understanding suspend function of Kotlin Coroutines
By Elyeelye.project4 min This article is related to a new language Kotlin. In this article I will discuss all the basics of the language.
Submitted by Aman Gautam, on November 25, 2017
Kotlin was invented by a software company JetBrains. This project is open Source and was started in 2010, But it was 
first released in 2016 as Kotlin v1.0.
Kotlin is statically typed Language means type checking is done at compile time. It runs on JVM (Java virtual machine) 
and requires less code to do the specific task as compared to java. Its code is more expressive than java and supports more feature than
 java like operator overloading (absent in java), lambda expressions etc.
We can develop Java Applications, Android Applications, Web Applications and native applications using Kotlin. So we can say it is a multiplatform Language.
Kotlin is not the replacement of java. Kotlin is interoperable with Java means we can use our existing Java code with Kotlin and Kotlin code with java.
In Google I/O 2017, Google has officially announced Kotlin as its official Android development language.
Features of Kotlin
First of all the main point to notice is that Kotlin is completely open source language.
Interoperable with java Concise Expressive
Easy to learn → Similar syntax to existing language (like java) Type Inference → need not to provide data type for variables, use var/val instead,
 it can automatically infer data types.
var a=5    //inferred as int  var s="Aman"  //inferred as String            
Operator overloading etc. Null Safety → to incur null pointer Exception (java)
The Kotlin programs can be compile and run in 'IntelliJ Idea' compiler (By JetBrains) includingeclipse (need plugin), NetBeans (need plugin). 
Kotlin files have ".kt" extension.
 Inheritance is one of the major aspect of OOP. It allow us to define a class and that can be inherited in multiple forms,
  like real world, features of parent class are accessible to child class through inheritance.
 It helps in designing larger application easily and efficiently.
The class from which child class inheritsall or some properties is known as Base class and the class which inherits properties
 from base class is known as derived class.
 Derived class contains feature from base class as well as its own feature.
In kotlin, to make any class inheritable we have to make it open. By default, all classes are final (final in java).
The kotlin 
open class vehicle{
    var price:Int=0
}
 java like operator overloading (absent in java), lambda expressions etc.
We can develop Java Applications, Android Applications, Web Applications and native applications using Kotlin. So we can say it is a multiplatform Language.
Kotlin is not the replacement of java. Kotlin is interoperable with Java means we can use our existing 
Java code with Kotlin and Kotlin code with java.
In Google I/O 2017, Google has officially announced Kotlin as its official Android development language.
Features of Kotlin
First of all the main point to notice is that Kotlin is completely open source language.
Interoperable with java Concise Expressive
Easy to learn → Similar syntax to existing language (like java) Type Inference → need not to provide data type 
for variables, use var/val instead, it can automatically infer data types.
var a=5    //inferred as int  var s="Aman"  //inferred as String            
Operator overloading etc. Null Safety → to incur null pointer Exception (java)
The Kotlin programs can be compile and run in 'IntelliJ Idea' compiler (By JetBrains) includingeclipse (need plugin),
 NetBeans (need plugin). Kotlin files have ".kt" extension.
 Inheritance is one of the major aspect of OOP. It allow us to define a class and that can be inherited in multiple forms, 
 like real world, features of parent class are accessible to child class through inheritance. It helps in designing larger application easily and efficiently.
The class from which child class inheritsall or some properties is known as Base class and the class which inherits properties
 from base class is known as derived class.
 Derived class contains feature from base class as well as its own feature.
In kotlin, to make any class inheritable we have to make it open. By default, all classes are final (final in java).
The kotlin 
open class vehicle{
    var price:Int=0
}
       """;
  }
}
