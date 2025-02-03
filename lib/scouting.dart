// notes for telemetry: team number log updates too often. coral ground pickup logs too much (test this). algae ground pickup logs too much, just like coral.
// comments updates after every interaction. too much

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // date time format
import 'data.dart';
import 'dart:developer' as developer;
import 'settings.dart';
import 'about.dart';
import 'main.dart';  // for ThemeProvider
import 'widgets/navbar.dart';
import 'widgets/topbar.dart';
import 'services/telemetry_service.dart';
import 'dart:async';

class ScoutingPage extends StatefulWidget {
  @override
  _ScoutingPageState createState() => _ScoutingPageState();
}

class _ScoutingPageState extends State<ScoutingPage> {
  int _currentIndex = 0; // for managing navbar

  // state variables for match info
  int matchNumber = 0;
  String matchType = 'Unset';
  String currentTime = '';

  // state vars for team info
  int teamNumber = 0;
  bool isRedAlliance = true;

  // state vars for autonomous
  String cageType = 'Shallow';
  bool coralPreloaded = false;
  bool taxis = false;
  int algaeRemoved = 0;
  String coralPlaced = 'No';
  bool rankingPoint = false;

  // state vars for tele-op
  int algaeScoredInNet = 0;
  int coralOnReefHeight1 = 0;
  int coralOnReefHeight2 = 0;
  int coralOnReefHeight3 = 0;
  int coralOnReefHeight4 = 0;
  bool coralRankingPoint = false;
  int algaeProcessed = 0;
  int processedAlgaeScored = 0;
  bool coOpPoint = false;

  // state vars for endgame
  bool returnedToBarge = false;
  String cageHang = 'None';
  bool bargeRankingPoint = false;

  // state vars for other section
  bool breakdown = false;
  String comments = '';

  // state vars for pickup capabilities
  bool canPickupAlgae = false;
  bool canPickupCoral = false;

  // state var for processor cycles
  int processorCycles = 0;

  // dev mode state
  bool _isVisible = false;
  bool _isDevMode = false;

  StreamSubscription? _devModeSubscription;

  @override
  void initState() {
    super.initState();
    updateTime();
    _loadDevMode();
    TelemetryService().logInfo('ScoutingPage initialized');
    
    // listen to dev mode changes
    _devModeSubscription = TelemetryService().devModeStream.listen((enabled) {
      if (mounted && enabled != _isDevMode) {
        setState(() {
          _isDevMode = enabled;
        });
      }
    });
  }

  @override
  void dispose() {
    _devModeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDevMode() async {
    final isEnabled = await TelemetryService.isDevModeEnabled();
    if (mounted && isEnabled != _isDevMode) {
      setState(() {
        _isDevMode = isEnabled;
      });
    }
  }

  void updateTime() {
    setState(() {
      currentTime = DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now());
    });
  }

