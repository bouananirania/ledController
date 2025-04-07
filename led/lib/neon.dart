import 'dart:async';
import 'dart:convert';
import 'dart:ui'; // Importé pour ImageFilter

import 'package:assets_audio_player/assets_audio_player.dart'; // Import package for sound
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

// Couleurs du Thème
const Color primaryPink = Color(0xFFE91E63); // Rose vif
const Color primaryPurple = Color(0xFF9C27B0); // Mauve
const Color accentPink = Color(0xFFFF80AB);
const Color accentPurple = Color(0xFFE040FB);
const Color darkBackground = Color(0xFF2C1B3E); // Fond sombre pour contraster
const Color neonGlowOff = Color(0xFF5A5A5A); // Couleur de la lueur éteinte
const Color ledOffColor = Color(0xFF303030); // Couleur de la LED éteinte

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IoT LED Controller',
      theme: ThemeData(
        brightness: Brightness.dark, // Thème sombre pour le look néon/tendance
        primaryColor: primaryPurple,
        colorScheme: const ColorScheme.dark(
          primary: primaryPurple,
          secondary: primaryPink,
          surface: Color(0xFF3C2B4E), // Couleur de surface un peu plus claire
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          error: Colors.redAccent,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: darkBackground,
        appBarTheme: AppBarTheme(
          backgroundColor:
              primaryPurple.withOpacity(0.8), // AppBar semi-transparente
          elevation: 0, // Pas d'ombre pour l'AppBar
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        // Style global des boutons (peut être surchargé localement)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, // Couleur texte/icon par défaut
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // Coins arrondis
            ),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        fontFamily: 'Roboto', // Utiliser une police standard
      ),
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
    'yellow': false, // Changé pour une couleur plus "rose/mauve"
    'green': false, // Changé pour une couleur plus "rose/mauve"
  };
  bool alarmOn = false;
  // Il est préférable d'utiliser .newPlayer() pour une instance dédiée
  final assetsAudioPlayer = AssetsAudioPlayer();

  // *** RAPPEL : Adaptez cette URL si nécessaire ***
  final String apiUrl =
      'http://localhost:4000'; // Gardé localhost, attention si émulateur/appareil
  Timer? pollingTimer;

  @override
  void initState() {
    super.initState();
    // Débogage Audio

    fetchStatus();
    pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      fetchStatus();
    });
  }

  // Optionnel : Pour le débogage

  @override
  void dispose() {
    pollingTimer?.cancel();
    assetsAudioPlayer
        .stop(); // Ensure alarm sound stops when the screen is disposed
    super.dispose();
  }

  // --- Logique fetchStatus (INCHANGÉE - contient potentiellement l'ancienne logique audio) ---
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

  // --- Logique toggleLed (INCHANGÉE) ---
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

  // --- Logique toggleAlarm (INCHANGÉE - contient potentiellement l'ancienne logique audio) ---
  Future<void> toggleAlarm() async {
    try {
      final res = await http.post(
        Uri.parse('$apiUrl/alarm'),
        body: jsonEncode({"state": !alarmOn}),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        await fetchStatus();
        if (alarmOn) {
          assetsAudioPlayer.open(
            Audio("assets/audio.wav"),
            autoStart: true,
            showNotification: true,
          );
        }
        //print(">>> On arrête le son");
        //assetsAudioPlayer.stop();
      }
    } catch (e) {
      print('Erreur toggleAlarm: $e');
    }
  }

  // --- WIDGET buildLed (MODIFIÉ pour effet néon) ---
  Widget buildLed(String colorKey, Color displayColor) {
    final bool isOn = ledStates[colorKey] ?? false;
    final Color neonColor = isOn ? displayColor : neonGlowOff;
    final Color bulbColor = isOn ? displayColor.withOpacity(0.9) : ledOffColor;

    return GestureDetector(
      onTap: () => toggleLed(colorKey, !isOn),
      child: Container(
        width: 90, // Légèrement plus grand pour la lueur
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bulbColor, // Couleur centrale de l'ampoule
          boxShadow: isOn // Appliquer l'ombre seulement si ON
              ? [
                  // Lueur principale
                  BoxShadow(
                    color: neonColor.withOpacity(0.8),
                    blurRadius: 20.0, // Flou important
                    spreadRadius: 5.0, // Étendue de la lueur
                  ),
                  // Halo plus subtil
                  BoxShadow(
                    color: neonColor.withOpacity(0.5),
                    blurRadius: 30.0,
                    spreadRadius: 8.0,
                  ),
                  // Lueur interne (optionnel)
                  // BoxShadow(
                  //   color: Colors.white.withOpacity(0.3),
                  //   blurRadius: 5.0,
                  //   spreadRadius: -2.0, // Négatif pour aller vers l'intérieur
                  // ),
                ]
              : [], // Pas d'ombre si OFF
        ),
        child: Center(
          child: Text(
            colorKey.toUpperCase(),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11, // Légèrement plus petit
                color: isOn ? Colors.white.withOpacity(0.9) : Colors.grey[400],
                // Ombre légère sur le texte pour le détacher
                shadows: [
                  Shadow(
                    blurRadius: isOn ? 5.0 : 1.0,
                    color: Colors.black.withOpacity(0.7),
                    offset: const Offset(1.0, 1.0),
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  // --- WIDGET build (MODIFIÉ pour UI et Bouton Alarme) ---
  @override
  Widget build(BuildContext context) {
    // Définir les couleurs des LEDs ici pour correspondre au thème
    final Map<String, Color> ledDisplayColors = {
      'red': const Color(0xC70039), // Utiliser la couleur primaire rose
      'yellow': const Color(
          0xe9ec1d), // Utiliser l'accent mauve (ou une autre couleur comme Colors.orangeAccent)
      'green': const Color(
          0x4fff33), // Utiliser l'accent rose (ou Colors.cyanAccent pour varier)
    };

    // Définir les gradients pour le bouton d'alarme
    final Gradient alarmOffGradient = const LinearGradient(
      colors: [primaryPurple, accentPurple], // Mauve -> Mauve clair
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final Gradient alarmOnGradient = const LinearGradient(
      colors: [primaryPink, accentPink], // Rose -> Rose clair/vif
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      // AppBar utilise maintenant le thème global
      appBar: AppBar(
        // Ajout d'un effet de flou derrière l'AppBar (optionnel)
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: const Text("Neon Control"), // Titre mis à jour
      ),
      body: Container(
        // Optionnel: Ajouter un fond dégradé subtil à tout l'écran
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              darkBackground.withOpacity(0.9),
              const Color(0xFF1A1128), // Encore plus sombre en bas
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0), // Ajouter du padding global
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Section LEDs Néon ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ledDisplayColors.keys.map((key) {
                    return buildLed(key, ledDisplayColors[key]!);
                  }).toList(),
                ),
                const SizedBox(height: 60), // Plus d'espace

                // --- Bouton Alarme Tendance (MODIFIÉ) ---
                GestureDetector(
                  onTap: toggleAlarm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 18),
                    decoration: BoxDecoration(
                      gradient: alarmOn ? alarmOnGradient : alarmOffGradient,
                      borderRadius:
                          BorderRadius.circular(30), // Coins bien arrondis
                      boxShadow: [
                        BoxShadow(
                          color: (alarmOn ? primaryPink : primaryPurple)
                              .withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 1,
                          offset:
                              const Offset(0, 5), // Ombre portée vers le bas
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min, // Ajuster la taille au contenu
                      children: [
                        Icon(
                          alarmOn
                              ? Icons.notifications_off_outlined
                              : Icons
                                  .notifications_active, // Icônes alternatives
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          alarmOn ? "Stop Alarme" : "Lancer Alarme",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5, // Espacement lettres
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // --- Fin Bouton Alarme ---
              ],
            ),
          ),
        ),
      ),
    );
  }
}
