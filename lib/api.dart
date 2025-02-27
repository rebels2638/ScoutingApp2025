import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'services/tba_service.dart';
import 'dart:convert';
import 'services/telemetry_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ApiPage extends StatefulWidget {
  const ApiPage({Key? key}) : super(key: key);

  @override
  State<ApiPage> createState() => ApiPageState();
}

class ApiPageState extends State<ApiPage> {
  static const String _teamNumberKey = 'selected_team_number';
  static const String _teamDataKey = 'team_data';
  static const String _eventsDataKey = 'events_data';
  
  int? _savedTeamNumber;
  final List<int> _selectedDigits = [0, 0, 0, 0, 0];
  final TBAService _tbaService = TBAService();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _teamData;
  List<dynamic>? _eventsData;
  bool _prefsLoaded = false;

  // Add loading state tracking
  Map<String, bool> _loadingStates = {
    'team': false,
    'events': false,
    'eventTeams': false,
    'matches': false,
  };
  Map<String, String> _loadingMessages = {
    'team': 'Loading team information...',
    'events': 'Loading team events...',
    'eventTeams': 'Loading event participants...',
    'matches': 'Loading match schedules...',
  };
  int _totalItemsToLoad = 0;
  int _itemsLoaded = 0;
  String _currentOperation = '';
  DateTime? _loadStartTime;

