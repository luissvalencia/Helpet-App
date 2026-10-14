import 'dart:io';

import 'package:image/image.dart' as img;

/// US-22: validaciones de calidad de foto antes de subirla a Storage.
const int fotoAnchoAltoMinimo = 200;
const int fotoPesoMaximoBytes = 10 * 1024 * 1024;
const double fotoBrilloPromedioMinimo = 30;

/// Auditoría post-Sprint-5: US-22 mencionaba brillo *y* borrosidad como
/// "opcional pero valorado", pero solo brillo se implementó en el Sprint 5.
/// Umbral conservador (solo atrapa los casos obviamente borrosos) sobre un
/// proxy simple de nitidez, no un detector de borrosidad real.
const double fotoNitidezMinima = 40;

class FotoValidationException implements Exception {
  FotoValidationException(this.message);

  final String message;
}

/// Lanza [FotoValidationException] con el mensaje a mostrar al usuario si la
/// foto no pasa alguna validación. No retorna nada si es válida.
Future<void> validarFoto(File file) async {
  final bytes = await file.readAsBytes();

  if (bytes.lengthInBytes > fotoPesoMaximoBytes) {
    throw FotoValidationException(
      'La foto es demasiado grande. El tamaño máximo es 10 MB.',
    );
  }

  final image = img.decodeImage(bytes);
  if (image == null) {
    throw FotoValidationException('No se pudo leer la foto seleccionada.');
  }

  if (image.width < fotoAnchoAltoMinimo || image.height < fotoAnchoAltoMinimo) {
    throw FotoValidationException(
      'La foto es demasiado pequeña. Usa una imagen de al menos 200×200 píxeles.',
    );
  }

  if (_brilloPromedio(image) < fotoBrilloPromedioMinimo) {
    throw FotoValidationException(
      'La foto está muy oscura. Intenta con mejor iluminación.',
    );
  }

  if (_varianzaDeGradiente(image) < fotoNitidezMinima) {
    throw FotoValidationException(
      'La foto está borrosa. Intenta tomarla de nuevo con la mascota quieta.',
    );
  }
}

double _brilloPromedio(img.Image image) {
  double suma = 0;
  int contados = 0;
  // Muestrea 1 de cada N píxeles en vez de todos: suficiente para estimar el
  // brillo promedio sin decodificar imágenes de varios megapíxeles pixel a pixel.
  const paso = 4;
  for (int y = 0; y < image.height; y += paso) {
    for (int x = 0; x < image.width; x += paso) {
      suma += image.getPixel(x, y).luminance;
      contados++;
    }
  }
  return contados == 0 ? 255 : suma / contados;
}

/// Proxy simple de nitidez: varianza del gradiente local de luminancia
/// (diferencia con el vecino a la derecha/abajo) sobre una muestra de la
/// imagen. Una foto borrosa tiene bordes suaves en todos lados → gradientes
/// chicos y parejos → varianza baja. No es un detector de borrosidad real
/// (tipo varianza del Laplaciano sobre la imagen completa), pero alcanza
/// para descartar los casos obvios sin depender de una librería de visión.
double _varianzaDeGradiente(img.Image image) {
  const paso = 4;
  final gradientes = <double>[];
  for (int y = 0; y < image.height - paso; y += paso) {
    for (int x = 0; x < image.width - paso; x += paso) {
      final actual = image.getPixel(x, y).luminance;
      final derecha = image.getPixel(x + paso, y).luminance;
      final abajo = image.getPixel(x, y + paso).luminance;
      gradientes.add(((derecha - actual).abs() + (abajo - actual).abs()).toDouble());
    }
  }
  if (gradientes.isEmpty) return fotoNitidezMinima;

  final promedio = gradientes.reduce((a, b) => a + b) / gradientes.length;
  final varianza = gradientes
          .map((v) => (v - promedio) * (v - promedio))
          .reduce((a, b) => a + b) /
      gradientes.length;
  return varianza;
}
