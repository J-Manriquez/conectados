import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_info.dart';
import 'flow_log_service.dart'; // Importar FlowLogService
import 'error_service.dart'; // Importar ErrorService

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Clave para almacenar dispositivos vinculados
  static const String _pairedDevicesKey = 'paired_devices';
  static const String _selectedAppsKey = 'selected_apps';

  final FlowLogService _flowLogService = FlowLogService(); // Instancia de FlowLogService
  final ErrorService _errorService = ErrorService(); // Instancia de ErrorService

  // Guardar dispositivos vinculados
  Future<void> savePairedDevice(String deviceName, String deviceAddress) async {
    _flowLogService.logFlow(script: 'storage_service.dart - savePairedDevice', message: 'Intentando guardar dispositivo vinculado: $deviceName ($deviceAddress).');
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> devices = prefs.getStringList(_pairedDevicesKey) ?? [];

      // Crear un mapa con la información del dispositivo
      Map<String, String> deviceInfo = {
        'name': deviceName,
        'address': deviceAddress,
      };

      // Convertir a JSON y guardar
      String deviceJson = jsonEncode(deviceInfo);
      if (!devices.contains(deviceJson)) {
        devices.add(deviceJson);
        await prefs.setStringList(_pairedDevicesKey, devices);
        _flowLogService.logFlow(script: 'storage_service.dart - savePairedDevice', message: 'Dispositivo guardado con éxito.');
      } else {
        _flowLogService.logFlow(script: 'storage_service.dart - savePairedDevice', message: 'Dispositivo ya existe en la lista. No se guarda de nuevo.');
      }
    } catch (e, st) {
      _errorService.logError(
        script: 'storage_service.dart - savePairedDevice',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(script: 'storage_service.dart - savePairedDevice', message: 'Error al guardar dispositivo vinculado: ${e.toString()}');
    }
  }

  // Obtener dispositivos vinculados
  Future<List<Map<String, String>>> getPairedDevices() async {
    _flowLogService.logFlow(script: 'storage_service.dart - getPairedDevices', message: 'Intentando obtener dispositivos vinculados.');
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> devices = prefs.getStringList(_pairedDevicesKey) ?? [];

      List<Map<String, String>> pairedDevices = devices.map((deviceJson) {
        Map<String, dynamic> deviceMap = jsonDecode(deviceJson);
        return {
          'name': deviceMap['name'] as String,
          'address': deviceMap['address'] as String,
        };
      }).toList();
      _flowLogService.logFlow(script: 'storage_service.dart - getPairedDevices', message: 'Dispositivos vinculados obtenidos: ${pairedDevices.length}.');
      return pairedDevices;
    } catch (e, st) {
      _errorService.logError(
        script: 'storage_service.dart - getPairedDevices',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(script: 'storage_service.dart - getPairedDevices', message: 'Error al obtener dispositivos vinculados: ${e.toString()}');
      return []; // Devolver lista vacía en caso de error
    }
  }

  // Guardar aplicaciones seleccionadas
  Future<void> saveSelectedApps(List<AppInfo> apps) async {
    _flowLogService.logFlow(script: 'storage_service.dart - saveSelectedApps', message: 'Intentando guardar aplicaciones seleccionadas.');
    try {
      final prefs = await SharedPreferences.getInstance();

      // Filtrar solo las aplicaciones seleccionadas
      List<AppInfo> selectedApps = apps.where((app) => app.isSelected).toList();
      _flowLogService.logFlow(script: 'storage_service.dart - saveSelectedApps', message: 'Filtradas ${selectedApps.length} aplicaciones seleccionadas de ${apps.length} totales.');

      // Convertir a lista de mapas
      List<Map<String, dynamic>> appMaps = selectedApps.map((app) => {
        'name': app.name,
        'packageName': app.packageName,
        'isSelected': app.isSelected,
        'color': app.color.toARGB32(),
        'iconData': app.iconData.codePoint,
      }).toList();
      _flowLogService.logFlow(script: 'storage_service.dart - saveSelectedApps', message: 'Convertidas a mapa para JSON.');

      // Guardar como JSON
      String appsJson = jsonEncode(appMaps);
      await prefs.setString(_selectedAppsKey, appsJson);
      _flowLogService.logFlow(script: 'storage_service.dart - saveSelectedApps', message: 'Aplicaciones seleccionadas guardadas con éxito.');
    } catch (e, st) {
      _errorService.logError(
        script: 'storage_service.dart - saveSelectedApps',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(script: 'storage_service.dart - saveSelectedApps', message: 'Error al guardar aplicaciones seleccionadas: ${e.toString()}');
    }
  }

  // Obtener aplicaciones seleccionadas
  Future<List<String>> getSelectedAppPackages() async {
    _flowLogService.logFlow(script: 'storage_service.dart - getSelectedAppPackages', message: 'Intentando obtener paquetes de aplicaciones seleccionadas.');
    try {
      final prefs = await SharedPreferences.getInstance();
      String? appsJson = prefs.getString(_selectedAppsKey);

      // Manejar el caso donde appsJson es null (no hay apps guardadas)
      if (appsJson == null) {
        _flowLogService.logFlow(script: 'storage_service.dart - getSelectedAppPackages', message: 'No se encontraron aplicaciones seleccionadas guardadas. Devolviendo lista vacía.');
        return []; // Devolver una lista vacía si no hay datos guardados
      }

      // Si appsJson no es null, decodificarlo
      List<dynamic> appMaps = jsonDecode(appsJson);
      List<String> selectedPackages = appMaps.map<String>((app) => app['packageName'] as String).toList();
      _flowLogService.logFlow(script: 'storage_service.dart - getSelectedAppPackages', message: 'Paquetes de aplicaciones seleccionadas obtenidos: ${selectedPackages.length}.');
      return selectedPackages;
    } catch (e, st) {
      _errorService.logError(
        script: 'storage_service.dart - getSelectedAppPackages',
        error: e,
        stackTrace: st,
      );
      _flowLogService.logFlow(script: 'storage_service.dart - getSelectedAppPackages', message: 'Error al obtener paquetes de aplicaciones seleccionadas: ${e.toString()}');
      return []; // Devolver lista vacía en caso de error
    }
  }
}