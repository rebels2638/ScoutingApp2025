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
import 'drawing_page.dart';
import 'theme/app_theme.dart';  // Add this import
import 'database_helper.dart';
import 'widgets/telemetry_overlay.dart';
import 'dart:math';

class ScoutingPage extends StatefulWidget {
  @override
  _ScoutingPageState createState() => _ScoutingPageState();
}

class _ScoutingPageState extends State<ScoutingPage> {
  int _currentIndex = 0; // for managing navbar

  // state variables for match info
  int matchNumber = 0;
  String matchType = 'Practice';
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

  // Add these state variables at the top of _ScoutingPageState
  int autoAlgaeInNet = 0;
  int autoAlgaeInProcessor = 0;

  // Add to state variables section
  String coralPickupMethod = 'None';

  // Update the type to match the new DrawingLine format
  List<Map<String, dynamic>>? drawingData;

  // Add a key to access the DrawingButton state
  final GlobalKey<_DrawingButtonState> _drawingButtonKey = GlobalKey<_DrawingButtonState>();

  // Global key to access the DataPageState for refreshing records
  final GlobalKey<DataPageState> _dataPageKey = GlobalKey<DataPageState>();

  // Add feederStation variable (if needed for your record)
  String feederStation = '';

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
    // When switching to the DataPage (assumed index 1) refresh its records
    if (index == 1) {
      _dataPageKey.currentState?.loadRecords();
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
        actions: _currentIndex == 0 ? <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Reset Form',
            onPressed: () => _showResetDialog(context),
          ),
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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildScoutingPage(),
          DataPage(key: _dataPageKey),
          SettingsPage(),
          AboutPage(),
        ],
      ),
      bottomNavigationBar: NavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  // Show reset confirmation dialog
  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: AppSpacing.sm),
            Text('Reset Form'),
          ],
        ),
        content: Text('Are you sure you want to reset all fields? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: Text('Reset'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  // Reset form fields
  void _resetForm() {
    setState(() {
      teamNumber = 0;
      matchNumber = 0;
      matchType = 'Qualification';
      // ... other field resets ...
      drawingData = null;
      if (_drawingButtonKey.currentState != null) {
        _drawingButtonKey.currentState!.resetPath();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: AppSpacing.sm),
            Text('Form reset successfully'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }

  Widget _buildScoutingPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMatchInfoSection(),
            _buildAutoSection(),
            _buildTeleopSection(),
            _buildEndgameSection(),
            _buildOtherSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchInfoSection() {
    return SectionCard(
      title: 'Match Information',
      icon: Icons.event,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Match number and type
          Row(
            children: [
              Expanded(
                child: NumberInput(
                  label: 'Match Number',
                  value: matchNumber,
                  onChanged: (value) {
                    setState(() {
                      matchNumber = value;
                      _logStateChange('matchNumber', matchNumber, value);
                    });
                  },
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: DropdownCard(
                  label: 'Match Type',
                  value: matchType,
                  items: const ['Practice', 'Qualification', 'Playoff'],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        matchType = value;
                        _logStateChange('matchType', matchType, value);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          
          // Team selection
          TeamSelector(
            teamNumber: teamNumber,
            isRedAlliance: isRedAlliance,
            onTeamChanged: (value) {
              setState(() {
                teamNumber = value;
                _logStateChange('teamNumber', teamNumber, value);
              });
            },
            onAllianceChanged: (value) {
              setState(() {
                isRedAlliance = value;
                _logStateChange('isRedAlliance', isRedAlliance, value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAutoSection() {
    return SectionCard(
      title: 'Autonomous',
      icon: Icons.auto_awesome,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Taxis and path first for importance
          SwitchCard(
            label: 'Taxis',
            value: taxis,
            onChanged: (value) {
              setState(() {
                taxis = value;
                _logStateChange('taxis', taxis, value);
              });
            },
          ),
          DrawingButton(
            key: _drawingButtonKey,
            isRedAlliance: isRedAlliance,
            initialHasPath: drawingData?.isNotEmpty ?? false,
            onPathSaved: (path) {
              setState(() {
                drawingData = path;
                _logStateChange('drawingData', 'updated', 'new path');
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Auto path saved'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          
          // Scoring section
          SectionHeader(
            title: 'Scoring',
            color: Theme.of(context).colorScheme.primary,
          ),
          CounterRow(
            label: 'Algae Removed',
            value: algaeRemoved,
            onChanged: (value) {
              setState(() {
                algaeRemoved = value;
                _logStateChange('algaeRemoved', algaeRemoved, value);
              });
            },
          ),
          CounterRow(
            label: 'Algae in Net',
            value: autoAlgaeInNet,
            onChanged: (value) {
              setState(() {
                autoAlgaeInNet = value;
                _logStateChange('autoAlgaeInNet', autoAlgaeInNet, value);
              });
            },
          ),
          CounterRow(
            label: 'Algae in Processor',
            value: autoAlgaeInProcessor,
            onChanged: (value) {
              setState(() {
                autoAlgaeInProcessor = value;
                _logStateChange('autoAlgaeInProcessor', autoAlgaeInProcessor, value);
              });
            },
          ),
          
          // Coral section
          SectionHeader(
            title: 'Coral',
            color: Theme.of(context).colorScheme.primary,
          ),
          DropdownCard(
            label: 'Cage Type',
            value: cageType,
            items: const ['Shallow', 'Deep'],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  cageType = value;
                  _logStateChange('cageType', cageType, value);
                });
              }
            },
          ),
          SwitchCard(
            label: 'Coral Preloaded',
            value: coralPreloaded,
            onChanged: (value) {
              setState(() {
                coralPreloaded = value;
                _logStateChange('coralPreloaded', coralPreloaded, value);
              });
            },
          ),
          DropdownCard(
            label: 'Coral Placed',
            value: coralPlaced,
            items: const ['No', 'Yes - Shallow', 'Yes - Deep'],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  coralPlaced = value;
                  _logStateChange('coralPlaced', coralPlaced, value);
                });
              }
            },
          ),
          
          // Ranking point
          SwitchCard(
            label: 'Ranking Point',
            value: rankingPoint,
            onChanged: (value) {
              setState(() {
                rankingPoint = value;
                _logStateChange('rankingPoint', rankingPoint, value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTeleopSection() {
    return SectionCard(
      title: 'Teleop',
      icon: Icons.sports_esports,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Algae scoring section
          SectionHeader(
            title: 'Algae Scoring',
            color: Theme.of(context).colorScheme.primary,
          ),
          CounterRow(
            label: 'Algae in Net',
            value: algaeScoredInNet,
            onChanged: (value) {
              setState(() {
                algaeScoredInNet = value;
                _logStateChange('algaeScoredInNet', algaeScoredInNet, value);
              });
            },
          ),
          CounterRow(
            label: 'Algae Processed',
            value: algaeProcessed,
            onChanged: (value) {
              setState(() {
                algaeProcessed = value;
                _logStateChange('algaeProcessed', algaeProcessed, value);
              });
            },
          ),
          CounterRow(
            label: 'Processed Scored',
            value: processedAlgaeScored,
            onChanged: (value) {
              setState(() {
                processedAlgaeScored = value;
                _logStateChange('processedAlgaeScored', processedAlgaeScored, value);
              });
            },
          ),
          CounterRow(
            label: 'Processor Cycles',
            value: processorCycles,
            onChanged: (value) {
              setState(() {
                processorCycles = value;
                _logStateChange('processorCycles', processorCycles, value);
              });
            },
          ),
          
          // Coral scoring section
          SectionHeader(
            title: 'Coral Scoring',
            color: Theme.of(context).colorScheme.primary,
          ),
          CounterRow(
            label: 'Height 1',
            value: coralOnReefHeight1,
            onChanged: (value) {
              setState(() {
                coralOnReefHeight1 = value;
                _logStateChange('coralOnReefHeight1', coralOnReefHeight1, value);
              });
            },
          ),
          CounterRow(
            label: 'Height 2',
            value: coralOnReefHeight2,
            onChanged: (value) {
              setState(() {
                coralOnReefHeight2 = value;
                _logStateChange('coralOnReefHeight2', coralOnReefHeight2, value);
              });
            },
          ),
          CounterRow(
            label: 'Height 3',
            value: coralOnReefHeight3,
            onChanged: (value) {
              setState(() {
                coralOnReefHeight3 = value;
                _logStateChange('coralOnReefHeight3', coralOnReefHeight3, value);
              });
            },
          ),
          CounterRow(
            label: 'Height 4',
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
                coralOnReefHeight4 = value;
                _logStateChange('coralOnReefHeight4', coralOnReefHeight4, value);
              });
            },
          ),
          
          // Robot capabilities section
          SectionHeader(
            title: 'Capabilities',
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: 8),
          Column(
            children: [
              SwitchCard(
                label: 'Pickup Algae',
                value: canPickupAlgae,
                onChanged: (value) {
                  setState(() {
                    canPickupAlgae = value;
                    _logStateChange('canPickupAlgae', canPickupAlgae, value);
                  });
                },
              ),
              SizedBox(height: 8),
              SwitchCard(
                label: 'Pickup Coral', 
                value: canPickupCoral,
                onChanged: (value) {
                  setState(() {
                    canPickupCoral = value;
                    _logStateChange('canPickupCoral', canPickupCoral, value);
                  });
                },
              ),
              SizedBox(height: 12),
              DropdownCard(
                label: 'Coral Pickup Method',
                value: coralPickupMethod,
                items: const ['None', 'Ground', 'Human Player', 'Both'],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      coralPickupMethod = value;
                      _logStateChange('coralPickupMethod', coralPickupMethod, value);
                    });
                  }
                },
              ),
            ],
          ),
          
          // Points section
          SectionHeader(
            title: 'Points',
            color: Theme.of(context).colorScheme.primary,
          ),
          SwitchCard(
            label: 'Co-Op Point',
            value: coOpPoint,
            onChanged: (value) {
              setState(() {
                coOpPoint = value;
                _logStateChange('coOpPoint', coOpPoint, value);
              });
            },
          ),
          SwitchCard(
            label: 'Coral Ranking Point',
            value: coralRankingPoint,
            onChanged: (value) {
              setState(() {
                coralRankingPoint = value;
                _logStateChange('coralRankingPoint', coralRankingPoint, value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEndgameSection() {
    return SectionCard(
      title: 'Endgame',
      icon: Icons.flag,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barge section
          SectionHeader(
            title: 'Barge',
            color: Theme.of(context).colorScheme.primary,
          ),
          SwitchCard(
            label: 'Returned to Barge',
            value: returnedToBarge,
            onChanged: (value) {
              setState(() {
                returnedToBarge = value;
                _logStateChange('returnedToBarge', returnedToBarge, value);
              });
            },
          ),
          
          // Hanging section
          SectionHeader(
            title: 'Hanging',
            color: Theme.of(context).colorScheme.primary,
          ),
          DropdownCard(
            label: 'Cage Hang',
            value: cageHang,
            items: const ['None', 'Low', 'Mid', 'High'],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  cageHang = value;
                  _logStateChange('cageHang', cageHang, value);
                });
              }
            },
          ),
          SwitchCard(
            label: 'Barge RP',
            value: bargeRankingPoint,
            onChanged: (value) {
              setState(() {
                bargeRankingPoint = value;
                _logStateChange('bargeRankingPoint', bargeRankingPoint, value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOtherSection() {
    return SectionCard(
      title: 'Other',
      icon: Icons.more_horiz,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Robot status
          SectionHeader(
            title: 'Robot Status',
            color: Theme.of(context).colorScheme.primary,
          ),
          SwitchCard(
            label: 'Robot Breakdown',
            value: breakdown,
            onChanged: (value) {
              setState(() {
                breakdown = value;
                _logStateChange('breakdown', breakdown, value);
              });
            },
          ),
          
          // Comments section
          SectionHeader(
            title: 'Notes',
            color: Theme.of(context).colorScheme.primary,
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppShadows.small,
            ),
            padding: EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  maxLines: 3,
                  maxLength: 150,
                  decoration: InputDecoration(
                    hintText: 'Enter any additional notes...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(AppSpacing.sm),
                  ),
                  style: TextStyle(fontSize: 14),
                  onChanged: (value) {
                    setState(() {
                      comments = value;
                      _logStateChange('comments', 'updated', 'new comment');
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (teamNumber == 0 || matchNumber == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Team number and match number are required')),
      );
      return;
    }

    TelemetryService().logAction('save_button_pressed');
    try {
      // Log all values before saving
      TelemetryService().logInfo('save_record_debug', {
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
        'autoAlgaeInNet': autoAlgaeInNet,
        'autoAlgaeInProcessor': autoAlgaeInProcessor,
        'coralPickupMethod': coralPickupMethod,
        'feederStation': feederStation,
        'coralOnReefHeight1': coralOnReefHeight1,
        'coralOnReefHeight2': coralOnReefHeight2,
        'coralOnReefHeight3': coralOnReefHeight3,
        'coralOnReefHeight4': coralOnReefHeight4,
      }.toString());

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
        autoAlgaeInNet: autoAlgaeInNet,
        autoAlgaeInProcessor: autoAlgaeInProcessor,
        coralPickupMethod: coralPickupMethod,
        feederStation: feederStation,
        coralOnReefHeight1: coralOnReefHeight1,
        coralOnReefHeight2: coralOnReefHeight2,
        coralOnReefHeight3: coralOnReefHeight3,
        coralOnReefHeight4: coralOnReefHeight4,
        robotPath: drawingData,
      );

      await DataManager.saveRecord(record);
      
      // Refresh the DataPage after saving
      _dataPageKey.currentState?.loadRecords();
      
      // Switch to Data tab
      setState(() {
        _currentIndex = 1;
      });

      // Show success message
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Record saved successfully'),
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
        autoAlgaeInNet = 0;
        autoAlgaeInProcessor = 0;
        coralPickupMethod = 'None';
        drawingData = null;
        updateTime();
      });

      TelemetryService().logInfo('record_saved_successfully', 'Match $matchNumber');
    } catch (e, stackTrace) {
      TelemetryService().logError('save_record_failed', '${e.toString()}\n${stackTrace.toString()}');
      developer.log('Error saving record: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving record'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _logStateChange(String field, dynamic oldValue, dynamic newValue) {
    TelemetryService().logStateChange(
      field,
      '$oldValue → $newValue',
    );
  }
}

class TeamNumberSelector extends StatelessWidget {
  final int initialValue;
  final ValueChanged<int> onChanged;

  const TeamNumberSelector({
    Key? key,
    required this.initialValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Number', style: TextStyle(fontSize: 16)),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeamNumberSelectorDialog(
                    initialValue: initialValue,
                    onValueChanged: onChanged,
                  ),
                ),
              );
            },
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
                    initialValue.toString(),
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
  final Color color;

  const SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
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
  final ValueChanged<int> onChanged;

  const CounterRow({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.remove, size: 18),
                  onPressed: value > 0 ? () => onChanged(value - 1) : null,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Container(
                  constraints: BoxConstraints(minWidth: 36),
                  alignment: Alignment.center,
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, size: 18),
                  onPressed: () => onChanged(value + 1),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const SectionCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ],
      ),
    );
  }
}

class DrawingButton extends StatefulWidget {
  final bool isRedAlliance;
  final Function(List<Map<String, dynamic>>) onPathSaved;
  final bool initialHasPath;

  const DrawingButton({
    Key? key,
    required this.isRedAlliance,
    required this.onPathSaved,
    this.initialHasPath = false,
  }) : super(key: key);

  @override
  State<DrawingButton> createState() => _DrawingButtonState();
}

class _DrawingButtonState extends State<DrawingButton> {
  late bool hasPath;

  @override
  void initState() {
    super.initState();
    hasPath = widget.initialHasPath;
  }

  void resetPath() {
    setState(() {
      hasPath = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () async {
              final drawingData = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DrawingPage(
                    isRedAlliance: widget.isRedAlliance,
                    readOnly: false,
                    initialDrawing: null,
                  ),
                ),
              );
              
              if (drawingData != null) {
                widget.onPathSaved(drawingData);
                setState(() {
                  hasPath = true;
                });
              }
            },
            icon: Icon(hasPath ? Icons.edit : Icons.draw),
            label: Text(hasPath ? 'Edit Auto Path' : 'Draw Auto Path'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: hasPath ? 
                Theme.of(context).colorScheme.primaryContainer :
                null,
            ),
          ),
          if (hasPath)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Auto path saved ✓',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
        ],
      ),
    );
  }
}

class SwitchCard extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SwitchCard({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class NumberInput extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const NumberInput({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.small,
      ),
      padding: EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          TextField(
            controller: TextEditingController(text: value.toString()),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              border: OutlineInputBorder(),
            ),
            onChanged: (text) {
              final newValue = int.tryParse(text);
              if (newValue != null) {
                onChanged(newValue);
              }
            },
          ),
        ],
      ),
    );
  }
}

class DropdownCard extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const DropdownCard({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.small,
      ),
      padding: EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: SizedBox(),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class TeamSelector extends StatelessWidget {
  final int teamNumber;
  final bool isRedAlliance;
  final ValueChanged<int> onTeamChanged;
  final ValueChanged<bool> onAllianceChanged;

  const TeamSelector({
    Key? key,
    required this.teamNumber,
    required this.isRedAlliance,
    required this.onTeamChanged,
    required this.onAllianceChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.small,
      ),
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Selection',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TeamNumberSelector(
                  initialValue: teamNumber,
                  onChanged: (value) {
                    onTeamChanged(value);
                  },
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Row(
                  children: [
                    _AllianceButton(
                      label: 'Red',
                      isSelected: isRedAlliance,
                      color: AppColors.redAlliance,
                      onTap: () => onAllianceChanged(true),
                    ),
                    _AllianceButton(
                      label: 'Blue',
                      isSelected: !isRedAlliance,
                      color: AppColors.blueAlliance,
                      onTap: () => onAllianceChanged(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AllianceButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _AllianceButton({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class TeamNumberSelectorDialog extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onValueChanged;

  const TeamNumberSelectorDialog({
    Key? key,
    required this.initialValue,
    required this.onValueChanged,
  }) : super(key: key);

  @override
  _TeamNumberSelectorDialogState createState() => _TeamNumberSelectorDialogState();
}

class _TeamNumberSelectorDialogState extends State<TeamNumberSelectorDialog> {
  late List<int> selectedDigits;

  @override
  void initState() {
    super.initState();
    selectedDigits = _numberToDigits(widget.initialValue);
  }

  List<int> _numberToDigits(int number) {
    String numStr = number.toString().padLeft(5, '0');
    return numStr.split('').map(int.parse).toList();
  }

  void _updateTeamNumber() {
    int number = selectedDigits.fold(0, (prev, digit) => prev * 10 + digit);
    widget.onValueChanged(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Team Number')),
      body: Column(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (columnIndex) {
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
    );
  }
}