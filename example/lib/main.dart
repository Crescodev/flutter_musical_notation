import 'package:flutter/material.dart';
import 'package:flutter_music_core/flutter_music_core.dart';
import 'package:flutter_musical_notation/flutter_musical_notation.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GoogleFonts.pendingFonts([GoogleFonts.notoMusic()]);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: MusicNotation(
              beatUnit: MusicalDuration.quarter,
              beatsPerMeasure: 4,
              measureCount: 2,
              color: Colors.white,
              clef: Clef.treble,
              values: [
                MusicalValue(
                  type: RhythmicType.note,
                  duration: MusicalDuration.quarter,
                  midiNotes: [MidiNote(index: 5, octave: 3)],
                ),
                MusicalValue(
                  type: RhythmicType.note,
                  duration: MusicalDuration.quarter,
                  midiNotes: [MidiNote(index: 6, octave: 3)],
                ),
                MusicalValue(
                  type: RhythmicType.note,
                  duration: MusicalDuration.quarter,
                  midiNotes: [MidiNote(index: 1, octave: 3)],
                ),
                MusicalValue(
                  type: RhythmicType.note,
                  duration: MusicalDuration.quarter,
                  midiNotes: [MidiNote(index: 2, octave: 3)],
                ),

                MusicalValue(
                  type: RhythmicType.note,
                  duration: MusicalDuration.quarter,
                  midiNotes: [MidiNote(index: 3, octave: 6), MidiNote(index: 2, octave: 6)],
                ),
                MusicalValue(
                  type: RhythmicType.note,
                  duration: MusicalDuration.quarter,
                  midiNotes: [MidiNote(index: 4, octave: 6)],
                ),
                MusicalValue(
                  type: RhythmicType.note,
                  duration: MusicalDuration.quarter,
                  midiNotes: [MidiNote(index: 5, octave: 6)],
                ),
                MusicalValue(
                  type: RhythmicType.note,
                  duration: MusicalDuration.quarter,
                  midiNotes: [MidiNote(index: 6, octave: 6), MidiNote(index: 5, octave: 6)],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
