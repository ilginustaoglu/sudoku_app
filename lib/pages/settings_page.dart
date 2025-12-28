import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Uygulama Ayarları',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Tema'),
            subtitle: const Text('Uygulama temasını değiştir'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Tema ayarları (gelecekte eklenecek)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tema ayarları yakında eklenecek')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.volume_up),
            title: const Text('Ses'),
            subtitle: const Text('Ses efektlerini aç/kapat'),
            trailing: Switch(
              value: true, // Gelecekte state'ten gelecek
              onChanged: (value) {
                // Ses ayarı (gelecekte eklenecek)
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Hakkında'),
            subtitle: const Text('Uygulama bilgileri'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Sudoku Master',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.grid_4x4, size: 48),
              );
            },
          ),
        ],
      ),
    );
  }
}

