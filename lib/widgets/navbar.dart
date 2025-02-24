import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool showBluetooth;

  const NavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.showBluetooth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create base items list
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.edit_note),
        label: 'Scout',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.data_usage),
        label: 'Data',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.api),
        label: 'API',
      ),
    ];

    // Add Bluetooth item if enabled
    if (showBluetooth) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.bluetooth),
        label: 'Bluetooth',
      ));
    }

    // Add remaining items
    items.addAll([
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Settings',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.info),
        label: 'About',
      ),
    ]);

    // Calculate display index based on whether Bluetooth is shown
    int displayIndex = currentIndex;
    if (!showBluetooth && currentIndex >= 3) {
      displayIndex--;
    }

    return BottomNavigationBar(
      items: items,
      currentIndex: displayIndex,
      onTap: (index) {
        // Convert display index back to actual index
        final actualIndex = (!showBluetooth && index >= 3) ? index + 1 : index;
        onTap(actualIndex);
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
    );
  }
} 