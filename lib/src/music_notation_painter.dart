import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_music_core/flutter_music_core.dart';
import 'package:flutter_musical_notation/src/measure.dart';
import 'package:google_fonts/google_fonts.dart';

class MusicNotationPainter extends CustomPainter {
  final int beatsPerMeasure;
  final MusicalDuration beatUnit;
  final int measureCount;
  final Color color;
  final Clef clef;
  final bool isEnd;
  final bool horizontallyCenterNotes;
  final bool drawClef;
  final bool drawTimeSignature;
  final List<MusicalValue> values;

  MusicNotationPainter({
    this.beatsPerMeasure = 4,
    this.beatUnit = MusicalDuration.quarter,
    this.measureCount = 1,
    this.color = Colors.black,
    this.clef = Clef.treble,
    this.isEnd = true,
    this.horizontallyCenterNotes = false,
    this.drawClef = true,
    this.drawTimeSignature = true,
    this.values = const [],
  });

  double _fontSize(double height) => height / 3;

  late TextPainter _measurePainter;
  late TextPainter _measureLinePainter;
  late TextPainter _clefPainter;
  late TextPainter _beatsPerMeasurePainter;
  late TextPainter _beatUnitPainter;
  late TextPainter _endPainter;
  late double _noteSpaceHeight;
  late double _measureDescent;
  late double _measureExactHeight;
  late double _lineStrokeWidth;

  final bottomLimitIndex = 2;
  final topLimitIndex = -8;

  void _initializeDrawingElements(Canvas canvas, Size size) {
    final fontSize = _fontSize(size.height);
    _measurePainter = noteTextPainter(Measure.measureSpace.symbol, fontSize: fontSize)
      ..layout(maxWidth: size.width);
    _measureDescent = _measurePainter.computeLineMetrics().first.descent;
    _measureExactHeight = _measurePainter.computeLineMetrics().first.baseline - _measureDescent;
    _noteSpaceHeight = _measurePainter.height * 0.0675;
    _measureLinePainter = noteTextPainter(Measure.measureLine.symbol, fontSize: fontSize)
      ..layout(maxWidth: size.width);
    _clefPainter = noteTextPainter(clef.symbol, fontSize: fontSize)..layout(maxWidth: size.width);
    _beatsPerMeasurePainter = noteTextPainter(beatsPerMeasure.toString(), fontSize: fontSize * 0.7)
      ..layout(maxWidth: size.width);
    _beatUnitPainter = noteTextPainter(beatUnit.value.toString(), fontSize: fontSize * 0.7)
      ..layout(maxWidth: size.width);
    _endPainter = noteTextPainter(Measure.measureEnd.symbol, fontSize: fontSize)
      ..layout(maxWidth: size.width);

    _lineStrokeWidth = size.height / 100;
  }

  void centerCanvasVertical(Canvas canvas, Size size) {
    final yOffset = size.height / 2 - (_measurePainter.height / 2);
    canvas.translate(0, yOffset);
  }

