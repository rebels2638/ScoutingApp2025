import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // date time format
import 'data.dart';
import 'dart:developer' as developer;
import 'settings.dart';
import 'about.dart';
import 'main.dart';  // Add this import for ThemeProvider
import 'widgets/navbar.dart';
import 'widgets/topbar.dart';

class ScoutingPage extends StatefulWidget {
  @override
  _ScoutingPageState createState() => _ScoutingPageState();
}

class _ScoutingPageState extends State<ScoutingPage> {
  int _currentIndex = 0; // For managing navigation bar

  // State variables for Match Information
  int matchNumber = 0;
  String matchType = 'Unset';
  String currentTime = '';

  // State variables for Team Information
  int teamNumber = 0;
  bool isRedAlliance = true;

  // State variables for Autonomous
  String cageType = 'Shallow';
  bool coralPreloaded = false;
  bool taxis = false;
  int algaeRemoved = 0;
  String coralPlaced = 'No';
  bool rankingPoint = false;

  // State variables for Tele-op
  int algaeScoredInNet = 0;
  int coralOnReefHeight1 = 0;
  int coralOnReefHeight2 = 0;
  int coralOnReefHeight3 = 0;
  int coralOnReefHeight4 = 0;
  bool coralRankingPoint = false;
  int algaeProcessed = 0;
  int processedAlgaeScored = 0;
  bool coOpPoint = false;

  // State variables for Endgame
  bool returnedToBarge = false;
  String cageHang = 'None';
  bool bargeRankingPoint = false;

  // State variables for Other Section
  bool breakdown = false;
  String comments = '';

  // Add new state variable for algae pickup
  bool canPickupAlgae = false;

  // Add new state variable for processor cycles
  int processorCycles = 0;

  @override
  void initState() {
    super.initState();
    updateTime();
  }

  void updateTime() {
    setState(() {
      currentTime = DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now());
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // navbar redirects
  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return _buildScoutingPage();
      case 1:
        return DataPage();
      case 2:
        return SettingsPage();
      case 3:
        return AboutPage();
      default:
        return _buildScoutingPage();
    }
  }

