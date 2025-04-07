import 'dart:async';
import 'dart:convert';

import 'package:assets_audio_player/assets_audio_player.dart'; // Import package for sound
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IoT LED Controller',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const LedControllerScreen(),
    );
  }
}

class LedControllerScreen extends StatefulWidget {
  const LedControllerScreen({super.key});

  @override
  State<LedControllerScreen> createState() => _LedControllerScreenState();
}

class _LedControllerScreenState extends State<LedControllerScreen> {
  Map<String, bool> ledStates = {
    'red': false,
    'yellow': false,
    'green': false,
  };
  bool alarmOn = false;
  final assetsAudioPlayer = AssetsAudioPlayer(); // Audio player instance

  final String apiUrl = 'http://localhost:4000'; // Update API URL as needed
  Timer? pollingTimer;

  @override
  void initState() {
    super.initState();
    fetchStatus();
    pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      fetchStatus();
    });
  }

  @override
  void dispose() {
    pollingTimer?.cancel();
    assetsAudioPlayer
        .stop(); // Ensure alarm sound stops when the screen is disposed
    super.dispose();
  }

  Future<void> fetchStatus() async {
    try {
      final res = await http.get(Uri.parse('$apiUrl/status'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          ledStates = {
            'red': data['leds']?['red'] ?? false,
            'yellow': data['leds']?['yellow'] ?? false,
            'green': data['leds']?['green'] ?? false,
          };
          alarmOn = data['alarmOn'] ?? false; // Default to 'false' if null
        });
        if (alarmOn) {
          // Si l'alarme est ON, jouer le son (s'il n'est pas déjà en train de jouer)
          if (!assetsAudioPlayer.isPlaying.value) {
            print("fetchStatus: Alarm is ON. Playing sound.");
            assetsAudioPlayer
                .open(
                  Audio(
                      "assets/audio.wav"), // Assurez-vous que le chemin est correct
                  autoStart: true,

                  showNotification: false, // Cacher la notification par défaut
                )
                .catchError((e) => print("Error playing sound: $e"));
          } else {
            print("fetchStatus: Alarm is ON, but sound already playing.");
          }
        }
      }
    } catch (e) {
      print('Erreur de fetchStatus: $e');
    }
  }

  Future<void> toggleLed(String color, bool state) async {
    try {
      final res = await http.post(
        Uri.parse('$apiUrl/led/$color'),
        body: jsonEncode({"state": state}),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        await fetchStatus();
      }
    } catch (e) {
      print('Erreur toggleLed: $e');
    }
  }

  Future<void> toggleAlarm() async {
    try {
      final res = await http.post(
        Uri.parse('$apiUrl/alarm'),
        body: jsonEncode({"state": !alarmOn}),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        await fetchStatus();
        assetsAudioPlayer.open(
          Audio("assets/audio.wav"),
          autoStart: true,
          showNotification: true,
        );
        //print(">>> On arrête le son");
        //assetsAudioPlayer.stop();
      }
    } catch (e) {
      print('Erreur toggleAlarm: $e');
    }
  }

  Widget buildLed(String color, Color displayColor) {
    return GestureDetector(
      onTap: () => toggleLed(color, !ledStates[color]!),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: ledStates[color]! ? displayColor : Colors.grey[400],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            color.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("IoT LED + Alarme")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildLed('red', Colors.red),
                buildLed('yellow', Colors.yellow),
                buildLed('green', Colors.green),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: toggleAlarm,
              icon: Icon(alarmOn ? Icons.alarm_off : Icons.alarm),
              label: Text(alarmOn ? "Stop Alarme" : "Lancer Alarme"),
              style: ElevatedButton.styleFrom(
                backgroundColor: alarmOn ? Colors.red : Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
