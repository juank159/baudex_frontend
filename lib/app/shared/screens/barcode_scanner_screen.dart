import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatelessWidget {
  const BarcodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear código de barras')),
      body: MobileScanner(
        onDetect: (barcodeCapture) {
          final code = barcodeCapture.barcodes.first.rawValue;
          if (code != null) {
            Navigator.pop(context, code); // ⬅️ Devuelve el código escaneado
          }
        },
      ),
    );
  }
}
