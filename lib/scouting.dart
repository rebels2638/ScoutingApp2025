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
import 'team_number_selector.dart';
import 'api.dart';
import 'package:flutter/services.dart';  // Add this import
import 'package:shared_preferences/shared_preferences.dart';
import 'bluetooth_page.dart';

class ScoutingPage extends StatefulWidget {
  @override
  _ScoutingPageState createState() => _ScoutingPageState();
}

class _ScoutingPageState extends State<ScoutingPage> {
  int _currentIndex = 0; // for managing navbar

  // state variables for match info
  int matchNumber = 0;
  String matchType = 'Qualification';
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

  // Add a focus node
  final FocusNode _focusNode = FocusNode();

  // Add this at the top with other state variables
  final FocusNode _matchNumberFocusNode = FocusNode();

  // Add this variable
  bool _bluetoothEnabled = false;

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

    // Add this to handle focus when the page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    });

    // Add this method
    _loadBluetoothSetting();
  }

  @override
  void dispose() {
    _devModeSubscription?.cancel();
    _focusNode.dispose();
    _matchNumberFocusNode.dispose();
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

  Future<void> _loadBluetoothSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bluetoothEnabled = prefs.getBool('bluetooth_enabled') ?? false;
    });
  }

  void updateTime() {
    setState(() {
      currentTime = DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now());
    });
  }

  void _onItemTapped(int index) {
    TelemetryService().logAction('navigation_changed', 'to index $index');
    
    // Calculate the actual maximum index
    final maxIndex = _bluetoothEnabled ? 5 : 5;  // Max is always 5
    
    // Ensure the index is valid
    if (index > maxIndex) {
      index = maxIndex;
    }
    
    setState(() {
      _currentIndex = index;
    });
    
    if (index == 1) {
      _dataPageKey.currentState?.loadRecords();
    }

    // Ensure keyboard is dismissed when switching tabs
    FocusScope.of(context).unfocus();
  }

  Widget _getPage(int index) {
    if (_bluetoothEnabled) {
      // When Bluetooth is enabled, use normal order
      switch (index) {
        case 0:
          return _buildScoutingPage();
        case 1:
          return DataPage(key: _dataPageKey);
        case 2:
          return ApiPage(key: ApiPageState.globalKey);
        case 3:
          return BluetoothPage();
        case 4:
          return SettingsPage();
        case 5:
          return AboutPage();
        default:
          return _buildScoutingPage();
      }
    } else {
      // When Bluetooth is disabled, skip index 3
      switch (index) {
        case 0:
          return _buildScoutingPage();
        case 1:
          return DataPage(key: _dataPageKey);
        case 2:
          return ApiPage(key: ApiPageState.globalKey);
        case 4:
          return SettingsPage();
        case 5:
          return AboutPage();
        default:
          return _buildScoutingPage();
      }
    }
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
          // Match number and type in a Row with proper alignment
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,  // Align to top
            children: [
              // Match Number input - make it same width as dropdown
              Expanded(
                child: NumberInput(
                  label: 'Match Number',
                  value: matchNumber,
                  onChanged: (value) {
                    setState(() {
                      final oldValue = matchNumber;
                      matchNumber = value;
                      _logStateChange('matchNumber', oldValue, value);
                    });
                  },
                  autofocus: false,
                  focusNode: _matchNumberFocusNode,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              // Match Type dropdown - make it same width as number input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: Theme.of(context).brightness == Brightness.dark 
                        ? [] 
                        : AppShadows.small,
                  ),
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Match Type',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      DropdownCard(
                        label: 'Match Type',
                        value: matchType,
                        items: const ['Practice', 'Qualification', 'Playoff'],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              final oldValue = matchType;
                              matchType = value;
                              _logStateChange('matchType', oldValue, value);
                            });
                          }
                        },
                      ),
                    ],
                  ),
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
                final oldValue = teamNumber;
                teamNumber = value;
                _logStateChange('teamNumber', oldValue, value);
              });
            },
            onAllianceChanged: (value) {
              setState(() {
                final oldValue = isRedAlliance;
                isRedAlliance = value;
                _logStateChange('isRedAlliance', oldValue, value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAutoSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
                final oldValue = taxis;
                taxis = value;
                _logStateChange('taxis', oldValue, value);
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
          
          // Update the SCORING header
          Container(
            margin: EdgeInsets.only(top: AppSpacing.md),
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark 
                      ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                      : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Text(
              'SCORING',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          
          // Scoring section
          CounterRow(
            label: 'Algae Removed',
            value: algaeRemoved,
            onChanged: (value) {
              setState(() {
                final oldValue = algaeRemoved;
                algaeRemoved = value;
                _logStateChange('algaeRemoved', oldValue, value);
              });
            },
          ),
          CounterRow(
            label: 'Algae in Net',
            value: autoAlgaeInNet,
            onChanged: (value) {
              setState(() {
                final oldValue = autoAlgaeInNet;
                autoAlgaeInNet = value;
                _logStateChange('autoAlgaeInNet', oldValue, value);
              });
            },
          ),
          CounterRow(
            label: 'Algae in Processor',
            value: autoAlgaeInProcessor,
            onChanged: (value) {
              setState(() {
                final oldValue = autoAlgaeInProcessor;
                autoAlgaeInProcessor = value;
                _logStateChange('autoAlgaeInProcessor', oldValue, value);
              });
            },
          ),
          
          // Coral section
          SectionHeader(
            title: 'Coral',
            color: Theme.of(context).colorScheme.primary,
          ),
          FormRow(
            label: 'Cage Type',
            input: DropdownCard(
              label: 'Cage Type',
              value: cageType,
              items: const [
                'Shallow',
                'Deep',
              ],
              onChanged: (value) {
                setState(() {
                  final oldValue = cageType;
                  cageType = value!;
                  _logStateChange('cageType', oldValue, value);
                });
              },
            ),
          ),
          SwitchCard(
            label: 'Coral Preloaded',
            value: coralPreloaded,
            onChanged: (value) {
              setState(() {
                final oldValue = coralPreloaded;
                coralPreloaded = value;
                _logStateChange('coralPreloaded', oldValue, value);
              });
            },
          ),
          FormRow(
            label: 'Coral Placed',
            input: DropdownCard(
              label: 'Coral Placed',
              value: coralPlaced,
              items: const [
                'No',
                'Yes - Shallow',
                'Yes - Deep',
              ],
              onChanged: (value) {
                setState(() {
                  final oldValue = coralPlaced;
                  coralPlaced = value!;
                  _logStateChange('coralPlaced', oldValue, value);
                });
              },
            ),
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
                final oldValue = algaeScoredInNet;
                algaeScoredInNet = value;
                _logStateChange('algaeScoredInNet', oldValue, value);
              });
            },
          ),
          CounterRow(
            label: 'Algae Processed',
            value: algaeProcessed,
            onChanged: (value) {
              setState(() {
                final oldValue = algaeProcessed;
                algaeProcessed = value;
                _logStateChange('algaeProcessed', oldValue, value);
              });
            },
          ),
          CounterRow(
            label: 'Processed Scored',
            value: processedAlgaeScored,
            onChanged: (value) {
              setState(() {
                final oldValue = processedAlgaeScored;
                processedAlgaeScored = value;
                _logStateChange('processedAlgaeScored', oldValue, value);
              });
            },
          ),
          CounterRow(
            label: 'Processor Cycles',
            value: processorCycles,
            onChanged: (value) {
              setState(() {
                final oldValue = processorCycles;
                processorCycles = value;
                _logStateChange('processorCycles', oldValue, value);
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
                final oldValue = coralOnReefHeight1;
                coralOnReefHeight1 = value;
                _logStateChange('coralOnReefHeight1', oldValue, value);
              });
            },
          ),
          CounterRow(
            label: 'Height 2',
            value: coralOnReefHeight2,
            onChanged: (value) {
              setState(() {
                final oldValue = coralOnReefHeight2;
                coralOnReefHeight2 = value;
                _logStateChange('coralOnReefHeight2', oldValue, value);
              });
            },
          ),
          CounterRow(
            label: 'Height 3',
            value: coralOnReefHeight3,
            onChanged: (value) {
              setState(() {
                final oldValue = coralOnReefHeight3;
                coralOnReefHeight3 = value;
                _logStateChange('coralOnReefHeight3', oldValue, value);
              });
            },
          ),
          CounterRow(
            label: 'Height 4',
            value: coralOnReefHeight4,
            onChanged: (value) {
              setState(() {
                final oldValue = coralOnReefHeight4;
                coralOnReefHeight4 = value;
                _logStateChange('coralOnReefHeight4', oldValue, value);
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ToggleRow(
              label: 'Coral Ranking Point?',
              options: ['YES', 'NO'],
              selectedIndex: coralRankingPoint ? 0 : 1,
              onSelected: (index) {
                setState(() {
                  final oldValue = coralRankingPoint;
                  coralRankingPoint = (index == 0);
                  _logStateChange('coralRankingPoint', oldValue, coralRankingPoint);
                });
              },
            ),
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
                    final oldValue = canPickupAlgae;
                    canPickupAlgae = value;
                    _logStateChange('canPickupAlgae', oldValue, value);
                  });
                },
              ),
              SizedBox(height: 8),
              SwitchCard(
                label: 'Pickup Coral', 
                value: canPickupCoral,
                onChanged: (value) {
                  setState(() {
                    final oldValue = canPickupCoral;
                    canPickupCoral = value;
                    _logStateChange('canPickupCoral', oldValue, value);
                  });
                },
              ),
              SizedBox(height: 12),
              FormRow(
                label: 'Coral Pickup',
                input: DropdownCard(
                  label: 'Method',
                  value: coralPickupMethod,
                  items: const [
                    'None',
                    'Ground',
                    'Human',
                    'Both',
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        final oldValue = coralPickupMethod;
                        coralPickupMethod = value;
                        // If they can pickup from either location, set canPickupCoral to true
                        if (value != 'None') {
                          canPickupCoral = true;
                        }
                        _logStateChange('coralPickupMethod', oldValue, value);
                      });
                    }
                  },
                ),
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
                final oldValue = coOpPoint;
                coOpPoint = value;
                _logStateChange('coOpPoint', oldValue, value);
              });
            },
          ),
          SwitchCard(
            label: 'Coral Ranking Point',
            value: coralRankingPoint,
            onChanged: (value) {
              setState(() {
                final oldValue = coralRankingPoint;
                coralRankingPoint = value;
                _logStateChange('coralRankingPoint', oldValue, value);
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
                final oldValue = returnedToBarge;
                returnedToBarge = value;
                _logStateChange('returnedToBarge', oldValue, value);
              });
            },
          ),
          
          // Hanging section
          SectionHeader(
            title: 'Hanging',
            color: Theme.of(context).colorScheme.primary,
          ),
          FormRow(
            label: 'Cage Hang',
            input: DropdownCard(
              label: '',
              value: cageHang,
              items: const [
                'None',
                'Shallow',
                'Deep',
              ],
              onChanged: (value) {
                setState(() {
                  final oldValue = cageHang;
                  cageHang = value!;
                  _logStateChange('cageHang', oldValue, value);
                });
              },
            ),
          ),
          SwitchCard(
            label: 'Barge RP',
            value: bargeRankingPoint,
            onChanged: (value) {
              setState(() {
                final oldValue = bargeRankingPoint;
                bargeRankingPoint = value;
                _logStateChange('bargeRankingPoint', oldValue, value);
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
                final oldValue = breakdown;
                breakdown = value;
                _logStateChange('breakdown', oldValue, value);
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
                      final oldValue = comments;
                      comments = value;
                      _logStateChange('comments', oldValue, 'new comment');
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
      // Get the confirmation setting
      final prefs = await SharedPreferences.getInstance();
      final confirmBeforeSaving = prefs.getBool('confirm_before_saving') ?? true;

      // If confirmation is enabled, show dialog
      if (confirmBeforeSaving) {
        final shouldSave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Save Record'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to save this record?'),
                SizedBox(height: 8),
                Text('Team $teamNumber - Match $matchNumber'),
                Text('${matchType} Match'),
                Text(isRedAlliance ? 'Red Alliance' : 'Blue Alliance'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Save'),
              ),
            ],
          ),
        );

        if (shouldSave != true) {
          return;
        }
      }

      // Log all values before saving
      TelemetryService().logInfo('save_record_debug', {
        'coralPreloaded': coralPreloaded,
        'taxis': taxis,
        'rankingPoint': coralRankingPoint,
        'canPickupCoral': canPickupCoral,
        'canPickupAlgae': canPickupAlgae,
        'coralRankingPoint': coralRankingPoint,
        'coOpPoint': coOpPoint,
        'returnedToBarge': returnedToBarge,
        'bargeRankingPoint': bargeRankingPoint,
        'breakdown': breakdown,
        'autoAlgaeInNet': autoAlgaeInNet,
        'autoAlgaeInProcessor': autoAlgaeInProcessor,
        'coralPickupMethod': canPickupCoral ? coralPickupMethod : 'None',
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
        rankingPoint: coralRankingPoint,
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
        coralPickupMethod: canPickupCoral ? coralPickupMethod : 'None',
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

      // Explicitly unfocus before showing snackbar
      FocusScope.of(context).unfocus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Record saved successfully')),
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
        coralRankingPoint = false;
        coOpPoint = false;
        returnedToBarge = false;
        bargeRankingPoint = false;
        breakdown = false;
        autoAlgaeInNet = 0;
        autoAlgaeInProcessor = 0;
        canPickupCoral = false;
        coralPickupMethod = 'None';
        drawingData = null;
        if (_drawingButtonKey.currentState != null) {
          _drawingButtonKey.currentState!.resetPath();
        }
        updateTime();
      });

      TelemetryService().logInfo('record_saved_successfully', 'Match $matchNumber');

      _triggerHaptic();  // Add haptic feedback when saving
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

  void _triggerHaptic() async {
    final prefs = await SharedPreferences.getInstance();
    final vibrateEnabled = prefs.getBool('vibrate_on_action') ?? true;
    
    if (vibrateEnabled) {
      switch (Theme.of(context).platform) {
        case TargetPlatform.iOS:
          await HapticFeedback.mediumImpact();
          break;
        case TargetPlatform.android:
          await HapticFeedback.vibrate();
          break;
        default:
          break;
      }
    }
  }

  void _logStateChange(String field, dynamic oldValue, dynamic newValue) {
    TelemetryService().logStateChange(
      field,
      '$oldValue → $newValue',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle(_currentIndex)),
        actions: _currentIndex == 0 ? [
          // Only show these buttons on the scouting page
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Record',
            onPressed: _saveRecord,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Form',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Form?'),
                  content: const Text('This will clear all fields. Are you sure?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
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
                          coralRankingPoint = false;
                          coOpPoint = false;
                          returnedToBarge = false;
                          bargeRankingPoint = false;
                          breakdown = false;
                          autoAlgaeInNet = 0;
                          autoAlgaeInProcessor = 0;
                          canPickupCoral = false;
                          coralPickupMethod = 'None';
                          drawingData = null;
                          if (_drawingButtonKey.currentState != null) {
                            _drawingButtonKey.currentState!.resetPath();
                          }
                          updateTime();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Form reset')),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
            },
          ),
          // Only show telemetry button if dev mode is enabled
          if (_isDevMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              tooltip: 'Toggle Telemetry',
              onPressed: () {
                final myAppState = context.findAncestorStateOfType<MyAppState>();
                if (myAppState != null) {
                  myAppState.toggleTelemetry(!myAppState.telemetryVisible);
                }
              },
            ),
        ] : null,
      ),
      body: _getPage(_currentIndex),
      bottomNavigationBar: NavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        showBluetooth: _bluetoothEnabled,
      ),
    );
  }

  String _getPageTitle(int index) {
    if (_bluetoothEnabled) {
      // When Bluetooth is enabled, use normal order
      switch (index) {
        case 0:
          return 'Scouting';
        case 1:
          return 'Data';
        case 2:
          return 'API';
        case 3:
          return 'Bluetooth';
        case 4:
          return 'Settings';
        case 5:
          return 'About';
        default:
          return 'Scouting';
      }
    } else {
      // When Bluetooth is disabled, skip index 3
      switch (index) {
        case 0:
          return 'Scouting';
        case 1:
          return 'Data';
        case 2:
          return 'API';
        case 4:
          return 'Settings';
        case 5:
          return 'About';
        default:
          return 'Scouting';
      }
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ElevatedButton(
      onPressed: () async {
        await showTeamNumberSelector(
          context,
          initialValue,
          (value) {
            onChanged(value);
          },
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark 
            ? Theme.of(context).colorScheme.surface.withOpacity(0.8)
            : Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        side: BorderSide(
          color: isDark
              ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        elevation: isDark ? 0 : 1,
      ),
      child: Text(
        'Team ${initialValue == 0 ? "Number" : initialValue.toString()}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const SectionHeader({
    Key? key,
    required this.title,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.only(top: AppSpacing.md),
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark 
                ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
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
    Key? key,
    required this.label,
    required this.options,
    required this.onSelected,
    required this.selectedIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ToggleButtons(
            borderRadius: BorderRadius.circular(8),
            selectedBorderColor: Colors.transparent,
            borderWidth: 1,
            fillColor: selectedIndex == 0
                ? (isDark ? Colors.blue.shade900 : Colors.green.shade300)
                : (isDark ? Colors.red.shade900 : Colors.red.shade300),
            color: Theme.of(context).textTheme.bodyLarge?.color,
            selectedColor: Theme.of(context).textTheme.bodyLarge?.color,
            constraints: const BoxConstraints(minWidth: 60, minHeight: 36),
            isSelected: List.generate(
              options.length,
              (index) => index == selectedIndex,
            ),
            children: options
                .map((option) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        option,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ))
                .toList(),
            onPressed: onSelected,
          ),
        ],
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.grey.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Theme.of(context).colorScheme.surface.withOpacity(0.8)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                    : Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark 
              ? Colors.grey.withOpacity(0.2)
              : Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: isDark 
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : AppShadows.small,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
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
  bool hasPath = false;

  @override
  void initState() {
    super.initState();
    hasPath = widget.initialHasPath;
  }

  void resetPath() {
    if (mounted) {
      setState(() {
        hasPath = false;
      });
    }
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
                    useDefaultImage: true,  // Use default image for new drawings
                  ),
                ),
              );
              
              if (drawingData != null) {
                widget.onPathSaved(drawingData);
              }
            },
            icon: Icon(
              hasPath ? Icons.edit : Icons.draw,
              // Make icon white when path exists
              color: hasPath ? Colors.white : null,
            ),
            label: Text(
              hasPath ? 'Edit Auto Path' : 'Draw Auto Path',
              // Make text white when path exists
              style: TextStyle(
                color: hasPath ? Colors.white : null,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: hasPath ? 
                Theme.of(context).colorScheme.primary :  // Changed from primaryContainer to primary
                null,
              foregroundColor: hasPath ? Colors.white : null,  // Added explicit foreground color
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? (value ? Colors.blue.withOpacity(0.3) : Colors.grey.withOpacity(0.2))
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class NumberInput extends StatefulWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final bool autofocus;
  final FocusNode? focusNode;

  const NumberInput({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.autofocus = false,
    this.focusNode,
  }) : super(key: key);

  @override
  _NumberInputState createState() => _NumberInputState();
}

class _NumberInputState extends State<NumberInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = widget.focusNode ?? FocusNode();
    
    // Add listener to handle focus changes
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // When focus is lost, ensure the keyboard stays dismissed
        FocusScope.of(context).unfocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark
              ? Colors.grey.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: isDark ? [] : AppShadows.small,
      ),
      padding: EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            autofocus: widget.autofocus,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark
                      ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                      : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              fillColor: isDark
                  ? Theme.of(context).colorScheme.surface.withOpacity(0.8)
                  : Theme.of(context).colorScheme.surface,
              filled: true,
            ),
            onChanged: (text) {
              final newValue = int.tryParse(text);
              if (newValue != null) {
                widget.onChanged(newValue);
              }
            },
            onEditingComplete: () {
              // Explicitly unfocus when editing is complete
              FocusScope.of(context).unfocus();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surface.withOpacity(0.8)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: SizedBox(),
        icon: Icon(
          Icons.arrow_drop_down,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
        ),
        isDense: true,
        padding: EdgeInsets.zero,
        dropdownColor: isDark
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surface,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.grey.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ]
            : AppShadows.small,
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

// Create a reusable FormRow widget for consistent styling
class FormRow extends StatelessWidget {
  final String label;
  final Widget input;

  const FormRow({
    Key? key,
    required this.label,
    required this.input,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.grey.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: input,
          ),
        ],
      ),
    );
  }
}