  void _onItemTapped(int index) {
    TelemetryService().logAction('navigation_changed', 'to index $index');
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
        // match info section
        SectionHeader(title: 'Match Information', icon: Icons.view_module),
        InfoRow(label: 'Time', value: currentTime),
        CounterRow(
          label: 'Number',
          value: matchNumber,
          onIncrement: () {
            final oldValue = matchNumber;
            setState(() {
              matchNumber++;
            });
            _logStateChange('matchNumber', oldValue, matchNumber);
            //TelemetryService().logAction('counter_increment', 'matchNumber');
          },
          onDecrement: () {
            if (matchNumber > 0) {
              final oldValue = matchNumber;
              setState(() {
                matchNumber--;
              });
              _logStateChange('matchNumber', oldValue, matchNumber);
              //TelemetryService().logAction('counter_decrement', 'matchNumber');
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
              final oldValue = matchType;
              setState(() {
                matchType = value!;
              });
              _logStateChange('matchType', oldValue, value);
              //TelemetryService().logAction('dropdown_changed', 'matchType: $oldValue -> $value');
            },
          ),
        ),
        SizedBox(height: 20),
        SectionHeader(title: 'Team Information', icon: Icons.people),
        TeamNumberSelector(
          initialValue: teamNumber,
          onChanged: (value) {
            TelemetryService().logAction('team_number_changed', 'to $value');
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
                    TelemetryService().logAction('alliance_selection_changed', 'from ${isRedAlliance ? "red" : "blue"} to ${index == 0 ? "red" : "blue"}');
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
        // auto section
        SectionHeader(title: 'Autonomous', icon: Icons.settings),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ToggleRow(
            label: 'Cage Type',
            options: ['SHALLOW', 'DEEP'],
            selectedIndex: cageType == 'Shallow' ? 0 : 1,
            onSelected: (index) {
              TelemetryService().logAction('toggle_changed', 'cageType');
              final oldValue = cageType;
              setState(() {
                cageType = index == 0 ? 'Shallow' : 'Deep';
              });
              _logStateChange('cageType', oldValue, cageType);
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
              final oldValue = coralPreloaded;
              setState(() {
                coralPreloaded = index == 0;
              });
              _logStateChange('coralPreloaded', oldValue, coralPreloaded);
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
              final oldValue = taxis;
              setState(() {
                taxis = index == 0;
              });
              _logStateChange('taxis', oldValue, taxis);
            },
          ),
        ),
        CounterRow(
          label: 'Num. of Algae Removed',
          value: algaeRemoved,
          onIncrement: () {
            final oldValue = algaeRemoved;
            setState(() {
              algaeRemoved++;
            });
            _logStateChange('algaeRemoved', oldValue, algaeRemoved);
            //TelemetryService().logAction('counter_increment', 'algaeRemoved');
          },
          onDecrement: () {
            if (algaeRemoved > 0) {
              final oldValue = algaeRemoved;
              setState(() {
                algaeRemoved--;
              });
              _logStateChange('algaeRemoved', oldValue, algaeRemoved);
              //TelemetryService().logAction('counter_decrement', 'algaeRemoved');
            }
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Coral Placed?', style: TextStyle(fontSize: 16)),
            DropdownButton<String>(
              value: coralPlaced,
              items: ['No', 'Yes - Shallow', 'Yes - Deep']
                  .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                  .toList(),
              onChanged: (value) {
                final oldValue = coralPlaced;
                setState(() {
                  coralPlaced = value!;
                });
                _logStateChange('coralPlaced', oldValue, value);
                //TelemetryService().logAction('dropdown_changed', 'coralPlaced: $oldValue -> $value');
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
              final oldValue = rankingPoint;
              setState(() {
                rankingPoint = index == 0;
              });
              _logStateChange('rankingPoint', oldValue, rankingPoint);
            },
          ),
        ),
        Divider(),
        // tele-op section
        SectionHeader(title: 'Tele-op', icon: Icons.directions_run),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: CounterRow(
            label: 'Algae Scored in Net',
            value: algaeScoredInNet,
            onIncrement: () {
              TelemetryService().logAction('counter_increment', 'algaeScoredInNet');
              final oldValue = algaeScoredInNet;
              setState(() => algaeScoredInNet++);
              _logStateChange('algaeScoredInNet', oldValue, algaeScoredInNet);
            },
            onDecrement: () {
              if (algaeScoredInNet > 0) {
                TelemetryService().logAction('counter_decrement', 'algaeScoredInNet');
                final oldValue = algaeScoredInNet;
                setState(() => algaeScoredInNet--);
                _logStateChange('algaeScoredInNet', oldValue, algaeScoredInNet);
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: CounterRow(
            label: 'Coral on Reef, Height 1',
            value: coralOnReefHeight1,
            onIncrement: () {
              final oldValue = coralOnReefHeight1;
              setState(() => coralOnReefHeight1++);
              _logStateChange('coralOnReefHeight1', oldValue, coralOnReefHeight1);
            },
            onDecrement: () {
              if (coralOnReefHeight1 > 0) {
                final oldValue = coralOnReefHeight1;
                setState(() => coralOnReefHeight1--);
                _logStateChange('coralOnReefHeight1', oldValue, coralOnReefHeight1);
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: CounterRow(
            label: 'Coral on Reef, Height 2',
            value: coralOnReefHeight2,
            onIncrement: () {
              final oldValue = coralOnReefHeight2;
              setState(() => coralOnReefHeight2++);
              _logStateChange('coralOnReefHeight2', oldValue, coralOnReefHeight2);
              //TelemetryService().logAction('counter_increment', 'coralOnReefHeight2');
            },
            onDecrement: () {
              if (coralOnReefHeight2 > 0) {
                final oldValue = coralOnReefHeight2;
                setState(() => coralOnReefHeight2--);
                _logStateChange('coralOnReefHeight2', oldValue, coralOnReefHeight2);
                //TelemetryService().logAction('counter_decrement', 'coralOnReefHeight2');
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: CounterRow(
            label: 'Coral on Reef, Height 3',
            value: coralOnReefHeight3,
            onIncrement: () {
              final oldValue = coralOnReefHeight3;
              setState(() => coralOnReefHeight3++);
              _logStateChange('coralOnReefHeight3', oldValue, coralOnReefHeight3);
              //TelemetryService().logAction('counter_increment', 'coralOnReefHeight3');
            },
            onDecrement: () {
              if (coralOnReefHeight3 > 0) {
                final oldValue = coralOnReefHeight3;
                setState(() => coralOnReefHeight3--);
                _logStateChange('coralOnReefHeight3', oldValue, coralOnReefHeight3);
                //TelemetryService().logAction('counter_decrement', 'coralOnReefHeight3');
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: CounterRow(
            label: 'Coral on Reef, Height 4',
            value: coralOnReefHeight4,
            onIncrement: () {
              final oldValue = coralOnReefHeight4;
              setState(() => coralOnReefHeight4++);
              _logStateChange('coralOnReefHeight4', oldValue, coralOnReefHeight4);
              //TelemetryService().logAction('counter_increment', 'coralOnReefHeight4');
            },
            onDecrement: () {
              if (coralOnReefHeight4 > 0) {
                final oldValue = coralOnReefHeight4;
                setState(() => coralOnReefHeight4--);
                _logStateChange('coralOnReefHeight4', oldValue, coralOnReefHeight4);
                //TelemetryService().logAction('counter_decrement', 'coralOnReefHeight4');
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ToggleRow(
            label: 'Coral Ranking Point?',
            options: ['YES', 'NO'],
            selectedIndex: coralRankingPoint ? 0 : 1,
            onSelected: (index) {
              final oldValue = coralRankingPoint;
              setState(() {
                coralRankingPoint = index == 0;
              });
              _logStateChange('coralRankingPoint', oldValue, coralRankingPoint);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ToggleRow(
            label: 'Coral ground pickup?',
            options: ['YES', 'NO'],
            selectedIndex: canPickupCoral ? 0 : 1,
            onSelected: (index) {
              final oldValue = canPickupCoral;
              setState(() {
                canPickupCoral = index == 0;
              });
              _logStateChange('canPickupCoral', oldValue, canPickupCoral);
              //TelemetryService().logAction('toggle_changed', 'canPickupCoral');
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
              final oldValue = canPickupAlgae;
              setState(() {
                canPickupAlgae = index == 0;
              });
              _logStateChange('canPickupAlgae', oldValue, canPickupAlgae);
              //TelemetryService().logAction('toggle_changed', 'canPickupAlgae');
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: CounterRow(
            label: 'Algae Processed',
            value: algaeProcessed,
            onIncrement: () {
              final oldValue = algaeProcessed;
              setState(() => algaeProcessed++);
              _logStateChange('algaeProcessed', oldValue, algaeProcessed);
              //TelemetryService().logAction('counter_increment', 'algaeProcessed');
            },
            onDecrement: () {
              if (algaeProcessed > 0) {
                final oldValue = algaeProcessed;
                setState(() => algaeProcessed--);
                _logStateChange('algaeProcessed', oldValue, algaeProcessed);
                //TelemetryService().logAction('counter_decrement', 'algaeProcessed');
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: CounterRow(
            label: 'Processed Algae Scored',
            value: processedAlgaeScored,
            onIncrement: () {
              final oldValue = processedAlgaeScored;
              setState(() => processedAlgaeScored++);
              _logStateChange('processedAlgaeScored', oldValue, processedAlgaeScored);
              //TelemetryService().logAction('counter_increment', 'processedAlgaeScored');
            },
            onDecrement: () {
              if (processedAlgaeScored > 0) {
                final oldValue = processedAlgaeScored;
                setState(() => processedAlgaeScored--);
                _logStateChange('processedAlgaeScored', oldValue, processedAlgaeScored);
                //TelemetryService().logAction('counter_decrement', 'processedAlgaeScored');
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ToggleRow(
            label: 'Co-op Point?',
            options: ['YES', 'NO'],
            selectedIndex: coOpPoint ? 0 : 1,
            onSelected: (index) {
              final oldValue = coOpPoint;
              setState(() {
                coOpPoint = index == 0;
              });
              _logStateChange('coOpPoint', oldValue, coOpPoint);
              //TelemetryService().logAction('toggle_changed', 'coOpPoint');
            },
          ),
        ),
        Divider(),
        // endgame section
        SectionHeader(title: 'Endgame', icon: Icons.flag),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ToggleRow(
            label: 'Returned to Barge?',
            options: ['YES', 'NO'],
            selectedIndex: returnedToBarge ? 0 : 1,
            onSelected: (index) {
              final oldValue = returnedToBarge;
              setState(() {
                returnedToBarge = index == 0;
              });
              _logStateChange('returnedToBarge', oldValue, returnedToBarge);
              //TelemetryService().logAction('toggle_changed', 'returnedToBarge');
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
                final oldValue = cageHang;
                setState(() {
                  cageHang = value!;
                });
                _logStateChange('cageHang', oldValue, value);
                //TelemetryService().logAction('dropdown_changed', 'cageHang: $oldValue -> $value');
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
              final oldValue = bargeRankingPoint;
              setState(() {
                bargeRankingPoint = index == 0;
              });
              _logStateChange('bargeRankingPoint', oldValue, bargeRankingPoint);
              //TelemetryService().logAction('toggle_changed', 'bargeRankingPoint');
            },
          ),
        ),
        Divider(),
        // other section
        SectionHeader(title: 'Other', icon: Icons.miscellaneous_services),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ToggleRow(
            label: 'Breakdown?',
            options: ['YES', 'NO'],
            selectedIndex: breakdown ? 0 : 1,
            onSelected: (index) {
              final oldValue = breakdown;
              setState(() {
                breakdown = index == 0;
              });
              _logStateChange('breakdown', oldValue, breakdown);
              //TelemetryService().logAction('toggle_changed', 'breakdown');
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
              final oldValue = comments;
              setState(() {
                comments = value;
              });
              _logStateChange('comments', oldValue, value);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _saveRecord() async {
    TelemetryService().logAction('save_button_pressed');
    try {
      // Log all boolean values before creating record
      final debugValues = {
        'coralPreloaded': coralPreloaded,
        'taxis': taxis,
        'rankingPoint': rankingPoint,
        'canPickupCoral': canPickupCoral,
        'canPickupAlgae': canPickupAlgae,
        'coralRankingPoint': coralRankingPoint,
        'coOpPoint': coOpPoint,
        'returnedToBarge': returnedToBarge,
        'bargeRankingPoint': bargeRankingPoint,
        'breakdown': breakdown,
      };
      TelemetryService().logInfo('save_record_debug', debugValues.toString());

      // Check for null values
      for (var entry in debugValues.entries) {
        if (entry.value == null) {
          throw Exception('Null boolean value found: ${entry.key}');
        }
      }

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
        canPickupCoral: canPickupCoral,
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
      
      // show success message
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Match data saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // reset form
      setState(() {
        matchNumber = matchNumber + 1; // increment match number
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

      TelemetryService().logInfo('record_saved_successfully', 'Match $matchNumber');
    } catch (e, stackTrace) {
      TelemetryService().logError('save_record_failed', '${e.toString()}\n${stackTrace.toString()}');
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
          if (_isDevMode)
            IconButton(
              icon: Icon(Icons.analytics),
              onPressed: () {
                final myAppState = context.findAncestorStateOfType<MyAppState>();
                if (myAppState != null) {
                  myAppState.toggleTelemetry(!myAppState.telemetryVisible);
                }
              },
            ),
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

  void _logStateChange(String field, dynamic oldValue, dynamic newValue) {
    TelemetryService().logStateChange(
      field,
      '$oldValue → $newValue',
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