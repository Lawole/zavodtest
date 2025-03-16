import 'package:flutter/material.dart';
import 'package:zavodtest/screens/profile_screen.dart';
import 'package:zavodtest/screens/support_screen.dart';

import 'history_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book,
                    size: 50,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildMenuItem(
              context,
              icon: Icons.person_outline,
              title: 'Profile',
              subtitle: 'View and edit your info',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileScreen()),
                );
              },
            ),
            const Divider(height: 1, thickness: 0.5),
            _buildMenuItem(
              context,
              icon: Icons.help_outline,
              title: 'Support',
              subtitle: 'Get assistance',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SupportScreen()),
                );
              },
            ),
            const Divider(height: 1, thickness: 0.5),
            _buildMenuItem(
              context,
              icon: Icons.history,
              title: 'History',
              subtitle: 'Check past activities',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HistoryScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.grey[100],
        child: const Center(
          child: Text(
            'Click the menu icon to explore options',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 28,
        color: Theme.of(context).primaryColor,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close the drawer
        onTap();
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tileColor: Colors.white,
      hoverColor: Colors.grey[200],
    );
  }
}
