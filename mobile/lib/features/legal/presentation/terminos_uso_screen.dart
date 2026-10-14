import 'package:flutter/material.dart';

import '../../../core/widgets/section_card.dart';

class TerminosUsoScreen extends StatelessWidget {
  const TerminosUsoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Términos de uso')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Última actualización: 2026-07-14',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          const SectionCard(
            titulo: 'Qué es Helpet',
            icono: Icons.pets_outlined,
            child: Text(
              'Helpet es una plataforma comunitaria para ayudar a localizar '
              'mascotas extraviadas en Colombia. Permite reportar una '
              'mascota perdida o un avistamiento, y usa reconocimiento de '
              'imágenes para sugerir posibles coincidencias entre ambos '
              'tipos de reporte. Es un proyecto de grado universitario, no '
              'un servicio comercial.',
            ),
          ),
          const SizedBox(height: 16),
          const SectionCard(
            titulo: 'Uso aceptable',
            icono: Icons.check_circle_outline,
            child: Text(
              'Al usar Helpet te comprometes a:\n\n'
              '• Publicar solo reportes reales y fotos que efectivamente '
              'correspondan a la mascota descrita.\n'
              '• No usar la app para acosar, amenazar o extorsionar a otros '
              'usuarios — el sistema de contacto revela datos personales '
              '(teléfono/correo) y ese acceso es solo para coordinar la '
              'devolución de una mascota.\n'
              '• No suplantar a otra persona ni crear cuentas falsas.\n'
              '• No subir contenido ofensivo, ilegal o que no tenga relación '
              'con mascotas perdidas/encontradas.\n\n'
              'Si otro usuario incumple esto, puedes reportarlo desde la '
              'pantalla donde se revela su contacto tras confirmar una '
              'coincidencia. Un administrador puede deshabilitar cuentas '
              'que incumplan estos términos.',
            ),
          ),
          const SizedBox(height: 16),
          const SectionCard(
            titulo: 'Limitaciones del servicio',
            icono: Icons.info_outline,
            child: Text(
              '• Las coincidencias sugeridas por el modelo de reconocimiento '
              'de imágenes son solo una ayuda automática — no garantizan que '
              'dos reportes correspondan a la misma mascota. Siempre '
              'verifica presencialmente antes de entregar o recibir un '
              'animal.\n'
              '• Helpet no participa en la entrega física de mascotas ni '
              'media disputas entre usuarios sobre la tenencia de un animal '
              '— solo facilita el contacto inicial entre las partes.\n'
              '• El servicio se ofrece "tal cual", sin garantía de '
              'disponibilidad continua (es un proyecto académico).',
            ),
          ),
          const SizedBox(height: 16),
          const SectionCard(
            titulo: 'Tu cuenta',
            icono: Icons.person_outline,
            child: Text(
              'Eres responsable de mantener segura tu contraseña. Puedes '
              'eliminar tu cuenta en cualquier momento desde Perfil → '
              'Eliminar mi cuenta. Podemos deshabilitar cuentas que '
              'incumplan estos términos o que hayan sido reportadas y '
              'verificadas por un administrador.',
            ),
          ),
          const SizedBox(height: 16),
          const SectionCard(
            titulo: 'Contacto',
            icono: Icons.mail_outline,
            child: Text(
              'Preguntas sobre estos términos o sobre tus datos: '
              'josevalencia@unicomfacauca.edu.co',
            ),
          ),
        ],
      ),
    );
  }
}
