import 'package:flutter_music_core/flutter_music_core.dart';

/// Ölçü içi arıza (aksidan) hafızası — gravür kuralı.
///
/// Bir notaya ölçü içinde yazılan arıza, aynı ölçüde **aynı harf ve aynı
/// oktavdaki** sonraki notalar için de geçerlidir; ölçü çizgisinde donanım
/// yeniden geçerli olur. Bu kural olmadan iki ayrı yanlış doğar (cihaz raporu
/// 2026-08-10, melodik minör):
///
/// 1. Aynı arıza her tekrarda yeniden yazılır (gereksiz kalabalık).
/// 2. **Arızalı sesten donanım hâline dönen nota işaretsiz çizilir** — okuyucu
///    kuralı uygulayıp arızalı söyler, oysa motor doğal ses bekler. Bu
///    **sessiz** bir yanlıştır: nota ile ses ayrışır, kullanıcı neden yanlış
///    saydığını anlayamaz.
///
/// Kullanım: her ölçünün başında [reset], her nota için [accidentalFor].
/// Notalar **zaman sırasında** verilmelidir.
class MeasureAccidentals {
  MeasureAccidentals(this.keySignature);

  final KeySignature keySignature;

  /// `harf + 7 × oktav` → o an geçerli arıza ofseti.
  final Map<int, int> _sounding = {};

  /// Ölçü sınırı: donanım yeniden geçerli.
  void reset() => _sounding.clear();

  /// [note] için nota önüne yazılacak arıza; gerekmiyorsa null. Çağrı
  /// hafızayı **günceller** (yazılan arıza ölçünün kalanında geçerlidir).
  MusicalAccidental? accidentalFor(MidiNote note) {
    final key = note.index + 7 * note.octave;
    final sounding =
        _sounding[key] ?? (keySignature.accidentalFor(note.index)?.offset ?? 0);
    final offset = note.accidental?.offset ?? 0;
    if (offset == sounding) return null;
    _sounding[key] = offset;
    // Ofset 0 → donanımın arızasını iptal eden **natürel**.
    return MusicalAccidental.fromOffsetOrNull(offset) ??
        MusicalAccidental.natural;
  }
}
