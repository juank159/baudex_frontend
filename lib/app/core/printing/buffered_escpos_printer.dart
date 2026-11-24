// lib/app/core/printing/buffered_escpos_printer.dart
//
// Mismo contrato que `NetworkPrinter` (esc_pos_printer_plus), pero en vez de
// escribir cada línea en la conexión, junta los bytes en memoria. Así el
// tiquete se arma completo ANTES de conectar con la impresora y se envía de
// una sola vez, sin pausas fijas entre bloques.
//
// Cada método hace exactamente la misma llamada al `Generator` que hace
// `NetworkPrinter`, así que los bytes (y el tiquete) son idénticos.
import 'dart:typed_data';

import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;

class BufferedEscPosPrinter implements NetworkPrinter {
  BufferedEscPosPrinter(this._paperSize, this._profile,
      {int spaceBetweenRows = 5})
      : _generator =
            Generator(_paperSize, _profile, spaceBetweenRows: spaceBetweenRows) {
    // `NetworkPrinter.connect` manda un reset al conectar.
    _out.add(_generator.reset());
  }

  final PaperSize _paperSize;
  final CapabilityProfile _profile;
  final Generator _generator;
  final BytesBuilder _out = BytesBuilder(copy: false);

  /// Bytes acumulados hasta ahora.
  Uint8List get bytes => _out.toBytes();
  int get length => _out.length;

  @override
  int? get port => null;
  @override
  String? get host => null;
  @override
  PaperSize get paperSize => _paperSize;
  @override
  CapabilityProfile get profile => _profile;

  /// No conecta con nada: los bytes se envían después, de una vez.
  @override
  Future<PosPrintResult> connect(String host,
          {int port = 9100,
          Duration timeout = const Duration(seconds: 5)}) async =>
      PosPrintResult.success;

  @override
  void disconnect({int? delayMs}) {}

  @override
  void reset() => _out.add(_generator.reset());

  @override
  void text(
    String text, {
    PosStyles styles = const PosStyles(),
    int linesAfter = 0,
    bool containsChinese = false,
    int? maxCharsPerLine,
  }) =>
      _out.add(_generator.text(text,
          styles: styles,
          linesAfter: linesAfter,
          containsChinese: containsChinese,
          maxCharsPerLine: maxCharsPerLine));

  @override
  void setGlobalCodeTable(String codeTable) =>
      _out.add(_generator.setGlobalCodeTable(codeTable));

  @override
  void setGlobalFont(PosFontType font, {int? maxCharsPerLine}) =>
      _out.add(_generator.setGlobalFont(font, maxCharsPerLine: maxCharsPerLine));

  @override
  void setStyles(PosStyles styles, {bool isKanji = false}) =>
      _out.add(_generator.setStyles(styles, isKanji: isKanji));

  @override
  void rawBytes(List<int> cmd, {bool isKanji = false}) =>
      _out.add(_generator.rawBytes(cmd, isKanji: isKanji));

  @override
  void emptyLines(int n) => _out.add(_generator.emptyLines(n));

  @override
  void feed(int n) => _out.add(_generator.feed(n));

  @override
  void cut({PosCutMode mode = PosCutMode.full}) =>
      _out.add(_generator.cut(mode: mode));

  @override
  void printCodeTable({String? codeTable}) =>
      _out.add(_generator.printCodeTable(codeTable: codeTable));

  @override
  void beep({int n = 3, PosBeepDuration duration = PosBeepDuration.beep450ms}) =>
      _out.add(_generator.beep(n: n, duration: duration));

  @override
  void reverseFeed(int n) => _out.add(_generator.reverseFeed(n));

  @override
  void row(List<PosColumn> cols) => _out.add(_generator.row(cols));

  @override
  void image(img.Image imgSrc, {PosAlign align = PosAlign.center}) =>
      _out.add(_generator.image(imgSrc, align: align));

  @override
  void imageRaster(
    img.Image image, {
    PosAlign align = PosAlign.center,
    bool highDensityHorizontal = true,
    bool highDensityVertical = true,
    PosImageFn imageFn = PosImageFn.bitImageRaster,
  }) =>
      _out.add(_generator.imageRaster(
        image,
        align: align,
        highDensityHorizontal: highDensityHorizontal,
        highDensityVertical: highDensityVertical,
        imageFn: imageFn,
      ));

  @override
  void barcode(
    Barcode barcode, {
    int? width,
    int? height,
    BarcodeFont? font,
    BarcodeText textPos = BarcodeText.below,
    PosAlign align = PosAlign.center,
  }) =>
      _out.add(_generator.barcode(
        barcode,
        width: width,
        height: height,
        font: font,
        textPos: textPos,
        align: align,
      ));

  @override
  void qrcode(
    String text, {
    PosAlign align = PosAlign.center,
    QRSize size = QRSize.size4,
    QRCorrection cor = QRCorrection.L,
  }) =>
      _out.add(_generator.qrcode(text, align: align, size: size, cor: cor));

  @override
  void drawer({PosDrawer pin = PosDrawer.pin2}) =>
      _out.add(_generator.drawer(pin: pin));

  @override
  void hr({String ch = '-', int? len, int linesAfter = 0}) =>
      _out.add(_generator.hr(ch: ch, linesAfter: linesAfter));

  @override
  void textEncoded(
    Uint8List textBytes, {
    PosStyles styles = const PosStyles(),
    int linesAfter = 0,
    int? maxCharsPerLine,
  }) =>
      _out.add(_generator.textEncoded(
        textBytes,
        styles: styles,
        linesAfter: linesAfter,
        maxCharsPerLine: maxCharsPerLine,
      ));
}
