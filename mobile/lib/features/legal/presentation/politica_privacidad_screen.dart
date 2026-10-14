import 'package:flutter/material.dart';

import '../../../core/widgets/section_card.dart';

/// Texto autocontenido en la app (sin dependencia de hosting externo).
/// Para publicar de verdad en Play Store, Google exige además una URL
/// pública con este mismo contenido.
class PoliticaPrivacidadScreen extends StatelessWidget {
  const PoliticaPrivacidadScreen({super.key});

  static const _contactoResponsable =
      'Equipo de desarrollo de Helpet (trabajo de grado, Ingeniería de '
      'Sistemas, Unicomfacauca) — josevalencia@unicomfacauca.edu.co';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Política de privacidad')),
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
            titulo: 'Responsable del tratamiento',
            icono: Icons.badge_outlined,
            child: Text(
              'Helpet es un proyecto de grado de Ingeniería de Sistemas '
              '(Unicomfacauca) para ayudar a reunir mascotas perdidas con '
              'sus familias mediante reconocimiento de imágenes. '
              'Responsable de contacto:\n\n$_contactoResponsable',
            ),
          ),
          const SizedBox(height: 16),
          const SectionCard(
            titulo: 'Qué datos recolectamos',
            icono: Icons.folder_outlined,
            child: Text(
              '• Datos de cuenta: nombre, correo electrónico y, opcionalmente, '
              'teléfono y foto de perfil.\n'
              '• Datos de reportes: fotos de mascotas, especie/raza/color/'
              'descripción, y la ubicación (latitud/longitud) que indicas al '
              'reportar una mascota perdida o un avistamiento.\n'
              '• Identificador de notificaciones push (token de FCM), para '
              'avisarte de coincidencias o reportes cercanos.\n'
              '• Registros técnicos de uso (fecha de creación de reportes, '
              'errores de la app) para mantenimiento del servicio.\n\n'
              'No recolectamos datos de pago ni de localización en segundo '
              'plano — la ubicación solo se envía cuando creas o editas un '
              'reporte de forma explícita.',
            ),
          ),
          const SizedBox(height: 16),
          const SectionCard(
            titulo: 'Para qué usamos tus datos',
            icono: Icons.flag_outlined,
            child: Text(
              '• Comparar fotos de mascotas mediante un modelo de '
              'reconocimiento de imágenes para sugerir posibles '
              'coincidencias entre reportes de "perdida" y "avistamiento".\n'
              '• Mostrar tus reportes en el mapa a otros usuarios cercanos.\n'
              '• Notificarte de coincidencias o reportes relevantes.\n'
              '• Revelar tu nombre, teléfono y correo a otro dueño '
              'únicamente cuando ambas partes confirman explícitamente que '
              'una coincidencia es real (nunca antes de esa doble '
              'confirmación).',
            ),
          ),
          const SizedBox(height: 16),
          const SectionCard(
            titulo: 'Con quién compartimos datos',
            icono: Icons.share_outlined,
            child: Text(
              'Tus datos se almacenan en la infraestructura de Firebase / '
              'Google Cloud (autenticación, base de datos, almacenamiento de '
              'fotos y notificaciones push), como proveedor de '
              'infraestructura técnica — no los vendemos ni los compartimos '
              'con fines publicitarios. El nombre y contacto de un dueño '
              'solo se revela a otro usuario cuando ambos confirman una '
              'coincidencia entre sus reportes (ver arriba).',
            ),
          ),
          const SizedBox(height: 16),
          const SectionCard(
            titulo: 'Tus derechos (Ley 1581 de 2012, Colombia)',
            icono: Icons.verified_user_outlined,
            child: Text(
              'Como titular de tus datos personales, en cualquier momento '
              'puedes:\n\n'
              '• Acceder a los datos que tenemos sobre ti (desde la pantalla '
              'de Perfil).\n'
              '• Actualizar o corregir tu nombre, teléfono o foto (desde la '
              'pantalla de Perfil).\n'
              '• Solicitar la supresión de tu cuenta y tus datos personales, '
              'usando la opción "Eliminar mi cuenta" en Perfil, o escribiendo '
              'al correo de contacto de arriba.\n'
              '• Revocar la autorización de tratamiento en cualquier '
              'momento.\n\n'
              'Al eliminar tu cuenta se borra tu perfil (Firestore y '
              'autenticación). Los reportes y coincidencias que ya '
              'generaste se conservan como historial de la plataforma '
              '(otros usuarios pueden depender de ellos), pero dejan de '
              'estar asociados a una cuenta activa tuya.',
            ),
          ),
          const SizedBox(height: 16),
          const SectionCard(
            titulo: 'Seguridad',
            icono: Icons.lock_outline,
            child: Text(
              'Las contraseñas nunca son manejadas por nuestros servidores '
              '— la autenticación corre directamente contra Firebase '
              'Authentication. Las comunicaciones entre la app y nuestros '
              'servidores usan HTTPS. El acceso administrativo está '
              'protegido y limitado a funciones de soporte.',
            ),
          ),
        ],
      ),
    );
  }
}
