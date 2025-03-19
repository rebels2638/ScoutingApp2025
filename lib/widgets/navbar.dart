import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// create a stream controller for scouting leader changes
final _scoutingLeaderController = StreamController<bool>.broadcast();

// function to notify listeners when the setting changes
void notifyScoutingLeaderChange(bool value) {
  _scoutingLeaderController.add(value);
}

class NavBar extends StatefulWidget {
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
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  bool? _isScoutingLeader;
  StreamSubscription? _scoutingLeaderSubscription;

  @override
  void initState() {
    super.initState();
    _loadScoutingLeaderStatus();
    
    // subscribe to scouting leader changes
    _scoutingLeaderSubscription = _scoutingLeaderController.stream.listen((enabled) {
      if (mounted) {
        setState(() {
          _isScoutingLeader = enabled;
        });
      }
    });
  }

  @override
  void dispose() {
    _scoutingLeaderSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadScoutingLeaderStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {  // check if widget is still mounted before setting state
      setState(() {
        _isScoutingLeader = prefs.getBool('scouting_leader_enabled') ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isScoutingLeader == null) {
      // return the current navbar staqte while loading to prevent flickering
      return BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Scout',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.data_usage),
            label: 'Data',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.api),
            label: 'API',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'About',
          ),
        ],
        currentIndex: widget.currentIndex,
        onTap: widget.onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
      );
    }

    // Create base items list
    final items = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Icon(
          Icons.assignment,
        ),
        label: 'Scout',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.data_usage),
        label: 'Data',
      ),
      
      const BottomNavigationBarItem(
      icon: Icon(Icons.api),
      label: 'API',
    )
    ];
    
    
    // add analysis tab only if scouting leader is enabled
    if (_isScoutingLeader!) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.analytics),
        label: 'Analysis',
      ));
    }

    

    // Add Bluetooth item if enabled
    if (widget.showBluetooth) {
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

    // calculate display index based on current state
    int displayIndex = widget.currentIndex;
    if (!_isScoutingLeader! && displayIndex > 2) {
      displayIndex--;  // adjust for missing analysis tab
    }
    if (!widget.showBluetooth && displayIndex >= (_isScoutingLeader! ? 4 : 3)) {
      displayIndex--;  // adjust for missing bluetooth tab
    }

    return BottomNavigationBar(
      items: items,
      currentIndex: displayIndex,
      onTap: (index) {
        // convert display index back to actual index
        int actualIndex = index;
        if (!_isScoutingLeader!) {
          // When scouting leader is off, adjust for missing analysis tab
          if (index > 2) {
            actualIndex++;  // skip the analysis tab position
          }
          // Then adjust for bluetooth if needed
          if (!widget.showBluetooth && actualIndex >= 3) {
            actualIndex++;  // adjust for missing bluetooth tab
          }
        } else {
          // When scouting leader is on, only adjust for bluetooth if needed
          if (!widget.showBluetooth && actualIndex >= 4) {
            actualIndex++;  // adjust for missing bluetooth tab
          }
        }
        widget.onTap(actualIndex);
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
    );
  }
} 