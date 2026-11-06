import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Datos técnicos que se adjuntan automáticamente a cada falla reportada.
///
/// Ayudan al superadministrador a reproducir el problema sin tener que
/// preguntarle al usuario qué dispositivo o versión estaba usando.
class AppMetadata {
  const AppMetadata({
    this.plataforma,
    this.sistemaOperativo,
    this.dispositivo,
    this.versionApp,
  });

  final String? plataforma;
  final String? sistemaOperativo;
  final String? dispositivo;
  final String? versionApp;

  bool get isEmpty =>
      plataforma == null &&
      sistemaOperativo == null &&
      dispositivo == null &&
      versionApp == null;
}

/// Lee la información del dispositivo y de la app.
///
/// Nunca lanza: si un plugin no está disponible (por ejemplo en pruebas), se
/// devuelven solo los datos que se hayan podido obtener.
Future<AppMetadata> leerAppMetadata() async {
  String? plataforma;
  String? sistemaOperativo;
  String? dispositivo;

  try {
    final DeviceInfoPlugin plugin = DeviceInfoPlugin();
    final BaseDeviceInfo info = await plugin.deviceInfo;
    if (info is AndroidDeviceInfo) {
      plataforma = 'Android';
      sistemaOperativo =
          'Android ${info.version.release} (API ${info.version.sdkInt})';
      dispositivo = '${info.manufacturer} ${info.model}'.trim();
    } else if (info is IosDeviceInfo) {
      plataforma = 'iOS';
      sistemaOperativo = 'iOS ${info.systemVersion}';
      dispositivo = info.utsname.machine;
    } else if (info is MacOsDeviceInfo) {
      plataforma = 'macOS';
      sistemaOperativo = 'macOS ${info.osRelease}';
      dispositivo = info.model;
    } else if (info is WindowsDeviceInfo) {
      plataforma = 'Windows';
      sistemaOperativo = 'Windows ${info.majorVersion}.${info.minorVersion}';
      dispositivo = info.productName;
    } else if (info is LinuxDeviceInfo) {
      plataforma = 'Linux';
      sistemaOperativo = info.prettyName;
      dispositivo = info.name;
    }
  } catch (_) {
    // Sin acceso a los datos del dispositivo: se continúa sin ellos.
  }

  String? versionApp;
  try {
    final PackageInfo paquete = await PackageInfo.fromPlatform();
    final String build = paquete.buildNumber.trim();
    versionApp = build.isEmpty ? paquete.version : '${paquete.version}+$build';
  } catch (_) {
    // La app puede seguir reportando la falla sin la versión.
  }

  return AppMetadata(
    plataforma: _limpiar(plataforma),
    sistemaOperativo: _limpiar(sistemaOperativo),
    dispositivo: _limpiar(dispositivo),
    versionApp: _limpiar(versionApp),
  );
}

String? _limpiar(String? valor) {
  final String texto = (valor ?? '').trim();
  if (texto.isEmpty) return null;
  // Los valores se muestran como chips: se evita guardar cadenas enormes.
  return texto.length <= 80 ? texto : texto.substring(0, 80);
}
