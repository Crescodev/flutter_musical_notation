import 'package:flutter/material.dart';
import 'package:flutter_music_core/flutter_music_core.dart';
import 'package:flutter_musical_notation/src/music_notation_painter.dart';

class MusicNotation extends StatelessWidget {
  final int beatsPerMeasure;
  final MusicalDuration beatUnit;
  final int measureCount;
  final Color color;
  final bool isEnd;
  final Clef clef;
  final double height;
  final bool horizontallyCenterNotes;
  final bool drawClef;
  final bool drawTimeSignature;
  final List<MusicalValue> values;
  const MusicNotation({
    this.beatsPerMeasure = 4,
    this.beatUnit = MusicalDuration.quarter,
    this.measureCount = 1,
    this.color = Colors.black,
    this.isEnd = true,
    this.clef = Clef.treble,
    this.height = 150,
    this.horizontallyCenterNotes = false,
    this.drawClef = true,
    this.drawTimeSignature = true,
    this.values = const [],
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: MusicNotationPainter(
          beatsPerMeasure: beatsPerMeasure,
          beatUnit: beatUnit,
          measureCount: measureCount,
          color: color,
          clef: clef,
          isEnd: isEnd,
          horizontallyCenterNotes: horizontallyCenterNotes,
          drawClef: drawClef,
          drawTimeSignature: drawTimeSignature,
          values: values,
        ),
      ),
    );
  }
}
