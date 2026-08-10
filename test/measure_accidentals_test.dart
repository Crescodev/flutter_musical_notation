import 'package:flutter_music_core/flutter_music_core.dart';
import 'package:flutter_musical_notation/flutter_musical_notation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ölçü içi arıza hafızası (gravür kuralı; cihaz raporu 2026-08-10).
///
/// Raporun sözleri: *"bir notaya ölçü içerisinde değiştirici işaret eklenirse
/// tekrar aynı nota geldiğinde o değiştirici işaret varmış gibi
/// çalınır-söylenir; ancak bu kural uygulamada uygulanmıyor."*

MidiNote _n(int index, int octave, [MusicalAccidental? acc]) =>
    MidiNote(index: index, octave: octave, accidental: acc);

const _si = 6; // si (B)
const _mi = 2; // mi (E)

void main() {
  // Do minör / Mi♭ majör donanımı: si, mi, la bemol.
  const cMinor = KeySignature(-3);

  test('donanımın yazdığı arıza nota önüne düşmez', () {
    final a = MeasureAccidentals(cMinor);
    expect(a.accidentalFor(_n(_si, 4, MusicalAccidental.flat)), isNull);
  });

  test('donanımı bozan nota işaret alır', () {
    final a = MeasureAccidentals(cMinor);
    // Si natürel (yükseltilmiş 7. derece): donanımda si♭ var → natürel yazılır.
    expect(a.accidentalFor(_n(_si, 4)), MusicalAccidental.natural);
  });

  test('aynı ölçüde tekrarlanan arıza YENİDEN YAZILMAZ', () {
    final a = MeasureAccidentals(cMinor);
    expect(a.accidentalFor(_n(_si, 4)), MusicalAccidental.natural);
    expect(a.accidentalFor(_n(_si, 4)), isNull);
    expect(a.accidentalFor(_n(_si, 4)), isNull);
  });

  test('arızadan donanım hâline dönen nota İPTAL İŞARETİ alır', () {
    // Sessiz yanlışın ta kendisi: bu işaret yazılmazsa okuyucu kuralı
    // uygulayıp si natürel söyler, motor si♭ bekler.
    final a = MeasureAccidentals(cMinor);
    expect(a.accidentalFor(_n(_si, 4)), MusicalAccidental.natural);
    expect(a.accidentalFor(_n(_si, 4, MusicalAccidental.flat)),
        MusicalAccidental.flat);
  });

  test('hafıza ölçü sınırında sıfırlanır', () {
    final a = MeasureAccidentals(cMinor);
    expect(a.accidentalFor(_n(_si, 4)), MusicalAccidental.natural);
    expect(a.accidentalFor(_n(_si, 4)), isNull);
    a.reset();
    expect(a.accidentalFor(_n(_si, 4)), MusicalAccidental.natural);
  });

  test('hafıza oktav duyarlıdır', () {
    final a = MeasureAccidentals(cMinor);
    expect(a.accidentalFor(_n(_si, 4)), MusicalAccidental.natural);
    // Başka oktavdaki si hâlâ donanımdan bemol sayılır → kendi işaretini alır.
    expect(a.accidentalFor(_n(_si, 5)), MusicalAccidental.natural);
    expect(a.accidentalFor(_n(_si, 5, MusicalAccidental.flat)),
        MusicalAccidental.flat);
  });

  test('hafıza harf duyarlıdır (si arızası mi\'yi etkilemez)', () {
    final a = MeasureAccidentals(cMinor);
    expect(a.accidentalFor(_n(_si, 4)), MusicalAccidental.natural);
    expect(a.accidentalFor(_n(_mi, 4, MusicalAccidental.flat)), isNull);
    expect(a.accidentalFor(_n(_mi, 4)), MusicalAccidental.natural);
  });

  test('çift arıza da hafızaya girer (Sol♯ minörde Fa çift diyez)', () {
    const gSharpMinor = KeySignature(5); // fa, do, sol, re, la diyez
    final a = MeasureAccidentals(gSharpMinor);
    const fa = 3;
    expect(a.accidentalFor(_n(fa, 4, MusicalAccidental.doubleSharp)),
        MusicalAccidental.doubleSharp);
    expect(a.accidentalFor(_n(fa, 4, MusicalAccidental.doubleSharp)), isNull);
    // Donanımın fa♯'ına dönüş: tek diyez yazılarak iptal edilir.
    expect(a.accidentalFor(_n(fa, 4, MusicalAccidental.sharp)),
        MusicalAccidental.sharp);
  });

  test('donanımsız tonda arıza ve iptali', () {
    final a = MeasureAccidentals(KeySignature.none);
    const fa = 3;
    expect(a.accidentalFor(_n(fa, 4)), isNull);
    expect(a.accidentalFor(_n(fa, 4, MusicalAccidental.sharp)),
        MusicalAccidental.sharp);
    expect(a.accidentalFor(_n(fa, 4, MusicalAccidental.sharp)), isNull);
    expect(a.accidentalFor(_n(fa, 4)), MusicalAccidental.natural);
  });
}
