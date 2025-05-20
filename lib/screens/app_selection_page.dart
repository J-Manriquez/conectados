import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';

class AppSelectionPage extends StatefulWidget {
  const AppSelectionPage({super.key});

  @override
  State<AppSelectionPage> createState() => _AppSelectionPageState();
}

class _AppSelectionPageState extends State<AppSelectionPage> {
  List<Application> _apps = [];
  List<Application> _selectedApps = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadApps();
  }
  
  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
    });
    
    List<Application> apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: false,
      onlyAppsWithLaunchIntent: true,
    );
    
    // Ordenar alfabéticamente
    apps.sort((a, b) => a.appName.compareTo(b.appName));
    
    setState(() {
      _apps = apps;
      _isLoading = false;
    });
  }
  
  void _toggleAppSelection(Application app) {
    setState(() {
      if (_selectedApps.contains(app)) {
        _selectedApps.remove(app);
      } else {
        _selectedApps.add(app);
      }
    });
  }
  
  void _saveSelection() {
    // Guardar la selección de aplicaciones
    List<String> selectedPackages = _selectedApps.map((app) => app.packageName).toList();
    
    // Aquí implementaríamos la lógica para guardar en preferencias
    
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
                Application app = _apps[index];
                bool isSelected = _selectedApps.contains(app);
                
                return ListTile(
                  leading: app is ApplicationWithIcon
                      ? Image.memory(app.icon, width: 40, height: 40)
                      : const Icon(Icons.android),
                  title: Text(app.appName),
                  subtitle: Text(app.packageName),
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