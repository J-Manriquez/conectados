import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import '../models/app_info.dart' as MyAppInfo;
import '../services/storage_service.dart';

class AppSelectionPage extends StatefulWidget {
  const AppSelectionPage({super.key});

  @override
  State<AppSelectionPage> createState() => _AppSelectionPageState();
}

class _AppSelectionPageState extends State<AppSelectionPage> {
  List<AppInfo> _apps = [];
  List<AppInfo> _selectedApps = [];
  bool _isLoading = true;
  final StorageService _storageService = StorageService();
  
  @override
  void initState() {
    super.initState();
    _loadApps();
  }
  
  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('[_loadApps] Iniciando carga de aplicaciones...'); // Log de inicio
      var apps = await compute(_loadAppsInBackground, null);
      print('[_loadApps] Aplicaciones cargadas en segundo plano: ${apps.length}'); // Log de cantidad

      if (apps.isEmpty) {
        print('[_loadApps] No se encontraron aplicaciones instaladas.'); // Log de apps vacías
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontraron aplicaciones instaladas'),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }
      
      // Ordenar alfabéticamente
      apps.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
      print('[_loadApps] Aplicaciones ordenadas.'); // Log de ordenamiento
      
      // Cargar aplicaciones previamente seleccionadas
      List<String> savedPackages = await _storageService.getSelectedAppPackages();
      print('[_loadApps] Paquetes guardados cargados: ${savedPackages.length}'); // Log de paquetes guardados
      
      setState(() {
        _apps = apps;
        _selectedApps = apps.where((app) {
          final package = app.packageName;
          return package != null && savedPackages.contains(package);
        }).toList();
        _isLoading = false;
        print('[_loadApps] Estado actualizado. Total apps: ${_apps.length}, Apps seleccionadas: ${_selectedApps.length}'); // Log de estado final
      });
    } catch (e) {
      print('[_loadApps] Error al cargar aplicaciones: $e'); // Log de error
      setState(() {
        _isLoading = false;
      });
      
      // Mostrar un mensaje de error más descriptivo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar aplicaciones: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
  
  void _toggleAppSelection(AppInfo app) {
    setState(() {
      if (_selectedApps.contains(app)) {
        _selectedApps.remove(app);
        print('[_toggleAppSelection] Deseleccionada: ${app.name}'); // Log de deselección
      } else {
        _selectedApps.add(app);
        print('[_toggleAppSelection] Seleccionada: ${app.name}'); // Log de selección
      }
      print('[_toggleAppSelection] Apps seleccionadas: ${_selectedApps.length}'); // Log de total seleccionadas
    });
  }
  
  void _saveSelection() async {
    print('[_saveSelection] Guardando selección...'); // Log de inicio de guardado
    // Guardar la selección de aplicaciones
    List<String> selectedPackages = _selectedApps
        .where((app) => app.packageName != null)
        .map((app) => app.packageName!)
        .toList();
    print('[_saveSelection] Paquetes seleccionados para guardar: ${selectedPackages.length}'); // Log de paquetes a guardar
    
    // Convertir a nuestro modelo de AppInfo para guardar
    List<MyAppInfo.AppInfo> myAppInfoList = _selectedApps
        .where((app) => app.packageName != null && app.name != null)
        .map((app) => MyAppInfo.AppInfo(
          name: app.name!,
          packageName: app.packageName!,
          isSelected: true,
          color: Colors.blue, // Color predeterminado
          iconData: Icons.android, // Icono predeterminado
        ))
        .toList();
    print('[_saveSelection] Convertidas a MyAppInfo: ${myAppInfoList.length}'); // Log de conversión
    
    // Guardar en preferencias
    await _storageService.saveSelectedApps(myAppInfoList);
    print('[_saveSelection] Selección guardada en StorageService.'); // Log de guardado completado
    
    Navigator.pop(context, selectedPackages);
    print('[_saveSelection] Navegando de regreso.'); // Log de navegación
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Aplicaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveSelection,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _apps.length,
              itemBuilder: (context, index) {
                AppInfo app = _apps[index];
                bool isSelected = _selectedApps.contains(app);
                
                return ListTile(
                  leading: app.icon != null
                      ? Image.memory(app.icon!, width: 40, height: 40)
                      : const Icon(Icons.android),
                  title: Text(app.name ?? 'Sin nombre'),
                  subtitle: Text(app.packageName ?? ''),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      _toggleAppSelection(app);
                    },
                  ),
                  onTap: () {
                    _toggleAppSelection(app);
                  },
                );
              },
            ),
    );
  }
}

// Añadir esta función al final del archivo
Future<List<AppInfo>> _loadAppsInBackground(_) async {
  try {
    print('[_loadAppsInBackground] Obteniendo aplicaciones instaladas...'); // Log de inicio
    List<AppInfo> apps = (await InstalledApps.getInstalledApps(false, true))
        .where((app) => app.packageName?.isNotEmpty ?? false)
        .toList();
    print('[_loadAppsInBackground] Total de aplicaciones obtenidas: ${apps.length}'); // Log de total obtenidas

    // No filtrar, mostrar todas las apps
    // apps = apps.where((app) {
    //   final package = app.packageName;
    //   if (package == null) return false;
    //   return !package.startsWith('com.android.') &&
    //          !package.startsWith('com.google.') &&
    //          !package.contains('.provider') &&
    //          !package.contains('.core');
    // }).toList();

    apps.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    print('[_loadAppsInBackground] Aplicaciones ordenadas.'); // Log de ordenamiento
    return apps;
  } catch (e) {
    print('[_loadAppsInBackground] Error en segundo plano: $e'); // Log de error
    return [];
  }
}