  Widget _buildScoutingPage() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Match Information Section
        SectionHeader(title: 'Match Information', icon: Icons.view_module),
        InfoRow(label: 'Time', value: currentTime),
        CounterRow(
          label: 'Number',
          value: matchNumber,
          onIncrement: () {
            setState(() {
              matchNumber++;
            });
          },
          onDecrement: () {
            if (matchNumber > 0) {
              setState(() {
                matchNumber--;
              });
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: 'Type'),
            value: matchType,
            items: ['Unset', 'Practice', 'Qualification', 'Playoff']
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) {
              setState(() {
                matchType = value!;
              });
            },
          ),
        ),
        SizedBox(height: 20),
        SectionHeader(title: 'Team Information', icon: Icons.people),
        TeamNumberSelector(
          initialValue: teamNumber,
          onChanged: (value) {
            setState(() {
              teamNumber = value;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Alliance', style: TextStyle(fontSize: 16)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ToggleButtons(
                  borderRadius: BorderRadius.circular(8),
                  selectedBorderColor: Colors.transparent,
                  borderWidth: 1,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? (isRedAlliance ? Colors.red.shade900 : Colors.blue.shade900)
                      : (isRedAlliance ? Colors.red.shade300 : Colors.blue.shade300),
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  selectedColor: Theme.of(context).textTheme.bodyLarge?.color,
                  constraints: BoxConstraints(minWidth: 100, minHeight: 40),
                  isSelected: [isRedAlliance, !isRedAlliance],
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'RED',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'BLUE',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ],
                  onPressed: (index) {
                    setState(() {
                      isRedAlliance = index == 0;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Divider(),
        // Autonomous Section
        SectionHeader(title: 'Autonomous', icon: Icons.settings),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ToggleRow(
            label: 'Cage Type',
            options: ['SHALLOW', 'DEEP'],
            selectedIndex: cageType == 'Shallow' ? 0 : 1,
            onSelected: (index) {
              setState(() {
                cageType = index == 0 ? 'Shallow' : 'Deep';
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ToggleRow(
            label: 'Coral Preloaded?',
            options: ['YES', 'NO'],
            selectedIndex: coralPreloaded ? 0 : 1,
            onSelected: (index) {
              setState(() {
                coralPreloaded = index == 0;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ToggleRow(
            label: 'Taxis?',
            options: ['YES', 'NO'],
            selectedIndex: taxis ? 0 : 1,
            onSelected: (index) {
              setState(() {
                taxis = index == 0;
              });
            },
          ),
        ),
        CounterRow(
          label: 'Num. of Algae Removed',
          value: algaeRemoved,
          onIncrement: () {
            setState(() {
              algaeRemoved++;
            });
          },
          onDecrement: () {
            if (algaeRemoved > 0) {
              setState(() {
                algaeRemoved--;
              });
            }
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Coral Placed?', style: TextStyle(fontSize: 16)),
            DropdownButton<String>(
              value: coralPlaced,
              items: ['No', 'Height 1', 'Height 2', 'Height 3', 'Height 4']
                  .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  coralPlaced = value!;
                });
              },
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ToggleRow(
            label: 'Ranking Point?',
            options: ['YES', 'NO'],
            selectedIndex: rankingPoint ? 0 : 1,
            onSelected: (index) {
              setState(() {
                rankingPoint = index == 0;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ToggleRow(
            label: 'Algae ground pickup?',
            options: ['YES', 'NO'],
            selectedIndex: canPickupAlgae ? 0 : 1,
            onSelected: (index) {
              setState(() {
                canPickupAlgae = index == 0;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: CounterRow(
            label: 'Coral Ranking Point?',
            value: coralRankingPoint ? 0 : 1,
            onIncrement: () => setState(() => coralRankingPoint = true),
            onDecrement: () => setState(() => coralRankingPoint = false),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: CounterRow(
            label: 'Algae Processed',
            value: algaeProcessed,
            onIncrement: () => setState(() => algaeProcessed++),
            onDecrement: () => setState(() {
              if (algaeProcessed > 0) algaeProcessed--;
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: CounterRow(
            label: 'Processed Algae Scored',
            value: processedAlgaeScored,
            onIncrement: () => setState(() => processedAlgaeScored++),
            onDecrement: () => setState(() {
              if (processedAlgaeScored > 0) processedAlgaeScored--;
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: CounterRow(
            label: 'Number of processor cycles',
            value: processorCycles,
            onIncrement: () => setState(() => processorCycles++),
            onDecrement: () => setState(() {
              if (processorCycles > 0) processorCycles--;
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ToggleRow(
            label: 'Co-op Point?',
            options: ['YES', 'NO'],
            selectedIndex: coOpPoint ? 0 : 1,
            onSelected: (index) {
              setState(() {
                coOpPoint = index == 0;
              });
            },
          ),
        ),
        Divider(),
        // Endgame Section
        SectionHeader(title: 'Endgame', icon: Icons.flag),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ToggleRow(
            label: 'Returned to Barge?',
            options: ['YES', 'NO'],
            selectedIndex: returnedToBarge ? 0 : 1,
            onSelected: (index) {
              setState(() {
                returnedToBarge = index == 0;
              });
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Cage Hang', style: TextStyle(fontSize: 16)),
            DropdownButton<String>(
              value: cageHang,
              items: ['None', 'Shallow', 'Deep']
                  .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  cageHang = value!;
                });
              },
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ToggleRow(
            label: 'Barge Ranking Point?',
            options: ['YES', 'NO'],
            selectedIndex: bargeRankingPoint ? 0 : 1,
            onSelected: (index) {
              setState(() {
                bargeRankingPoint = index == 0;
              });
            },
          ),
        ),
        Divider(),
        // Other Section
        SectionHeader(title: 'Other', icon: Icons.miscellaneous_services),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ToggleRow(
            label: 'Breakdown?',
            options: ['YES', 'NO'],
            selectedIndex: breakdown ? 0 : 1,
            onSelected: (index) {
              setState(() {
                breakdown = index == 0;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            maxLength: 150,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Comments',
              border: OutlineInputBorder(),
              counterText: '${comments.length}/150',
            ),
            onChanged: (value) {
              setState(() {
                comments = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Future<void> _saveRecord() async {
    try {
      final record = ScoutingRecord(
        timestamp: currentTime,
        matchNumber: matchNumber,
        matchType: matchType,
        teamNumber: teamNumber,
        isRedAlliance: isRedAlliance,
        cageType: cageType,
        coralPreloaded: coralPreloaded,
        taxis: taxis,
        algaeRemoved: algaeRemoved,
        coralPlaced: coralPlaced,
        rankingPoint: rankingPoint,
        canPickupAlgae: canPickupAlgae,
        algaeScoredInNet: algaeScoredInNet,
        coralRankingPoint: coralRankingPoint,
        algaeProcessed: algaeProcessed,
        processedAlgaeScored: processedAlgaeScored,
        processorCycles: processorCycles,
        coOpPoint: coOpPoint,
        returnedToBarge: returnedToBarge,
        cageHang: cageHang,
        bargeRankingPoint: bargeRankingPoint,
        breakdown: breakdown,
        comments: comments,
      );

      await DataManager.saveRecord(record);
      
      // Show success message
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Match data saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reset form
      setState(() {
        matchNumber = matchNumber + 1; // Increment match number
        algaeRemoved = 0;
        algaeScoredInNet = 0;
        coralOnReefHeight1 = 0;
        coralOnReefHeight2 = 0;
        coralOnReefHeight3 = 0;
        coralOnReefHeight4 = 0;
        algaeProcessed = 0;
        processedAlgaeScored = 0;
        processorCycles = 0;
        coralPlaced = 'No';
        cageHang = 'None';
        comments = '';
        taxis = false;
        rankingPoint = false;
        coralRankingPoint = false;
        coOpPoint = false;
        returnedToBarge = false;
        bargeRankingPoint = false;
        breakdown = false;
        updateTime();
      });

    } catch (e) {
      developer.log('Error saving record: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving match data'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
        title: _currentIndex == 0 ? 'Scouting' :
               _currentIndex == 1 ? 'Data' :
               _currentIndex == 2 ? 'Settings' :
               'About',
        actions: _currentIndex == 0 ? [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveRecord,
          ),
        ] : null,
      ),
      body: _getPage(_currentIndex),
      bottomNavigationBar: NavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class TeamNumberSelector extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onChanged;

  const TeamNumberSelector({
    Key? key,
    required this.initialValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  _TeamNumberSelectorState createState() => _TeamNumberSelectorState();
}

class _TeamNumberSelectorState extends State<TeamNumberSelector> {
  late List<int> selectedDigits;
  bool isOpen = false;
  
  @override
  void initState() {
    super.initState();
    selectedDigits = _numberToDigits(widget.initialValue);
  }

  List<int> _numberToDigits(int number) {
    String numStr = number.toString().padLeft(4, '0');
    return numStr.split('').map(int.parse).toList();
  }

  void _updateTeamNumber() {
    int number = selectedDigits.fold(0, (prev, digit) => prev * 10 + digit);
    widget.onChanged(number);
  }

  void _toggleSelector() {
    setState(() {
      isOpen = !isOpen;
    });
    if (isOpen) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.2,
          maxChildSize: 0.8,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                Text(
                  'Select Team Number',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (columnIndex) {
                      return SizedBox(
                        width: 60,
                        child: ListWheelScrollView(
                          controller: FixedExtentScrollController(
                            initialItem: selectedDigits[columnIndex],
                          ),
                          itemExtent: 40,
                          physics: FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              selectedDigits[columnIndex] = index;
                              _updateTeamNumber();
                            });
                          },
                          children: List.generate(
                            10,
                            (index) => Container(
                              alignment: Alignment.center,
                              child: Text(
                                index.toString(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Done'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).then((_) => setState(() => isOpen = false));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Number', style: TextStyle(fontSize: 16)),
          InkWell(
            onTap: _toggleSelector,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedDigits.fold('', (prev, digit) => prev + digit.toString()),
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.black),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class ToggleRow extends StatelessWidget {
  final String label;
  final List<String> options;
  final int selectedIndex;
  final Function(int) onSelected;

  const ToggleRow({
    required this.label,
    required this.options,
    required this.onSelected,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        ToggleButtons(
          borderRadius: BorderRadius.circular(8),
          selectedBorderColor: Colors.transparent,
          borderWidth: 1,
          fillColor: selectedIndex == 0 
              ? (isDark ? Colors.blue.shade900 : Colors.green.shade300)
              : (isDark ? Colors.red.shade900 : Colors.red.shade300),
          color: Theme.of(context).textTheme.bodyLarge?.color,
          selectedColor: Theme.of(context).textTheme.bodyLarge?.color,
          constraints: BoxConstraints(minWidth: 100, minHeight: 40),
          isSelected: List.generate(
            options.length,
            (index) => index == selectedIndex,
          ),
          children: options.map((option) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(option),
          )).toList(),
          onPressed: onSelected,
        ),
      ],
    );
  }
}

class CounterRow extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const CounterRow({
    required this.label,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        Row(
          children: [
            FloatingActionButton(
              mini: true,
              elevation: 0.0,
              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.blue.shade900 
                  : null,
              onPressed: onDecrement,
              child: Icon(
                Icons.remove,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            FloatingActionButton(
              mini: true,
              elevation: 0.0,
              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.blue.shade900 
                  : null,
              onPressed: onIncrement,
              child: Icon(
                Icons.add,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}