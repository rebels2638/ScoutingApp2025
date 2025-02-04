import 'package:flutter/material.dart';
import 'data.dart';

class ComparisonPage extends StatefulWidget {
  final List<ScoutingRecord> records;

  const ComparisonPage({Key? key, required this.records}) : super(key: key);

  @override
  _ComparisonPageState createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> {
  late ScrollController _horizontalController;
  late ScrollController _verticalController;

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
    _verticalController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDataCell(String text, {bool highlight = false}) {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: highlight ? Colors.blue.shade50 : null,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(text),
    );
  }

  List<DataRow> _buildRows() {
    List<DataRow> rows = [];

    // match info
    rows.addAll([
      DataRow(cells: [
        DataCell(_buildHeaderCell('Match')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.matchNumber}'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Team')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.teamNumber}'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Type')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.matchType))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Alliance')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.isRedAlliance ? 'Red' : 'Blue'))),
      ]),
    ]);

    // auto section
    rows.add(DataRow(cells: [
      DataCell(_buildHeaderCell('Autonomous')),
      ...widget.records.map((r) => DataCell(_buildDataCell(''))),
    ]));
    
    rows.addAll([
      DataRow(cells: [
        DataCell(_buildHeaderCell('Cage Type')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.cageType))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Coral Preloaded')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.coralPreloaded ? 'Yes' : 'No'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Taxis')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.taxis ? 'Yes' : 'No'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Algae Removed')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.algaeRemoved}'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Coral Placed')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.coralPlaced))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Auto RP')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.rankingPoint ? 'Yes' : 'No'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Can Pickup')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.canPickupAlgae ? 'Yes' : 'No'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Auto Algae in Net')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.autoAlgaeInNet}'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Auto Algae in Processor')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.autoAlgaeInProcessor}'))),
      ]),
    ]);

    // teleop section
    rows.add(DataRow(cells: [
      DataCell(_buildHeaderCell('Teleop')),
      ...widget.records.map((r) => DataCell(_buildDataCell(''))),
    ]));

    rows.addAll([
      DataRow(cells: [
        DataCell(_buildHeaderCell('Net Algae')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.algaeScoredInNet}'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Coral RP')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.coralRankingPoint ? 'Yes' : 'No'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Algae Processed')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.algaeProcessed}'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Processed Scored')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.processedAlgaeScored}'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Processor Cycles')),
        ...widget.records.map((r) => DataCell(_buildDataCell('${r.processorCycles}'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Co-Op Point')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.coOpPoint ? 'Yes' : 'No'))),
      ]),
    ]);

    // endgame section
    rows.add(DataRow(cells: [
      DataCell(_buildHeaderCell('Endgame')),
      ...widget.records.map((r) => DataCell(_buildDataCell(''))),
    ]));

    rows.addAll([
      DataRow(cells: [
        DataCell(_buildHeaderCell('Returned to Barge')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.returnedToBarge ? 'Yes' : 'No'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Cage Hang')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.cageHang))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Barge RP')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.bargeRankingPoint ? 'Yes' : 'No'))),
      ]),
    ]);

    // other section
    rows.add(DataRow(cells: [
      DataCell(_buildHeaderCell('Other')),
      ...widget.records.map((r) => DataCell(_buildDataCell(''))),
    ]));

    rows.addAll([
      DataRow(cells: [
        DataCell(_buildHeaderCell('Breakdown')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.breakdown ? 'Yes' : 'No'))),
      ]),
      DataRow(cells: [
        DataCell(_buildHeaderCell('Comments')),
        ...widget.records.map((r) => DataCell(_buildDataCell(r.comments))),
      ]),
    ]);

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compare ${widget.records.length} Records'),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _horizontalController,
        child: SingleChildScrollView(
          controller: _verticalController,
          child: DataTable(
            columnSpacing: 24,
            headingRowHeight: 0,
            columns: [
              DataColumn(label: Container(width: 150)),
              ...widget.records.map((r) => DataColumn(label: Container(width: 120))),
            ],
            rows: _buildRows(),
          ),
        ),
      ),
    );
  }
}