  // Add this static key to access the state
  static final GlobalKey<ApiPageState> globalKey = GlobalKey<ApiPageState>();

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    TelemetryService().logInfo('Loading saved team data');
    final prefs = await SharedPreferences.getInstance();
    final savedTeamNumber = prefs.getInt(_teamNumberKey);
    final teamDataStr = prefs.getString(_teamDataKey);
    final eventsDataStr = prefs.getString(_eventsDataKey);
    setState(() {
      _savedTeamNumber = savedTeamNumber;
      if (teamDataStr != null) {
        _teamData = json.decode(teamDataStr);
      }
      if (eventsDataStr != null) {
        _eventsData = json.decode(eventsDataStr);
      }
      _prefsLoaded = true;
    });
    if (savedTeamNumber != null) {
      if (_teamData == null || _eventsData == null) {
        _loadTeamData(savedTeamNumber);
      }
    }
  }

  Future<void> _saveTeamNumber() async {
    final teamNumber = int.parse(_selectedDigits.join());
    TelemetryService().logAction('save_team_number_initiated', teamNumber.toString());
    
    try {
      // Check team change cooldown
      final canChange = await _tbaService.canChangeTeam();
      if (!canChange) {
        throw Exception('Please wait 12 hours between changing team numbers');
      }

      // Show confirmation dialog with cooldown warnings
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Team Number'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Are you sure your team number is $teamNumber?'),
              const SizedBox(height: 8),
              const Text(
                'This will be your team\'s scouting app',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Important Cooldown Periods:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Team Number Changes: 12 hours\n'
                      '• Data Refreshes: 1 hour',
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        TelemetryService().logAction('team_number_confirmed', teamNumber.toString());
        
        setState(() {
          _isLoading = true;
          _error = null;
        });

        try {
          // Use new method to fetch and cache all data
          final currentYear = DateTime.now().year;
          await _tbaService.fetchAndCacheAllTeamData(teamNumber, currentYear);

          // Update team change timestamp
          await _tbaService.updateTeamChangeTimestamp();

          // Load cached data into state
          final prefs = await SharedPreferences.getInstance();
          final teamInfo = await _tbaService.getTeamInfo(teamNumber);
          final events = await _tbaService.getTeamEvents(teamNumber, currentYear);

          // Cache everything
          await prefs.setInt(_teamNumberKey, teamNumber);
          await prefs.setString(_teamDataKey, json.encode(teamInfo));
          await prefs.setString(_eventsDataKey, json.encode(events));

          setState(() {
            _savedTeamNumber = teamNumber;
            _teamData = teamInfo;
            _eventsData = events;
            _isLoading = false;
          });

          TelemetryService().logAction('team_setup_completed', 'Team $teamNumber');
        } catch (e) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
          TelemetryService().logError('team_setup_failed', e.toString());
        }
      } else {
        TelemetryService().logAction('team_number_cancelled', teamNumber.toString());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _loadTeamData(int teamNumber) async {
    TelemetryService().logAction('load_team_data_started', 'Team $teamNumber');
    setState(() {
      _isLoading = true;
      _error = null;
      _loadStartTime = DateTime.now();
      _itemsLoaded = 0;
      _currentOperation = 'Initializing...';
      _loadingStates.updateAll((key, value) => false);
    });

    try {
      final currentYear = DateTime.now().year;
      
      // Load team info
      setState(() {
        _loadingStates['team'] = true;
        _currentOperation = 'Loading team information...';
      });
      
      TelemetryService().logInfo('Fetching team info', 'Team $teamNumber');
      final teamInfo = await _tbaService.getTeamInfo(teamNumber);
      
      if (teamInfo == null || teamInfo['team_number'] != teamNumber) {
        TelemetryService().logError('team_not_found', 'Team $teamNumber');
        throw Exception('Could not find team $teamNumber');
      }

      setState(() {
        _loadingStates['team'] = false;
        _itemsLoaded++;
        _loadingStates['events'] = true;
        _currentOperation = 'Loading team events...';
      });
      
      // Load team events
      TelemetryService().logInfo('Fetching team events', 'Team $teamNumber, Year $currentYear');
      final events = await _tbaService.getTeamEvents(teamNumber, currentYear);
      
      if (events == null) {
        TelemetryService().logError('events_not_found', 'Team $teamNumber');
        throw Exception('Could not load events');
      }

      events.sort((a, b) => (a['start_date'] ?? '').compareTo(b['start_date'] ?? ''));
      TelemetryService().logInfo('Events loaded', '${events.length} events found');

      setState(() {
        _loadingStates['events'] = false;
        _itemsLoaded++;
        _loadingStates['eventTeams'] = true;
        _totalItemsToLoad = 2 + events.length * 2; // Team + Events + (Teams & Matches per event)
        _currentOperation = 'Loading event participants...';
      });

      // Load all event teams and matches in parallel
      final eventDataFutures = events.map((event) async {
        final eventKey = event['key'];
        
        // Get and cache event teams
        final teams = await _tbaService.getEventTeams(eventKey);
        setState(() {
          _itemsLoaded++;
          _currentOperation = 'Loading matches for ${event['short_name'] ?? event['name']}...';
        });
        
        // Get and cache event matches
        await _tbaService.getEventMatches(eventKey);
        setState(() => _itemsLoaded++);
        
        return {
          'event': event,
          'teams': teams,
        };
      }).toList();

      await Future.wait(eventDataFutures);

      // Cache the data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_teamDataKey, json.encode(teamInfo));
      await prefs.setString(_eventsDataKey, json.encode(events));
      TelemetryService().logInfo('Data cached successfully');

      setState(() {
        _teamData = teamInfo;
        _eventsData = events;
        _isLoading = false;
        _loadStartTime = null;
      });
      
      TelemetryService().logAction('load_team_data_completed', 'Team $teamNumber');
    } catch (e) {
      TelemetryService().logError('load_team_data_failed', e.toString());
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _loadStartTime = null;
      });
    }
  }

  Future<void> resetTeamData() async {
    TelemetryService().logAction('reset_team_data', 'Resetting all team data');
    final prefs = await SharedPreferences.getInstance();
    
    // Clear all saved data
    await prefs.remove(_teamNumberKey);
    await prefs.remove(_teamDataKey);
    await prefs.remove(_eventsDataKey);
    
    // Reset state
    setState(() {
      _savedTeamNumber = null;
      _teamData = null;
      _eventsData = null;
      _error = null;
      _prefsLoaded = true;
    });
  }

  void _handleDataRefresh() {
    if (_savedTeamNumber != null) {
      _loadTeamData(_savedTeamNumber!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded || _isLoading) {
      return _buildLoadingScreen();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_savedTeamNumber != null) {
                  _loadTeamData(_savedTeamNumber!);
                } else {
                  setState(() => _error = null);
                }
              },
              child: Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_savedTeamNumber == null) {
      return Center(
        child: SingleChildScrollView(
          child: _buildTeamNumberSelector(),
        ),
      );
    }

    if (_teamData != null && _eventsData != null) {
      return TeamInfoPage(
        teamInfo: _teamData!,
        events: _eventsData!,
        tbaService: _tbaService,
        onDataRefreshed: _handleDataRefresh,
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildTeamNumberSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Select Your Team Number',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return SizedBox(
                  width: 50,
                  child: ListWheelScrollView(
                    itemExtent: 50,
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (value) {
                      setState(() {
                        _selectedDigits[index] = value;
                      });
                    },
                    children: List.generate(
                      10,
                      (i) => Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            i.toString(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedDigits.fillRange(0, 5, 0);
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Reset'),
              ),
              ElevatedButton(
                onPressed: () => _saveTeamNumber(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    if (!_prefsLoaded) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Calculate progress and estimated time
    final progress = _totalItemsToLoad > 0 ? _itemsLoaded / _totalItemsToLoad : 0.0;
    String? estimatedTimeRemaining;
    
    if (_loadStartTime != null && _itemsLoaded > 0) {
      final elapsed = DateTime.now().difference(_loadStartTime!);
      final estimatedTotal = elapsed * (_totalItemsToLoad / _itemsLoaded);
      final remaining = estimatedTotal - elapsed;
      
      if (remaining.inSeconds < 60) {
        estimatedTimeRemaining = '${remaining.inSeconds}s remaining';
      } else {
        estimatedTimeRemaining = '${(remaining.inSeconds / 60).ceil()}m remaining';
      }
    }

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_download_outlined,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              Text(
                'Loading Data',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _currentOperation,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
              const SizedBox(height: 16),
              if (estimatedTimeRemaining != null)
                Text(
                  estimatedTimeRemaining,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              const SizedBox(height: 24),
              _buildLoadingStatesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingStatesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _loadingStates.entries.map((entry) {
        final isActive = entry.value;
        final isDone = !isActive && _loadingMessages.containsKey(entry.key);
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              if (isActive)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              else if (isDone)
                const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: Colors.green,
                )
              else
                const SizedBox(width: 16),
              const SizedBox(width: 12),
              Text(
                _loadingMessages[entry.key] ?? '',
                style: TextStyle(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : isDone
                          ? Colors.green
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class TeamInfoPage extends StatefulWidget {
  final Map<String, dynamic> teamInfo;
  final List<dynamic> events;
  final TBAService tbaService;
  final Function() onDataRefreshed;

  const TeamInfoPage({
    Key? key,
    required this.teamInfo,
    required this.events,
    required this.tbaService,
    required this.onDataRefreshed,
  }) : super(key: key);

  @override
  State<TeamInfoPage> createState() => _TeamInfoPageState();
}

class _TeamInfoPageState extends State<TeamInfoPage> {
  bool _isRefreshing = false;

  Future<void> _refreshAllData() async {
    setState(() => _isRefreshing = true);
    
    try {
      // Check refresh cooldown
      final canRefresh = await widget.tbaService.canRefreshData();
      if (!canRefresh) {
        throw Exception('Please wait at least 1 hour between refreshes');
      }

      // Show confirmation dialog
      final shouldRefresh = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Refresh Team Data'),
          content: const Text(
            'This will refresh all team and event data from The Blue Alliance. Continue?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );

      if (shouldRefresh != true) {
        setState(() => _isRefreshing = false);
        return;
      }

      // Refresh all data
      final teamNumber = widget.teamInfo['team_number'];
      final currentYear = DateTime.now().year;
      await widget.tbaService.fetchAndCacheAllTeamData(teamNumber, currentYear);

      // Update UI with fresh data
      final freshTeamInfo = await widget.tbaService.getTeamInfo(teamNumber);
      final freshEvents = await widget.tbaService.getTeamEvents(teamNumber, currentYear);
      
      if (freshEvents == null || freshTeamInfo == null) {
        throw Exception('Failed to refresh data');
      }

      // Cache the fresh data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('team_data', json.encode(freshTeamInfo));
      await prefs.setString('events_data', json.encode(freshEvents));

      // Notify parent to update its state
      widget.onDataRefreshed();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team data refreshed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refreshAllData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Team Header Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark 
                          ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Team ${widget.teamInfo['team_number']}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                if (widget.teamInfo['rookie_year'] != null) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.amber.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Text(
                                      'Since ${widget.teamInfo['rookie_year']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.amber[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.teamInfo['nickname'] ?? 'Unknown Team',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${widget.teamInfo['city']}, ${widget.teamInfo['state_prov']}, ${widget.teamInfo['country']}',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.teamInfo['school_name'] != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.teamInfo['school_name'],
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (widget.teamInfo['website'] != null) ...[
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.public),
                                label: const Text('Visit Team Website'),
                                onPressed: () async {
                                  final url = Uri.parse(widget.teamInfo['website']);
                                  try {
                                    await launchUrl(url);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error opening website: $e')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh All Data'),
                              onPressed: _isRefreshing ? null : _refreshAllData,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Events Section
                Text(
                  '2025 Season Events',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...widget.events.map((event) => _buildEventCard(context, event)).toList(),
              ],
            ),
          ),
        ),
        if (_isRefreshing)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, dynamic event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final startDate = DateTime.parse(event['start_date']);
    final endDate = DateTime.parse(event['end_date']);
    final isUpcoming = startDate.isAfter(DateTime.now());
    final isOngoing = startDate.isBefore(DateTime.now()) && 
                      endDate.isAfter(DateTime.now());
    
    // Check if this is the championship event
    final isChampionshipEvent = event['key']?.toString().toLowerCase() == '2025cmptx';
    final eventName = isChampionshipEvent ? 'FIRST Championship' : (event['short_name'] ?? event['name']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOngoing
              ? Theme.of(context).colorScheme.primary
              : isDark
                  ? Theme.of(context).colorScheme.outline.withOpacity(0.2)
                  : Colors.transparent,
          width: isOngoing ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsPage(
                event: event,
                tbaService: widget.tbaService,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          eventName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isUpcoming || isOngoing)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isOngoing
                                ? Colors.green.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isOngoing
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            isOngoing ? 'Ongoing' : 'Upcoming',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isOngoing ? Colors.green[700] : Colors.blue[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${event['city']}, ${event['state_prov']}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class EventDetailsPage extends StatefulWidget {
  final dynamic event;
  final TBAService tbaService;

  const EventDetailsPage({
    Key? key,
    required this.event,
    required this.tbaService,
  }) : super(key: key);

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> with SingleTickerProviderStateMixin {
  List<dynamic>? _teams;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (!_isChampionshipEvent) {
      _loadTeams();
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isChampionshipEvent {
    final eventKey = widget.event['key']?.toString().toLowerCase() ?? '';
    return eventKey == '2025cmptx';
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await widget.tbaService.getEventTeams(widget.event['key']);
      if (mounted) {
        setState(() {
          _teams = teams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChampionshipEvent) {
      return _buildChampionshipView(context);
    }

    final startDate = DateTime.parse(widget.event['start_date']);
    final endDate = DateTime.parse(widget.event['end_date']);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event['short_name'] ?? widget.event['name']),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Teams'),
            Tab(text: 'Matches'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Overview Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(
                  title: 'Event Details',
                  content: [
                    _buildInfoRow(Icons.event, 'Dates', 
                      '${_formatDate(startDate)} - ${_formatDate(endDate)}'),
                    _buildInfoRow(Icons.location_on, 'Location', 
                      '${widget.event['city']}, ${widget.event['state_prov']}'),
                    if (widget.event['venue'] != null)
                      _buildInfoRow(Icons.business, 'Venue', 
                        widget.event['venue']),
                  ],
                ),
                const SizedBox(height: 16),
                if (_teams != null)
                  _buildInfoCard(
                    title: 'Quick Stats',
                    content: [
                      _buildInfoRow(Icons.groups, 'Teams', 
                        '${_teams!.length} registered'),
                    ],
                  ),
              ],
            ),
          ),
          
          // Teams Tab
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text('Error: $_error'))
                  : _buildTeamsList(),
          
          // Matches Tab
          _buildMatchesList(),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> content}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildTeamsList() {
    if (_teams == null) return const Center(child: Text('No teams found'));
    
    final sortedTeams = List.from(_teams!)
      ..sort((a, b) => (a['team_number'] as int).compareTo(b['team_number'] as int));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sortedTeams.length,
      itemBuilder: (context, index) {
        final team = sortedTeams[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    team['team_number'].toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              team['nickname'] ?? 'Team ${team['team_number']}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text('${team['city']}, ${team['state_prov']}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _navigateToTeamDetails(team);
            },
          ),
        );
      },
    );
  }

  Future<void> _navigateToTeamDetails(Map<String, dynamic> team) async {
    try {
      // Get team's events for the current year
      final events = await widget.tbaService.getTeamEvents(
        team['team_number'],
        DateTime.now().year,
      );
      
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TeamDetailsPage(
            teamInfo: team,
            events: events ?? [],
            tbaService: widget.tbaService,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading team data: $e')),
      );
    }
  }

  Widget _buildMatchesList() {
    // TODO: Implement matches list from local database
    return const Center(
      child: Text('Match schedule coming soon'),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Widget _buildChampionshipView(BuildContext context) {
    final startDate = DateTime.parse(widget.event['start_date']);
    final endDate = DateTime.parse(widget.event['end_date']);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('FIRST Championship'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.calendar_today, 'Dates', 
                      '${_formatDate(startDate)} - ${_formatDate(endDate)}'),
                    _buildInfoRow(Icons.location_on, 'Location', 
                      '${widget.event["city"]}, ${widget.event["state_prov"]}'),
                    if (widget.event['venue'] != null)
                      _buildInfoRow(Icons.business, 'Venue', widget.event['venue']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, 
                          color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Championship Event',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Due to the large number of participating teams, '
                      'detailed event information is not available in the app. '
                      'Please visit The Blue Alliance website for complete event details.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: FilledButton.icon(
                        onPressed: () async {
                          final url = Uri.parse('https://www.thebluealliance.com/event/${widget.event["key"]}');
                          try {
                            await launchUrl(url);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error opening link: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.public),
                        label: const Text('View on TBA Website'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TeamDetailsPage extends StatefulWidget {
  final Map<String, dynamic> teamInfo;
  final List<dynamic> events;
  final TBAService tbaService;

  const TeamDetailsPage({
    Key? key,
    required this.teamInfo,
    required this.events,
    required this.tbaService,
  }) : super(key: key);

  @override
  State<TeamDetailsPage> createState() => _TeamDetailsPageState();
}

class _TeamDetailsPageState extends State<TeamDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Team ${widget.teamInfo['team_number']}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.teamInfo['nickname'] ?? 'Unknown Team',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  if (widget.teamInfo['rookie_year'] != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        'Rookie Year: ${widget.teamInfo['rookie_year']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.amber[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Team Info Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(
                    'Team Information',
                    [
                      _buildInfoRow(
                        Icons.location_on,
                        'Location',
                        '${widget.teamInfo['city']}, ${widget.teamInfo['state_prov']}, ${widget.teamInfo['country']}',
                      ),
                      if (widget.teamInfo['school_name'] != null)
                        _buildInfoRow(
                          Icons.school,
                          'School',
                          widget.teamInfo['school_name'],
                        ),
                      if (widget.teamInfo['website'] != null)
                        _buildInfoRow(
                          Icons.language,
                          'Website',
                          widget.teamInfo['website'],
                          isLink: true,
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Events Section
                  _buildInfoSection(
                    '2025 Events',
                    widget.events.map((event) => _buildEventRow(event)).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                if (isLink)
                  InkWell(
                    onTap: () async {
                      try {
                        await launchUrl(Uri.parse(value));
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error opening link: $e')),
                          );
                        }
                      }
                    },
                    child: Text(
                      value,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                else
                  Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventRow(dynamic event) {
    final startDate = DateTime.parse(event['start_date']);
    final endDate = DateTime.parse(event['end_date']);
    final isUpcoming = startDate.isAfter(DateTime.now());
    final isOngoing = startDate.isBefore(DateTime.now()) && 
                      endDate.isAfter(DateTime.now());
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsPage(
              event: event,
              tbaService: widget.tbaService,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['short_name'] ?? event['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isUpcoming || isOngoing)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isOngoing
                      ? Colors.green.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isOngoing
                        ? Colors.green.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  isOngoing ? 'Ongoing' : 'Upcoming',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isOngoing ? Colors.green[700] : Colors.blue[700],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
} 