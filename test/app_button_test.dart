import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sla_task_tracker_flutter/widgets/common.dart';

void main() {
  testWidgets('AppButton lays out inside an unbounded Row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              AppButton(label: 'Edit', icon: Icons.edit, onPressed: () {}),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(label: 'Complete', onPressed: () {}),
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Complete'), findsOneWidget);
  });
}
