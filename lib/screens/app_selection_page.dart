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
      // Verificar permiso QUERY_ALL_PACKAGES
      List<AppInfo> apps = await InstalledApps.getInstalledApps(false, true);

      if (apps.isEmpty) {
        print('No se encontraron aplicaciones');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontraron aplicaciones instaladas'),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }
      // Filtrar aplicaciones del sistema de manera más precisa
      apps = apps.where((app) => 
        app.packageName != null && 
        !app.packageName!.startsWith('com.android.') &&
        !app.packageName!.startsWith('com.google.') &&
        !app.packageName!.contains('.provider') &&
        !app.packageName!.contains('.core')
      ).toList();
      
      if (apps.isEmpty) {
        print('No se encontraron aplicaciones o no se tienen los permisos necesarios');
        // Mostrar un mensaje al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudieron cargar las aplicaciones. Verifica los permisos de la aplicación.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
      
      // Filtrar aplicaciones del sistema si es necesario
      apps = apps.where((app) => 
        app.packageName != null && 
        !app.packageName!.startsWith('com.android') &&
        !app.packageName!.startsWith('com.google.android')
      ).toList();
      
      // Ordenar alfabéticamente
      apps.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
      
      // Cargar aplicaciones previamente seleccionadas
      List<String> savedPackages = await _storageService.getSelectedAppPackages();
      
      setState(() {
        _apps = apps;
        _selectedApps = apps.where((app) => 
          app.packageName != null && 
          savedPackages.contains(app.packageName)
        ).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar aplicaciones: $e');
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
      } else {
        _selectedApps.add(app);
      }
    });
  }
  
  void _saveSelection() async {
    // Guardar la selección de aplicaciones
    List<String> selectedPackages = _selectedApps
        .where((app) => app.packageName != null)
        .map((app) => app.packageName!)
        .toList();
    
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
    
    // Guardar en preferencias
    await _storageService.saveSelectedApps(myAppInfoList);
    
    Navigator.pop(context, selectedPackages);
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