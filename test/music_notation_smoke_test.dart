import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_music_core/flutter_music_core.dart';
import 'package:flutter_musical_notation/flutter_musical_notation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paket fontunu test ortamına yükler (testlerde pubspec fontları otomatik
/// yüklenmez).
Future<void> _loadFont() async {
  final bytes = File('fonts/Bravura.otf').readAsBytesSync();
  final loader = FontLoader('packages/flutter_musical_notation/Bravura')
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

Future<void> _pump(WidgetTester tester, MusicNotation notation) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 420, height: 160, child: notation),
        ),
      ),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
}

MusicalValue _e(int index, int octave) => MusicalValue(
      duration: MusicalDuration.eighth,
      midiNotes: [MidiNote(index: index, octave: octave)],
    );


/// Çizilen mürekkebi ölçer: RepaintBoundary'deki opak piksel sayısı. Donanım
/// davranışını (aksidan yazıldı mı, yazılmadı mı) glif saymadan doğrular.
Future<int> _inkOf(WidgetTester tester, MusicNotation notation) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: RepaintBoundary(
            key: key,
            child: Container(
              color: Colors.white,
              width: 300,
              height: 140,
              child: notation,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  final data = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final bytes = data.buffer.asUint8List();
  var dark = 0;
  for (var i = 0; i < bytes.length; i += 4) {
    if (bytes[i] < 128) dark++; // siyah çizim, beyaz zemin
  }
  return dark;
}

void main() {
  setUpAll(_loadFont);

  testWidgets('renders single notes, dotted values, chords with seconds, '
      'rotated stems and rests without errors', (tester) async {
    await _pump(
      tester,
      MusicNotation(
        beatsPerMeasure: 2,
        measures: [
          NotationMeasure.singles([
            MusicalValue(
              duration: MusicalDuration.quarter,
              dotted: true,
              midiNotes: [MidiNote(index: 4, octave: 4)],
            ),
            MusicalValue(
              duration: MusicalDuration.eighth,
              midiNotes: [MidiNote(index: 5, octave: 4)],
            ),
          ]),
        ],
      ),
    );

    await _pump(
      tester,
      MusicNotation(
        measures: [
          NotationMeasure.singles([
            MusicalValue(
              duration: MusicalDuration.quarter,
              dotted: true,
              midiNotes: [
                MidiNote(index: 0, octave: 4),
                MidiNote(index: 1, octave: 4), // ikili aralık (second)
                MidiNote(index: 4, octave: 4),
              ],
            ),
            MusicalValue(
              duration: MusicalDuration.eighth,
              midiNotes: [MidiNote(index: 5, octave: 5)], // ters sap + ledger
            ),
            MusicalValue(
              type: RhythmicType.rest,
              duration: MusicalDuration.quarter,
            ),
            MusicalValue(
              duration: MusicalDuration.quarter,
              midiNotes: [MidiNote(index: 2, octave: 4)],
            ),
          ]),
        ],
      ),
    );

    // 5/8 aksak ölçü + fa anahtarı + kiriş grupları (3+2).
    await _pump(
      tester,
      MusicNotation(
        beatsPerMeasure: 5,
        beatUnit: MusicalDuration.eighth,
        clef: Clef.bass,
        measures: [
          NotationMeasure([
            Beam([_e(4, 2), _e(5, 2), _e(6, 2)]),
            Beam([_e(5, 2), _e(4, 2)]),
          ]),
        ],
      ),
    );
  });

  testWidgets('renders the single-line rhythm staff with beams and rests',
      (tester) async {
    await _pump(
      tester,
      MusicNotation.rhythm(
        beatsPerMeasure: 2,
        measures: [
          NotationMeasure([
            Single(MusicalValue(
              duration: MusicalDuration.quarter,
              midiNotes: [MidiNote(index: 0, octave: 4)],
            )),
            Beam([_e(0, 4), _e(0, 4)]),
          ]),
          NotationMeasure([
            Beam([_e(0, 4), _e(0, 4)]),
            Single(MusicalValue(
              type: RhythmicType.rest,
              duration: MusicalDuration.quarter,
            )),
          ]),
        ],
      ),
    );
  });

  testWidgets('renders key signatures and ties without errors',
      (tester) async {
    await _pump(
      tester,
      MusicNotation(
        beatsPerMeasure: 2,
        keySignature: const KeySignature(3), // La majör
        measures: [
          NotationMeasure.singles([
            MusicalValue(
              duration: MusicalDuration.quarter,
              midiNotes: [MidiNote(index: 4, octave: 4)],
            ),
            MusicalValue(
              duration: MusicalDuration.quarter,
              tiedToPrevious: true, // bağ
              midiNotes: [MidiNote(index: 4, octave: 4)],
            ),
          ]),
          NotationMeasure([
            Beam([
              _e(4, 4),
              MusicalValue(
                duration: MusicalDuration.eighth,
                tiedToPrevious: true, // kiriş içi bağ
                midiNotes: [MidiNote(index: 4, octave: 4)],
              ),
            ]),
            Single(MusicalValue(
              duration: MusicalDuration.quarter,
              tiedToPrevious: true, // kirişten ölçü içi bağ
              midiNotes: [MidiNote(index: 4, octave: 4)],
            )),
          ]),
        ],
      ),
    );

    // Bemollü donanım + fa anahtarı.
    await _pump(
      tester,
      MusicNotation(
        clef: Clef.bass,
        keySignature: const KeySignature(-4),
        measures: [
          NotationMeasure.singles([
            MusicalValue(
              duration: MusicalDuration.whole,
              midiNotes: [MidiNote(index: 1, octave: 3)],
            ),
          ]),
        ],
      ),
    );
  });

  test('KeySignature validates and reports accidentals', () {
    expect(() => KeySignature(8), throwsAssertionError);
    expect(() => KeySignature(-8), throwsAssertionError);

    const dMajor = KeySignature(2); // Fa♯ Do♯
    expect(dMajor.accidentalFor(3), MusicalAccidental.sharp); // Fa
    expect(dMajor.accidentalFor(0), MusicalAccidental.sharp); // Do
    expect(dMajor.accidentalFor(4), isNull); // Sol

    const ebMajor = KeySignature(-3); // Si♭ Mi♭ La♭
    expect(ebMajor.accidentalFor(6), MusicalAccidental.flat); // Si
    expect(ebMajor.accidentalFor(2), MusicalAccidental.flat); // Mi
    expect(ebMajor.accidentalFor(5), MusicalAccidental.flat); // La
    expect(ebMajor.accidentalFor(1), isNull); // Re

    expect(KeySignature.none.accidentalFor(3), isNull);
    expect(const KeySignature(2), const KeySignature(2));
  });

  test('a rest cannot be tied to the previous note', () {
    expect(
      () => MusicalValue(
        type: RhythmicType.rest,
        duration: MusicalDuration.quarter,
        tiedToPrevious: true,
      ),
      throwsAssertionError,
    );
  });

  test('MusicalValue.timeLength honors the dotted multiplier', () {
    expect(MusicalValue(duration: MusicalDuration.quarter).timeLength, 0.25);
    expect(
      MusicalValue(duration: MusicalDuration.quarter, dotted: true).timeLength,
      0.375,
    );
  });

  test('NotationMeasure and element timeLengths add up', () {
    final measure = NotationMeasure([
      Single(MusicalValue(duration: MusicalDuration.quarter)),
      Beam([_e(0, 4), _e(1, 4), _e(2, 4)]),
    ]);
    expect(measure.elements[0].timeLength, 0.25);
    expect(measure.elements[1].timeLength, 0.375);
    expect(measure.timeLength, 0.625); // 5/8'lik ölçüyü tam doldurur
  });

  test('Beam rejects invalid groups', () {
    expect(() => Beam([_e(0, 4)]), throwsAssertionError);
    expect(
      () => Beam([
        _e(0, 4),
        MusicalValue(type: RhythmicType.rest, duration: MusicalDuration.eighth),
      ]),
      throwsAssertionError,
    );
    expect(
      () => Beam([
        _e(0, 4),
        MusicalValue(
          duration: MusicalDuration.quarter,
          midiNotes: [MidiNote(index: 1, octave: 4)],
        ),
      ]),
      throwsAssertionError,
    );
  });

  group('donanım (key signature)', () {
    MusicNotation staffWith(KeySignature key, MidiNote note) => MusicNotation(
          keySignature: key,
          drawTimeSignature: false,
          measures: [
            NotationMeasure.singles([
              MusicalValue(
                duration: MusicalDuration.whole,
                midiNotes: [note],
              ),
            ]),
          ],
        );

    testWidgets('donanımın yazdığı arıza nota önünde tekrarlanmaz',
        (tester) async {
      const faMajor = KeySignature(-1); // Si♭
      // Si♭4 — arıza donanımda; nota önüne bemol DÜŞMEMELİ.
      final siBemol = await _inkOf(
        tester,
        staffWith(faMajor,
            MidiNote(index: 6, octave: 4, accidental: MusicalAccidental.flat)),
      );
      // Do5 — donanımda olmayan harf, arızasız. Aynı dizek + aynı donanım +
      // aynı notabaşı: mürekkep neredeyse birebir aynı olmalı.
      final referans =
          await _inkOf(tester, staffWith(faMajor, MidiNote(index: 0, octave: 5)));
      // Si♮4 — donanımı bozar; natürel yazılmalı → belirgin fazla mürekkep.
      final siNaturel = await _inkOf(
        tester,
        staffWith(faMajor, MidiNote(index: 6, octave: 4)),
      );

      expect(siNaturel, greaterThan(siBemol),
          reason: 'donanımı bozan nota natürel almalı');
      expect((siBemol - referans).abs(), lessThan((siNaturel - siBemol) ~/ 2),
          reason: 'Si♭ için nota önüne ikinci bir bemol çizilmemeli');
    });

    testWidgets('donanım dışı harfte notanın arızası yazılır', (tester) async {
      const solMajor = KeySignature(1); // Fa♯
      final doDiyez = await _inkOf(
        tester,
        staffWith(solMajor,
            MidiNote(index: 0, octave: 5, accidental: MusicalAccidental.sharp)),
      );
      final doNaturel =
          await _inkOf(tester, staffWith(solMajor, MidiNote(index: 0, octave: 5)));
      expect(doDiyez, greaterThan(doNaturel),
          reason: 'donanımda olmayan Do harfinde ♯ nota önünde yazılır');
    });
  });

  test('shouldRepaint reacts to field changes', () {
    final measures = [
      NotationMeasure.singles([MusicalValue()]),
    ];
    final a = MusicNotationPainter(measures: measures);
    final b = MusicNotationPainter(measures: measures);
    final c = MusicNotationPainter(measures: measures, color: Colors.red);
    final d = MusicNotationPainter(measures: measures, rhythmStaff: true);

    expect(a.shouldRepaint(b), isFalse);
    expect(a.shouldRepaint(c), isTrue);
    expect(a.shouldRepaint(d), isTrue);
  });
}
