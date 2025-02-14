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
    setState(() {
      _savedTeamNumber = prefs.getInt(_teamNumberKey);
      
      // Load cached data if available
      final teamDataStr = prefs.getString(_teamDataKey);
      final eventsDataStr = prefs.getString(_eventsDataKey);
      
      if (teamDataStr != null) {
        _teamData = json.decode(teamDataStr);
        TelemetryService().logInfo('Loaded cached team data', 'Team ${_teamData?['team_number']}');
      }
      if (eventsDataStr != null) {
        _eventsData = json.decode(eventsDataStr);
        TelemetryService().logInfo('Loaded cached events data', '${_eventsData?.length} events');
      }
    });

    // If we have a team number but no data, load it
    if (_savedTeamNumber != null && (_teamData == null || _eventsData == null)) {
      TelemetryService().logInfo('Missing cached data, loading from API');
      _loadTeamData(_savedTeamNumber!);
    }
  }

  Future<void> _saveTeamNumber() async {
    final teamNumber = int.parse(_selectedDigits.join());
    TelemetryService().logAction('save_team_number_initiated', teamNumber.toString());
    
    // Show confirmation dialog
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      TelemetryService().logAction('team_number_confirmed', teamNumber.toString());
      
      // Show loading indicator
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        // Load and cache all data
        final teamInfo = await _tbaService.getTeamInfo(teamNumber);
        if (teamInfo == null) throw Exception('Could not find team $teamNumber');

        final currentYear = DateTime.now().year;
        final events = await _tbaService.getTeamEvents(teamNumber, currentYear);
        if (events == null) throw Exception('Could not load events');

        // Sort events by date
        events.sort((a, b) => (a['start_date'] ?? '').compareTo(b['start_date'] ?? ''));

        // Cache everything
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_teamNumberKey, teamNumber);
        await prefs.setString(_teamDataKey, json.encode(teamInfo));
        await prefs.setString(_eventsDataKey, json.encode(events));

        // Update state
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
  }

  Future<void> _loadTeamData(int teamNumber) async {
    TelemetryService().logAction('load_team_data_started', 'Team $teamNumber');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentYear = DateTime.now().year;
      TelemetryService().logInfo('Fetching team info', 'Team $teamNumber');
      final teamInfo = await _tbaService.getTeamInfo(teamNumber);
      
      if (teamInfo == null || teamInfo['team_number'] != teamNumber) {
        TelemetryService().logError('team_not_found', 'Team $teamNumber');
        throw Exception('Could not find team $teamNumber');
      }
      
      TelemetryService().logInfo('Fetching team events', 'Team $teamNumber, Year $currentYear');
      final events = await _tbaService.getTeamEvents(teamNumber, currentYear);
      
      if (events == null) {
        TelemetryService().logError('events_not_found', 'Team $teamNumber');
        throw Exception('Could not load events for team $teamNumber');
      }

      events.sort((a, b) => (a['start_date'] ?? '').compareTo(b['start_date'] ?? ''));
      TelemetryService().logInfo('Events loaded', '${events.length} events found');

      // Cache the data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_teamDataKey, json.encode(teamInfo));
      await prefs.setString(_eventsDataKey, json.encode(events));
      TelemetryService().logInfo('Data cached successfully');

      setState(() {
        _teamData = teamInfo;
        _eventsData = events;
        _isLoading = false;
      });
      
      TelemetryService().logAction('load_team_data_completed', 'Team $teamNumber');
    } catch (e) {
      TelemetryService().logError('load_team_data_failed', e.toString());
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Make resetTeamData public
  Future<void> resetTeamData() async {
    TelemetryService().logAction('reset_team_data_started');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_teamNumberKey);
    await prefs.remove(_teamDataKey);
    await prefs.remove(_eventsDataKey);
    
    setState(() {
      _savedTeamNumber = null;
      _teamData = null;
      _eventsData = null;
      _selectedDigits.fillRange(0, 5, 0);
    });
    TelemetryService().logAction('reset_team_data_completed');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text('Error: $_error'),
            SizedBox(height: 16),
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

    // If we have team data, show the team info page with refresh button
    if (_teamData != null && _eventsData != null) {
      return RefreshIndicator(
        onRefresh: () async {
          // Show confirmation dialog
          final shouldRefresh = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Refresh Team Data'),
              content: Text('Do you want to refresh the team data?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Refresh'),
                ),
              ],
            ),
          );

          if (shouldRefresh == true && _savedTeamNumber != null) {
            await _loadTeamData(_savedTeamNumber!);
          }
        },
        child: TeamInfoPage(
          teamInfo: _teamData!,
          events: _eventsData!,
        ),
      );
    }

    // If we don't have a team number yet, show the centered team selector
    if (_savedTeamNumber == null) {
      return Center(
        child: SingleChildScrollView(
          child: _buildTeamNumberSelector(),
        ),
      );
    }

    // Loading saved team's data
    return const Center(
      child: CircularProgressIndicator(),
    );
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
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                return SizedBox(
                  width: 50,
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 50,
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (value) {
                      setState(() {
                        _selectedDigits[index] = value;
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 10,
                      builder: (context, index) => Center(
                        child: Text(
                          index.toString(),
                          style: const TextStyle(
                            fontSize: 32,
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
}

class TeamInfoPage extends StatelessWidget {
  final Map<String, dynamic> teamInfo;
  final List<dynamic> events;

  const TeamInfoPage({
    Key? key,
    required this.teamInfo,
    required this.events,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            teamInfo['nickname'] ?? 'Unknown Team',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${teamInfo['city']}, ${teamInfo['state_prov']}, ${teamInfo['country']}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Events',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...events.map((event) => Card(
            child: ListTile(
              title: Text(event['name']),
              subtitle: Text(event['start_date']),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                TelemetryService().logAction(
                  'event_selected',
                  'Event: ${event['key']}, Team: ${teamInfo['team_number']}'
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetailsPage(
                      event: event,
                      tbaService: TBAService(),
                    ),
                  ),
                );
              },
            ),
          )).toList(),
        ],
      ),
    );
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

class _EventDetailsPageState extends State<EventDetailsPage> {
  List<dynamic>? _teams;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  bool get _isChampionshipEvent {
    final eventName = widget.event['name']?.toString().toLowerCase() ?? '';
    final eventKey = widget.event['key']?.toString().toLowerCase() ?? '';
    return (eventName.contains('championship') && eventName.contains('first')) || 
           eventKey.startsWith('2025cmptx'); // This matches FIRST Championship events
  }

  Future<void> _loadTeams() async {
    if (_isChampionshipEvent) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      TelemetryService().logInfo('Loading teams for event', widget.event['key']);
      final teams = await widget.tbaService.getEventTeams(widget.event['key']);
      if (mounted) {
        setState(() {
          _teams = teams;
          _isLoading = false;
        });
      }
      TelemetryService().logInfo('Teams loaded', '${teams?.length ?? 0} teams found');
    } catch (e) {
      TelemetryService().logError('Failed to load teams', e.toString());
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event['short_name'] ?? widget.event['name']),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isChampionshipEvent
              ? _buildChampionshipView()
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Error: $_error'),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadTeams,
                            child: Text('Try Again'),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      children: [
                        // Event Info Card
                        Card(
                          margin: const EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Event Information',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text('Date: ${widget.event['start_date']}'),
                                if (widget.event['city'] != null)
                                  Text('Location: ${widget.event['city']}, ${widget.event['state_prov']}'),
                              ],
                            ),
                          ),
                        ),
                        // Teams List
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Participating Teams',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._teams!.map((team) => Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            title: Text('Team ${team['team_number']} - ${team['nickname']}'),
                            subtitle: Text('${team['city']}, ${team['state_prov']}'),
                            trailing: const Icon(Icons.info_outline),
                            onTap: () async {
                              TelemetryService().logAction(
                                'team_selected_from_event',
                                'Team ${team['team_number']} at event ${widget.event['key']}'
                              );
                              
                              try {
                                final teamInfo = await widget.tbaService.getTeamInfo(team['team_number']);
                                final events = await widget.tbaService.getTeamEvents(
                                  team['team_number'],
                                  DateTime.now().year
                                );
                                
                                if (mounted && teamInfo != null && events != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TeamDetailsPage(
                                        teamInfo: teamInfo,
                                        events: events,
                                        tbaService: widget.tbaService,
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error loading team data: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        )).toList(),
                      ],
                    ),
    );
  }

  Widget _buildChampionshipView() {
    final eventKey = widget.event['key'];
    final tbaUrl = 'https://www.thebluealliance.com/event/$eventKey';
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 64,
              color: Colors.amber,
            ),
            const SizedBox(height: 24),
            Text(
              'FIRST Championship Event',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Due to the large number of participating teams, '
              'the team list is not available in the app. '
              'Please visit The Blue Alliance website for complete event details.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                final url = Uri.parse(tbaUrl);
                TelemetryService().logAction('championship_tba_link_clicked', eventKey);
                try {
                  if (!await launchUrl(url)) {
                    throw Exception('Could not launch $url');
                  }
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
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _teamStats;

  @override
  void initState() {
    super.initState();
    _loadTeamStats();
  }

  Future<void> _loadTeamStats() async {
    setState(() => _isLoading = true);
    try {
      // Get team stats for each event
      final stats = <String, dynamic>{};
      for (final event in widget.events) {
        final eventKey = event['key'];
        // You could add more stats from TBA API here
        stats[eventKey] = {
          'event_name': event['name'],
          'date': event['start_date'],
          'location': '${event['city']}, ${event['state_prov']}',
        };
      }
      
      setState(() {
        _teamStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Team ${widget.teamInfo['team_number']}'),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Team Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.teamInfo['nickname'] ?? 'Unknown Team',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.teamInfo['city']}, ${widget.teamInfo['state_prov']}, ${widget.teamInfo['country']}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),

                      // Team Info
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Team Information',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoCard([
                              if (widget.teamInfo['rookie_year'] != null)
                                'Rookie Year: ${widget.teamInfo['rookie_year']}',
                              if (widget.teamInfo['website'] != null)
                                'Website: ${widget.teamInfo['website']}',
                              if (widget.teamInfo['school_name'] != null)
                                'School: ${widget.teamInfo['school_name']}',
                            ]),
                          ],
                        ),
                      ),

                      // 2025 Season Events
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '2025 Season Events',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            ...widget.events.map((event) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ExpansionTile(
                                title: Text(event['name']),
                                subtitle: Text(event['start_date']),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Location: ${event['city']}, ${event['state_prov']}'),
                                        const SizedBox(height: 8),
                                        FilledButton.icon(
                                          onPressed: () async {
                                            final url = Uri.parse(
                                              'https://www.thebluealliance.com/event/${event['key']}'
                                            );
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
                                          label: const Text('View on TBA'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard(List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(item),
          )).toList(),
        ),
      ),
    );
  }
} 