  void drawStaff(Canvas canvas, Size size) {
    final lineSpacing =
        (_measureExactHeight - _lineStrokeWidth + 1) / 4; // Distance between staff lines
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = _lineStrokeWidth;

    // Draw 5 horizontal lines for the staff
    for (int i = 0; i < 5; i++) {
      final y = i * lineSpacing + _measureDescent + _lineStrokeWidth / 2 - 1;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  double clefEndX = 0.0;

  void _drawClef(Canvas canvas, Size size) {
    canvas.save();
    var dx = _measureLinePainter.width * 2;
    var dy = (_measureLinePainter.height * .06) * clef.offsetYMultiplier;
    canvas.translate(dx, dy);
    _clefPainter.paint(canvas, Offset.zero);
    canvas.restore();
    clefEndX = _clefPainter.width + dx;
  }

  double timeSignatureEndX = 0.0;

  void _drawTimeSignature(Canvas canvas, Size size) {
    canvas.save();
    var dx = clefEndX + _measureLinePainter.width * 2;
    var dy = _measurePainter.height / 8;
    canvas.translate(dx, dy);
    var beatsPerMeasureXOffset = 0.0;
    var beatUnitXOffset = 0.0;
    if (beatsPerMeasure.toString().length > beatUnit.value.toString().length) {
      beatUnitXOffset = (_beatsPerMeasurePainter.width / 2) - (_beatUnitPainter.width / 2);
    } else {
      beatsPerMeasureXOffset = (_beatUnitPainter.width / 2) - (_beatsPerMeasurePainter.width / 2);
    }

    _beatsPerMeasurePainter.paint(
      canvas,
      Offset(beatsPerMeasureXOffset, -_measurePainter.height * .15),
    );
    _beatUnitPainter.paint(canvas, Offset(beatUnitXOffset, _measurePainter.height * .15));
    canvas.restore();

    timeSignatureEndX = max(_beatsPerMeasurePainter.width, _beatUnitPainter.width) + dx;
  }

  late double widthOfAMeasure;

  void drawMeasures(Canvas canvas, Size size) {
    final staffWidthExceptLines =
        (size.width - timeSignatureEndX - (isEnd ? _endPainter.width : _measureLinePainter.width));
    // Draw measures
    widthOfAMeasure = staffWidthExceptLines / measureCount;

    canvas.save();
    for (var i = 0; i < measureCount + 1; i++) {
      canvas.save();
      if (i == measureCount) {
        if (isEnd) {
          canvas.translate(size.width - _endPainter.width - timeSignatureEndX, 0);
          _endPainter.paint(canvas, Offset.zero);
        } else {
          canvas.translate(widthOfAMeasure * i - timeSignatureEndX, 0);
          _measureLinePainter.paint(canvas, Offset.zero);
        }
      } else {
        canvas.translate(widthOfAMeasure * i, 0);
        _measureLinePainter.paint(canvas, Offset.zero);
      }
      canvas.restore();
      if (i == 0) {
        canvas.translate(timeSignatureEndX, 0);
      }
    }
    canvas.restore();
  }

  void drawNotes(Canvas canvas, Size size) {
    final measureTimeLength = beatsPerMeasure * (1 / beatUnit.value);

    var currentNoteIndex = 0;

    final measureStartPadding = (horizontallyCenterNotes ? -37.5 : widthOfAMeasure * 0.1);

    final staffWidthExceptLines =
        (size.width - timeSignatureEndX - (isEnd ? _endPainter.width : _measureLinePainter.width));
    // Draw measures
    widthOfAMeasure = staffWidthExceptLines / measureCount - measureStartPadding;

    canvas.translate(timeSignatureEndX, 0);
    for (var i = 0; i < measureCount; i++) {
      var notesInMeasureList = <MusicalValue>[];
      var currentBeat = 0.0;

      // Get all notes in the measure
      while (currentBeat < measureTimeLength && currentNoteIndex < values.length) {
        final currentNote = values[currentNoteIndex];
        final noteDuration = (1 / currentNote.duration.value);
        currentBeat += noteDuration;
        notesInMeasureList.add(currentNote);
        currentNoteIndex++;
      }

      canvas.translate(measureStartPadding, 0);

      // Draw notes in the measure
      for (var note in notesInMeasureList) {
        final timeLengthRatioOfNoteInMeasure = (1 / note.duration.value) / measureTimeLength;
        final widthOfNote = widthOfAMeasure * timeLengthRatioOfNoteInMeasure;
        drawChord(canvas, size, note, horizontallyCenterNotes ? widthOfNote / 2 : 0);
        canvas.translate(widthOfNote, 0);
      }
    }
  }

  double drawChord(Canvas canvas, Size size, MusicalValue musicalValue, double startDx) {
    // Calculates the average note position to determine if the chord should be rotated horizontally
    final isRest = musicalValue.type == RhythmicType.rest;
    final isHorizontalRotated =
        musicalValue.duration != MusicalDuration.whole &&
        !isRest &&
        (musicalValue.midiNotes.map((e) => e.octave * 7 + e.index).reduce((a, b) => a + b) /
                musicalValue.midiNotes.length) >
            (clef.firstSpaceMidiNote.octave * 7 + clef.firstSpaceMidiNote.index + 3);

    // Reorder notes according to its horizontal rotation
    final sortedNoteList =
        musicalValue.midiNotes.toList()..sort(
          (a, b) =>
              isHorizontalRotated
                  ? b.midiNumberWithoutAccidental.compareTo(a.midiNumber)
                  : a.midiNumberWithoutAccidental.compareTo(b.midiNumber),
        );

    final accidentalsWidth = drawAccidentals(
      sortedNoteList,
      canvas,
      size,
      startDx,
      color: musicalValue.color,
    );
    var noteWidth = 0.0;

    var isPreviousRotatedVertical = false;
    final verticalRotatedNotes = <MidiNote>[];

    final noteSymbol = musicalValue.duration.symbol(musicalValue.type);

    if (!isRest && musicalValue.midiNotes.isNotEmpty) {
      for (var i = 0; i < sortedNoteList.length; i++) {
        final note = sortedNoteList[i];
        final noteIndexDifference = calculateNoteIndexDifferenceWithClefsFirstSpaceMidiNote(note);
        bool isVerticalRotated = false;
        if (i != 0 &&
            !isPreviousRotatedVertical &&
            calculateIndexDifferenceBetweenFirstNoteToSecondNote(sortedNoteList[i - 1], note) ==
                (isHorizontalRotated ? 1 : -1)) {
          verticalRotatedNotes.add(note);
          isVerticalRotated = true;
          isPreviousRotatedVertical = true;
        } else {
          isPreviousRotatedVertical = false;
        }
        noteWidth = drawNote(
          canvas: canvas,
          size: size,
          noteText: noteSymbol,
          dx: accidentalsWidth + startDx,
          isRest: isRest,
          indexFromClefFirstSpace: noteIndexDifference,
          isHorizontalRotated: isHorizontalRotated,
          isVerticalRotated: isVerticalRotated,
          color: musicalValue.color,
        );
      }
      drawExtraLines(
        canvas: canvas,
        size: size,
        note: musicalValue,
        isHorizontalRotated: isHorizontalRotated,
        dx: accidentalsWidth + startDx,
        noteSymbol: noteSymbol,
        verticalRotatedNotes: verticalRotatedNotes,
      );
    } else {
      noteWidth = drawNote(
        canvas: canvas,
        size: size,
        noteText: noteSymbol,
        dx: startDx,
        isRest: isRest,
        indexFromClefFirstSpace: 0,
        isOnLine: true,
        color: musicalValue.color,
      );
    }
    return noteWidth + accidentalsWidth;
  }

  /// returns the width of the accidentals
  double drawAccidentals(
    List<MidiNote> sortedNoteList,
    Canvas canvas,
    Size size,
    double dx, {
    Color? color,
  }) {
    var notesWithAccidentals = sortedNoteList.where((e) => e.accidental != null).toList();
    var width = _measureLinePainter.width;
    canvas.save();
    canvas.translate(dx, 0);
    for (var i = 0; i < notesWithAccidentals.length; i++) {
      final note = notesWithAccidentals[i];
      final noteIndexDifference = calculateNoteIndexDifferenceWithClefsFirstSpaceMidiNote(note);
      final noteYOffset = noteIndexDifference * _noteSpaceHeight;
      canvas.save();
      canvas.translate(0, noteYOffset - _noteSpaceHeight * -2);

      final accidentalPainter = noteTextPainter(
        note.accidental!.symbol,
        fontSize: _fontSize(size.height) * 0.8,
        color: color,
      )..layout(maxWidth: size.width);
      accidentalPainter.paint(canvas, Offset.zero);
      canvas.restore();
      if (notesWithAccidentals.isNotEmpty) {
        width += accidentalPainter.width + _measureLinePainter.width;
        canvas.translate(accidentalPainter.width + _measureLinePainter.width, 0);
      }
    }
    canvas.restore();
    return width;
  }

  double drawNote({
    required Canvas canvas,
    required Size size,
    required String noteText,
    required double dx,
    required int indexFromClefFirstSpace,
    bool isRest = false,
    bool isHorizontalRotated = false,
    bool isVerticalRotated = false,
    bool extraLine = false,
    bool isOnLine = true,
    Color? color,
  }) {
    final notePainter = noteTextPainter(noteText, fontSize: _fontSize(size.height), color: color)
      ..layout(maxWidth: size.width);
    final noteYOffset = isRest ? 0.0 : indexFromClefFirstSpace * _noteSpaceHeight;
    canvas.save();
    canvas.translate(dx, noteYOffset);
    if (isHorizontalRotated) {
      canvas.save();
      if (!isVerticalRotated) {
        canvas.translate(notePainter.width * 1.915, 0);
      }
      canvas.translate(0, notePainter.height + (_noteSpaceHeight * 6));
      canvas.transform(Matrix4.rotationX(pi).storage);
      if (!isVerticalRotated) {
        canvas.transform(Matrix4.rotationY(pi).storage);
      }
      notePainter.paint(canvas, Offset.zero);
      canvas.restore();
    } else {
      if (isVerticalRotated) {
        canvas.transform(Matrix4.rotationY(pi).storage);
        canvas.translate(-notePainter.width * 1.915, 0);
      }
      notePainter.paint(canvas, Offset.zero);
    }
    canvas.restore();
    return notePainter.width;
  }

  void drawExtraLines({
    required Canvas canvas,
    required Size size,
    required MusicalValue note,
    required double dx,
    required String noteSymbol,
    required bool isHorizontalRotated,
    required List<MidiNote> verticalRotatedNotes,
  }) {
    final notePainter = noteTextPainter(noteSymbol, fontSize: _fontSize(size.height))
      ..layout(maxWidth: size.width);
    final lowestNoteSpace = calculateNoteIndexDifferenceWithClefsFirstSpaceMidiNote(
      note.midiNotes.first,
    );
    final highestNoteSpace = calculateNoteIndexDifferenceWithClefsFirstSpaceMidiNote(
      note.midiNotes.last,
    );

    final bottomLineCount = ((lowestNoteSpace - bottomLimitIndex) / 2).ceil();
    final topLineCount = ((highestNoteSpace - topLimitIndex) / 2).floor();
    canvas.save();
    canvas.translate(dx, 0);
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = _lineStrokeWidth;
    for (int i = 0; i < bottomLineCount; i++) {
      if (isHorizontalRotated) {
        canvas.drawLine(
          Offset(notePainter.width * -.4, _measureDescent + _noteSpaceHeight * 2 * (i + 5) + 1),
          Offset(notePainter.width * 2.15, _measureDescent + _noteSpaceHeight * 2 * (i + 5) + 1),
          paint,
        );
      } else {
        canvas.drawLine(
          Offset(notePainter.width * -.4, _measureDescent + _noteSpaceHeight * 2 * (i + 5) + 1),
          Offset(notePainter.width * 1.4, _measureDescent + _noteSpaceHeight * 2 * (i + 5) + 1),
          paint,
        );
      }
    }
    for (int i = 0; i > topLineCount; i--) {
      if (isHorizontalRotated) {
        canvas.drawLine(
          Offset(notePainter.width / 2, _measureDescent + _noteSpaceHeight * 2 * (i - 1) + 1),
          Offset(notePainter.width * 2.25, _measureDescent + _noteSpaceHeight * 2 * (i - 1) + 1),
          paint,
        );
      } else {
        canvas.drawLine(
          Offset(notePainter.width * -.5, _measureDescent + _noteSpaceHeight * 2 * (i - 1) + 1),
          Offset(notePainter.width * 1.4, _measureDescent + _noteSpaceHeight * 2 * (i - 1) + 1),
          paint,
        );
      }
    }
    if (verticalRotatedNotes.isNotEmpty) {
      final rotatedLowestNoteSpace = calculateNoteIndexDifferenceWithClefsFirstSpaceMidiNote(
        verticalRotatedNotes.first,
      );
      final rotatedHighestNoteSpace = calculateNoteIndexDifferenceWithClefsFirstSpaceMidiNote(
        verticalRotatedNotes.first,
      );
      final bottomRotatedLineCount = ((rotatedLowestNoteSpace - bottomLimitIndex) / 2).ceil();
      final topRotatedLineCount = ((rotatedHighestNoteSpace - topLimitIndex) / 2).floor();
      for (int i = 0; i < bottomRotatedLineCount; i++) {
        if (isHorizontalRotated) {
          canvas.drawLine(
            Offset(notePainter.width * -.4, _measureDescent + _noteSpaceHeight * 2 * (i + 5) + 1),
            Offset(notePainter.width * 1.4, _measureDescent + _noteSpaceHeight * 2 * (i + 5) + 1),
            paint,
          );
        } else {
          canvas.drawLine(
            Offset(notePainter.width * -.4, _measureDescent + _noteSpaceHeight * 2 * (i + 5) + 1),
            Offset(notePainter.width * 2.15, _measureDescent + _noteSpaceHeight * 2 * (i + 5) + 1),
            paint,
          );
        }
      }
      for (int i = 0; i > topRotatedLineCount; i--) {
        if (isHorizontalRotated) {
          canvas.drawLine(
            Offset(notePainter.width * -.5, _measureDescent + _noteSpaceHeight * 2 * (i - 1) + 1),
            Offset(notePainter.width * 2.25, _measureDescent + _noteSpaceHeight * 2 * (i - 1) + 1),
            paint,
          );
        } else {
          canvas.drawLine(
            Offset(notePainter.width / 2, _measureDescent + _noteSpaceHeight * 2 * (i - 1) + 1),
            Offset(notePainter.width * 2.25, _measureDescent + _noteSpaceHeight * 2 * (i - 1) + 1),
            paint,
          );
        }
      }
    }
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    _initializeDrawingElements(canvas, size);

    // Center the canvas vertically
    centerCanvasVertical(canvas, size);

    // Draw a staff that fills the width of the canvas
    drawStaff(canvas, size);

    if (drawClef) {
      // Draw the clef
      _drawClef(canvas, size);
    }

    if (drawTimeSignature) {
      // Draw the time signature
      _drawTimeSignature(canvas, size);
    }

    // Draw measures
    drawMeasures(canvas, size);

    // Draw notes
    drawNotes(canvas, size);
  }

  TextStyle noteTextStyle({required double fontSize, bool isBold = false, Color? color}) =>
      GoogleFonts.notoMusic(
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: color ?? this.color,
        letterSpacing: fontSize * -0.1,
      );

  TextPainter noteTextPainter(
    String text, {
    required double fontSize,
    bool isBold = false,
    Color? color,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: noteTextStyle(fontSize: fontSize, isBold: isBold, color: color ?? this.color),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.start,
    );
  }

  int calculateIndexDifferenceBetweenFirstNoteToSecondNote(MidiNote midiNote1, MidiNote midiNote2) {
    final int midiNote1ExactIndex = midiNote1.index + (midiNote1.octave * 7);
    final int midiNote2ExactIndex = midiNote2.index + (midiNote2.octave * 7);
    return midiNote1ExactIndex - midiNote2ExactIndex;
  }

  int calculateNoteIndexDifferenceWithClefsFirstSpaceMidiNote(MidiNote otherMidiNote) {
    return calculateIndexDifferenceBetweenFirstNoteToSecondNote(
      clef.firstSpaceMidiNote,
      otherMidiNote,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
