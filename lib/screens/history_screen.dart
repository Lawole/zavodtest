import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> _navigationHistory = [
    {
      'route': 'Home to Office',
      'time': '10:00 AM, Mar 16, 2025',
      'distance': '5.2 km',
    },
    {
      'route': 'Office to Cafe',
      'time': '12:00 PM, Mar 16, 2025',
      'distance': '2.8 km',
    },
    {
      'route': 'Cafe to Park',
      'time': '2:00 PM, Mar 16, 2025',
      'distance': '3.5 km',
    },
    {
      'route': 'Park to Gym',
      'time': '4:00 PM, Mar 16, 2025',
      'distance': '4.1 km',
    },
    {
      'route': 'Gym to Home',
      'time': '6:00 PM, Mar 16, 2025',
      'distance': '6.0 km',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation History'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _animationController.forward(from: 0); // Restart animation
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History refreshed')),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _navigationHistory.length,
          itemBuilder: (context, index) {
            return FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index * 0.1, // Staggered animation for each item
                    1.0,
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
              child: _buildHistoryCard(_navigationHistory[index], index),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, String> record, int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_car,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record['route']!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record['time']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Distance: ${record['distance']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.grey),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Details for ${record['route']}')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}