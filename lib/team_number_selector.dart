import 'package:flutter/material.dart';

Future<void> showTeamNumberSelector(BuildContext context, int initialValue, ValueChanged<int> onChanged) {
  // Create a mutable value to track changes
  int currentValue = initialValue;
  
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.4,
        padding: const EdgeInsets.all(16),
        child: StatefulBuilder( // Add StatefulBuilder to handle state changes
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Team Number',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      return SizedBox(
                        width: 40,
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 40,
                          perspective: 0.005,
                          diameterRatio: 1.2,
                          physics: const FixedExtentScrollPhysics(),
                          controller: FixedExtentScrollController(
                            initialItem: int.parse(
                              currentValue.toString().padLeft(5, '0')[index],
                            ),
                          ),
                          onSelectedItemChanged: (value) {
                            // Update the current value when a digit changes
                            String numStr = currentValue.toString().padLeft(5, '0');
                            List<String> digits = numStr.split('');
                            digits[index] = value.toString();
                            currentValue = int.parse(digits.join());
                            setState(() {}); // Update the UI
                            onChanged(currentValue); // Notify parent
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 10,
                            builder: (context, index) => Center(
                              child: Text(
                                index.toString(),
                                style: const TextStyle(
                                  fontSize: 20,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        onChanged(initialValue); // Reset to initial value
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        onChanged(currentValue); // Ensure final value is passed
                        Navigator.pop(context);
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
} 