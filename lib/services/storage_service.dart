import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_info.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();
  
  // Clave para almacenar dispositivos vinculados
  static const String _pairedDevicesKey = 'paired_devices';
  static const String _selectedAppsKey = 'selected_apps';
  
  // Guardar dispositivos vinculados
  Future<void> savePairedDevice(String deviceName, String deviceAddress) async {
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
    }
  }
  
  // Obtener dispositivos vinculados
  Future<List<Map<String, String>>> getPairedDevices() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> devices = prefs.getStringList(_pairedDevicesKey) ?? [];
    
    return devices.map((deviceJson) {
      Map<String, dynamic> deviceMap = jsonDecode(deviceJson);
      return {
        'name': deviceMap['name'] as String,
        'address': deviceMap['address'] as String,
      };
    }).toList();
  }
  
  // Guardar aplicaciones seleccionadas
  Future<void> saveSelectedApps(List<AppInfo> apps) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Filtrar solo las aplicaciones seleccionadas
    List<AppInfo> selectedApps = apps.where((app) => app.isSelected).toList();
    
    // Convertir a lista de mapas
    List<Map<String, dynamic>> appMaps = selectedApps.map((app) => {
      'name': app.name,
      'packageName': app.packageName,
      'isSelected': app.isSelected,
      'color': app.color.toARGB32(),
      'iconData': app.iconData.codePoint,
    }).toList();
    
    // Guardar como JSON
    String appsJson = jsonEncode(appMaps);
    await prefs.setString(_selectedAppsKey, appsJson);
  }
  
  // Obtener aplicaciones seleccionadas
  Future<List<String>> getSelectedAppPackages() async {
    final prefs = await SharedPreferences.getInstance();
    String? appsJson = prefs.getString(_selectedAppsKey);
    
    if (appsJson == null) return [];
    
    List<dynamic> appMaps = jsonDecode(appsJson);
    return appMaps.map<String>((app) => app['packageName'] as String).toList();
  }
}