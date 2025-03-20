import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data.dart';
import 'theme/app_theme.dart';
import 'widgets/section_card.dart';
import 'widgets/counter_button.dart';
import 'widgets/dropdown_card.dart';

class EditRecordPage extends StatefulWidget {
  final ScoutingRecord record;

  const EditRecordPage({Key? key, required this.record}) : super(key: key);

  @override
  EditRecordPageState createState() => EditRecordPageState();
}

class EditRecordPageState extends State<EditRecordPage> {
  late int teamNumber;
  late int matchNumber;
  late String matchType;
  late bool isRedAlliance;
  
  // Auto
  late bool autoTaxis;
  late bool autoCoralPreloaded;
  late int autoAlgaeRemoved;
  late int autoCoralHeight4Success;
  late int autoCoralHeight4Failure;
  late int autoCoralHeight3Success;
  late int autoCoralHeight3Failure;
  late int autoCoralHeight2Success;
  late int autoCoralHeight2Failure;
  late int autoCoralHeight1Success;
  late int autoCoralHeight1Failure;
  late int autoAlgaeInNet;
  late int autoAlgaeInProcessor;

  // Teleop
  late int teleopCoralHeight4Success;
  late int teleopCoralHeight4Failure;
  late int teleopCoralHeight3Success;
  late int teleopCoralHeight3Failure;
  late int teleopCoralHeight2Success;
  late int teleopCoralHeight2Failure;
  late int teleopCoralHeight1Success;
  late int teleopCoralHeight1Failure;
  late bool teleopCoralRankingPoint;
  late int teleopAlgaeRemoved;
  late int teleopAlgaeProcessorAttempts;
  late int teleopAlgaeProcessed;
  late int teleopAlgaeScoredInNet;
  late bool teleopCanPickupAlgae;
  late String teleopCoralPickupMethod;

  // Endgame
  late bool endgameReturnedToBarge;
  late String endgameCageHang;
  late bool endgameBargeRankingPoint;

  // Other
  late bool otherCoOpPoint;
  late bool otherBreakdown;
  late String otherComments;

  @override
  void initState() {
    super.initState();
    // Initialize all fields from the record
    teamNumber = widget.record.teamNumber;
    matchNumber = widget.record.matchNumber;
    matchType = widget.record.matchType;
    isRedAlliance = widget.record.isRedAlliance;
    
    // Auto
    autoTaxis = widget.record.autoTaxis;
    autoCoralPreloaded = widget.record.autoCoralPreloaded;
    autoAlgaeRemoved = widget.record.autoAlgaeRemoved;
    autoCoralHeight4Success = widget.record.autoCoralHeight4Success;
    autoCoralHeight4Failure = widget.record.autoCoralHeight4Failure;
    autoCoralHeight3Success = widget.record.autoCoralHeight3Success;
    autoCoralHeight3Failure = widget.record.autoCoralHeight3Failure;
    autoCoralHeight2Success = widget.record.autoCoralHeight2Success;
    autoCoralHeight2Failure = widget.record.autoCoralHeight2Failure;
    autoCoralHeight1Success = widget.record.autoCoralHeight1Success;
    autoCoralHeight1Failure = widget.record.autoCoralHeight1Failure;
    autoAlgaeInNet = widget.record.autoAlgaeInNet;
    autoAlgaeInProcessor = widget.record.autoAlgaeInProcessor;

    // Teleop
    teleopCoralHeight4Success = widget.record.teleopCoralHeight4Success;
    teleopCoralHeight4Failure = widget.record.teleopCoralHeight4Failure;
    teleopCoralHeight3Success = widget.record.teleopCoralHeight3Success;
    teleopCoralHeight3Failure = widget.record.teleopCoralHeight3Failure;
    teleopCoralHeight2Success = widget.record.teleopCoralHeight2Success;
    teleopCoralHeight2Failure = widget.record.teleopCoralHeight2Failure;
    teleopCoralHeight1Success = widget.record.teleopCoralHeight1Success;
    teleopCoralHeight1Failure = widget.record.teleopCoralHeight1Failure;
    teleopCoralRankingPoint = widget.record.teleopCoralRankingPoint;
    teleopAlgaeRemoved = widget.record.teleopAlgaeRemoved;
    teleopAlgaeProcessorAttempts = widget.record.teleopAlgaeProcessorAttempts;
    teleopAlgaeProcessed = widget.record.teleopAlgaeProcessed;
    teleopAlgaeScoredInNet = widget.record.teleopAlgaeScoredInNet;
    teleopCanPickupAlgae = widget.record.teleopCanPickupAlgae;
    teleopCoralPickupMethod = widget.record.teleopCoralPickupMethod;

    // Endgame
    endgameReturnedToBarge = widget.record.endgameReturnedToBarge;
    endgameCageHang = widget.record.endgameCageHang;
    endgameBargeRankingPoint = widget.record.endgameBargeRankingPoint;

    // Other
    otherCoOpPoint = widget.record.otherCoOpPoint;
    otherBreakdown = widget.record.otherBreakdown;
    otherComments = widget.record.otherComments;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Record'),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildMatchInfoSection(),
              _buildAutoSection(),
              _buildTeleopSection(),
              _buildEndgameSection(),
              _buildOtherSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchInfoSection() {
    return SectionCard(
      title: 'Match Information',
      icon: Icons.event,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Team Number',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                controller: TextEditingController(text: teamNumber.toString()),
                onChanged: (value) {
                  setState(() {
                    teamNumber = int.tryParse(value) ?? teamNumber;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Match Number',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                controller: TextEditingController(text: matchNumber.toString()),
                onChanged: (value) {
                  setState(() {
                    matchNumber = int.tryParse(value) ?? matchNumber;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownCard(
                label: 'Match Type',
                value: matchType,
                items: const ['Practice', 'Qualification', 'Playoff'],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      matchType = value;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Row(
                children: [
                  _buildAllianceButton(true),
                  _buildAllianceButton(false),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAllianceButton(bool isRed) {
    final isSelected = isRedAlliance == isRed;
    final color = isRed ? AppColors.redAlliance : AppColors.blueAlliance;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          isRedAlliance = isRed;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isRed ? 'Red' : 'Blue',
          style: TextStyle(
            color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAutoSection() {
    return SectionCard(
      title: 'Auto',
      icon: Icons.smart_toy,
      children: [
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('Taxis'),
                value: autoTaxis,
                onChanged: (value) {
                  setState(() {
                    autoTaxis = value ?? false;
                  });
                },
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Coral Preloaded'),
                value: autoCoralPreloaded,
                onChanged: (value) {
                  setState(() {
                    autoCoralPreloaded = value ?? false;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCounterRow('Algae Removed', autoAlgaeRemoved, (value) {
          setState(() => autoAlgaeRemoved = value);
        }),
        _buildCounterRow('Algae in Net', autoAlgaeInNet, (value) {
          setState(() => autoAlgaeInNet = value);
        }),
        _buildCounterRow('Algae in Processor', autoAlgaeInProcessor, (value) {
          setState(() => autoAlgaeInProcessor = value);
        }),
        const Divider(),
        _buildCoralHeightCounters(
          height: 4,
          success: autoCoralHeight4Success,
          failure: autoCoralHeight4Failure,
          onSuccessChanged: (value) {
            setState(() => autoCoralHeight4Success = value);
          },
          onFailureChanged: (value) {
            setState(() => autoCoralHeight4Failure = value);
          },
        ),
        _buildCoralHeightCounters(
          height: 3,
          success: autoCoralHeight3Success,
          failure: autoCoralHeight3Failure,
          onSuccessChanged: (value) {
            setState(() => autoCoralHeight3Success = value);
          },
          onFailureChanged: (value) {
            setState(() => autoCoralHeight3Failure = value);
          },
        ),
        _buildCoralHeightCounters(
          height: 2,
          success: autoCoralHeight2Success,
          failure: autoCoralHeight2Failure,
          onSuccessChanged: (value) {
            setState(() => autoCoralHeight2Success = value);
          },
          onFailureChanged: (value) {
            setState(() => autoCoralHeight2Failure = value);
          },
        ),
        _buildCoralHeightCounters(
          height: 1,
          success: autoCoralHeight1Success,
          failure: autoCoralHeight1Failure,
          onSuccessChanged: (value) {
            setState(() => autoCoralHeight1Success = value);
          },
          onFailureChanged: (value) {
            setState(() => autoCoralHeight1Failure = value);
          },
        ),
      ],
    );
  }

  Widget _buildTeleopSection() {
    return SectionCard(
      title: 'Teleop',
      icon: Icons.sports_esports,
      children: [
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('Can Pickup Algae'),
                value: teleopCanPickupAlgae,
                onChanged: (value) {
                  setState(() {
                    teleopCanPickupAlgae = value ?? false;
                  });
                },
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Coral Ranking Point'),
                value: teleopCoralRankingPoint,
                onChanged: (value) {
                  setState(() {
                    teleopCoralRankingPoint = value ?? false;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownCard(
          label: 'Coral Pickup Method',
          value: teleopCoralPickupMethod,
          items: const ['Human', 'Ground', 'Both', 'None'],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                teleopCoralPickupMethod = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        _buildCounterRow('Algae Removed', teleopAlgaeRemoved, (value) {
          setState(() => teleopAlgaeRemoved = value);
        }),
        _buildCounterRow('Algae Processor Attempts', teleopAlgaeProcessorAttempts, (value) {
          setState(() => teleopAlgaeProcessorAttempts = value);
        }),
        _buildCounterRow('Algae Processed', teleopAlgaeProcessed, (value) {
          setState(() => teleopAlgaeProcessed = value);
        }),
        _buildCounterRow('Algae Scored in Net', teleopAlgaeScoredInNet, (value) {
          setState(() => teleopAlgaeScoredInNet = value);
        }),
        const Divider(),
        _buildCoralHeightCounters(
          height: 4,
          success: teleopCoralHeight4Success,
          failure: teleopCoralHeight4Failure,
          onSuccessChanged: (value) {
            setState(() => teleopCoralHeight4Success = value);
          },
          onFailureChanged: (value) {
            setState(() => teleopCoralHeight4Failure = value);
          },
        ),
        _buildCoralHeightCounters(
          height: 3,
          success: teleopCoralHeight3Success,
          failure: teleopCoralHeight3Failure,
          onSuccessChanged: (value) {
            setState(() => teleopCoralHeight3Success = value);
          },
          onFailureChanged: (value) {
            setState(() => teleopCoralHeight3Failure = value);
          },
        ),
        _buildCoralHeightCounters(
          height: 2,
          success: teleopCoralHeight2Success,
          failure: teleopCoralHeight2Failure,
          onSuccessChanged: (value) {
            setState(() => teleopCoralHeight2Success = value);
          },
          onFailureChanged: (value) {
            setState(() => teleopCoralHeight2Failure = value);
          },
        ),
        _buildCoralHeightCounters(
          height: 1,
          success: teleopCoralHeight1Success,
          failure: teleopCoralHeight1Failure,
          onSuccessChanged: (value) {
            setState(() => teleopCoralHeight1Success = value);
          },
          onFailureChanged: (value) {
            setState(() => teleopCoralHeight1Failure = value);
          },
        ),
      ],
    );
  }

  Widget _buildEndgameSection() {
    return SectionCard(
      title: 'Endgame',
      icon: Icons.timer,
      children: [
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('Returned to Barge'),
                value: endgameReturnedToBarge,
                onChanged: (value) {
                  setState(() {
                    endgameReturnedToBarge = value ?? false;
                  });
                },
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Barge Ranking Point'),
                value: endgameBargeRankingPoint,
                onChanged: (value) {
                  setState(() {
                    endgameBargeRankingPoint = value ?? false;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownCard(
          label: 'Cage Hang',
          value: endgameCageHang,
          items: const ['None', 'Attempted', 'Partial', 'Complete'],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                endgameCageHang = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildOtherSection() {
    return SectionCard(
      title: 'Other',
      icon: Icons.more_horiz,
      children: [
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('Co-Op Point'),
                value: otherCoOpPoint,
                onChanged: (value) {
                  setState(() {
                    otherCoOpPoint = value ?? false;
                  });
                },
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Breakdown'),
                value: otherBreakdown,
                onChanged: (value) {
                  setState(() {
                    otherBreakdown = value ?? false;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Comments',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          controller: TextEditingController(text: otherComments),
          onChanged: (value) {
            setState(() {
              otherComments = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCounterRow(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label),
          ),
          CounterButton(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildCoralHeightCounters({
    required int height,
    required int success,
    required int failure,
    required ValueChanged<int> onSuccessChanged,
    required ValueChanged<int> onFailureChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Height $height', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildCounterRow('Success', success, onSuccessChanged),
        _buildCounterRow('Failure', failure, onFailureChanged),
        const SizedBox(height: 8),
      ],
    );
  }

  void _saveChanges() {
    final updatedRecord = ScoutingRecord(
      timestamp: widget.record.timestamp,  // Keep original timestamp
      matchNumber: matchNumber,
      matchType: matchType,
      teamNumber: teamNumber,
      isRedAlliance: isRedAlliance,
      
      // Auto
      autoTaxis: autoTaxis,
      autoCoralPreloaded: autoCoralPreloaded,
      autoAlgaeRemoved: autoAlgaeRemoved,
      autoCoralHeight4Success: autoCoralHeight4Success,
      autoCoralHeight4Failure: autoCoralHeight4Failure,
      autoCoralHeight3Success: autoCoralHeight3Success,
      autoCoralHeight3Failure: autoCoralHeight3Failure,
      autoCoralHeight2Success: autoCoralHeight2Success,
      autoCoralHeight2Failure: autoCoralHeight2Failure,
      autoCoralHeight1Success: autoCoralHeight1Success,
      autoCoralHeight1Failure: autoCoralHeight1Failure,
      autoAlgaeInNet: autoAlgaeInNet,
      autoAlgaeInProcessor: autoAlgaeInProcessor,

      // Teleop
      teleopCoralHeight4Success: teleopCoralHeight4Success,
      teleopCoralHeight4Failure: teleopCoralHeight4Failure,
      teleopCoralHeight3Success: teleopCoralHeight3Success,
      teleopCoralHeight3Failure: teleopCoralHeight3Failure,
      teleopCoralHeight2Success: teleopCoralHeight2Success,
      teleopCoralHeight2Failure: teleopCoralHeight2Failure,
      teleopCoralHeight1Success: teleopCoralHeight1Success,
      teleopCoralHeight1Failure: teleopCoralHeight1Failure,
      teleopCoralRankingPoint: teleopCoralRankingPoint,
      teleopAlgaeRemoved: teleopAlgaeRemoved,
      teleopAlgaeProcessorAttempts: teleopAlgaeProcessorAttempts,
      teleopAlgaeProcessed: teleopAlgaeProcessed,
      teleopAlgaeScoredInNet: teleopAlgaeScoredInNet,
      teleopCanPickupAlgae: teleopCanPickupAlgae,
      teleopCoralPickupMethod: teleopCoralPickupMethod,

      // Endgame
      endgameReturnedToBarge: endgameReturnedToBarge,
      endgameCageHang: endgameCageHang,
      endgameBargeRankingPoint: endgameBargeRankingPoint,

      // Other
      otherCoOpPoint: otherCoOpPoint,
      otherBreakdown: otherBreakdown,
      otherComments: otherComments,

      // Legacy fields - maintain original values
      cageType: widget.record.cageType,
      coralPreloaded: autoCoralPreloaded,
      taxis: autoTaxis,
      algaeRemoved: autoAlgaeRemoved,
      coralPlaced: widget.record.coralPlaced,
      rankingPoint: teleopCoralRankingPoint,
      canPickupCoral: widget.record.canPickupCoral,
      canPickupAlgae: teleopCanPickupAlgae,
      algaeScoredInNet: teleopAlgaeScoredInNet,
      coralRankingPoint: teleopCoralRankingPoint,
      algaeProcessed: teleopAlgaeProcessed,
      processedAlgaeScored: teleopAlgaeProcessed,
      processorCycles: teleopAlgaeProcessorAttempts,
      coOpPoint: otherCoOpPoint,
      returnedToBarge: endgameReturnedToBarge,
      cageHang: endgameCageHang,
      bargeRankingPoint: endgameBargeRankingPoint,
      breakdown: otherBreakdown,
      comments: otherComments,
      coralPickupMethod: teleopCoralPickupMethod,
      feederStation: widget.record.feederStation,
      coralOnReefHeight1: teleopCoralHeight1Success,
      coralOnReefHeight2: teleopCoralHeight2Success,
      coralOnReefHeight3: teleopCoralHeight3Success,
      coralOnReefHeight4: teleopCoralHeight4Success,
      robotPath: widget.record.robotPath,  // Maintain original robot path
    );

    Navigator.pop(context, updatedRecord);
  }
} 