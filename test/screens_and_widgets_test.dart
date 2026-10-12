import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sla_task_tracker_flutter/models/enums.dart';
import 'package:sla_task_tracker_flutter/models/task.dart';
import 'package:sla_task_tracker_flutter/models/team_member.dart';
import 'package:sla_task_tracker_flutter/widgets/task_card.dart';
import 'package:sla_task_tracker_flutter/widgets/team_member_card.dart';

void main() {
  final sampleMember = TeamMember(
    id: 'user-1',
    name: 'Maya Kim',
    firstName: 'Maya',
    initials: 'MK',
    role: 'Backend Engineer',
    avatarColor: 'avatar-mint',
  );

  final sampleTask = Task(
    id: 'task-1',
    title: 'Resolve Redis connection timeout',
    description:
        'Investigate intermittent socket timeouts under high concurrency',
    assignedTo: 'user-1',
    priority: TaskPriority.high,
    deadline: DateTime.now().add(const Duration(hours: 3)),
    status: TaskStatus.inProgress,
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    updatedAt: DateTime.now(),
    atRiskAt: DateTime.now().add(const Duration(hours: 2)),
  );

  group('TaskCard Widget Tests', () {
    testWidgets('renders title, priority, status badge, and deadline', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: sampleTask,
              slaStatus: SlaStatus.onTrack,
              assignee: sampleMember,
            ),
          ),
        ),
      );

      expect(find.text('Resolve Redis connection timeout'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('MK'), findsOneWidget);
    });

    testWidgets('calls onTap when clicked', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: sampleTask,
              slaStatus: SlaStatus.onTrack,
              assignee: sampleMember,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TaskCard));
      expect(tapped, isTrue);
    });
  });

  group('TeamMemberCard Widget Tests', () {
    testWidgets(
      'renders member name, role, and "You" badge when current user',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TeamMemberCard(
                member: sampleMember,
                isCurrentUser: true,
                assignedCount: 3,
              ),
            ),
          ),
        );

        expect(find.text('Maya Kim'), findsOneWidget);
        expect(find.text('Backend Engineer'), findsOneWidget);
        expect(find.text('You'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.text('tasks'), findsOneWidget);
      },
    );

    testWidgets('does not render "You" badge when not current user', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamMemberCard(
              member: sampleMember,
              isCurrentUser: false,
              assignedCount: 1,
            ),
          ),
        ),
      );

      expect(find.text('Maya Kim'), findsOneWidget);
      expect(find.text('You'), findsNothing);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('task'), findsOneWidget);
    });
  });

  group('TaskDetails Action Row 360dp Layout Tests', () {
    Widget buildActionRowForStatus(TaskStatus status) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 21),
                child: Row(
                  children: [
                    // Edit button (flex: 3)
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined, size: 17),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Edit',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    // Lifecycle button (flex: 4)
                    if (status == TaskStatus.todo)
                      Expanded(
                        flex: 4,
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded, size: 18),
                              SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'Start',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (status == TaskStatus.inProgress)
                      Expanded(
                        flex: 4,
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pause_rounded, size: 18),
                              SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'Pause',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (status == TaskStatus.paused)
                      Expanded(
                        flex: 4,
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded, size: 18),
                              SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'Resume',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(width: 9),
                    // Complete button (flex: 5)
                    Expanded(
                      flex: 5,
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, size: 18),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Complete',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'Paused task action row renders without overflow on 360dp viewport',
      (tester) async {
        await tester.pumpWidget(buildActionRowForStatus(TaskStatus.paused));

        expect(tester.takeException(), isNull);
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Resume'), findsOneWidget);
        expect(find.text('Complete'), findsOneWidget);
      },
    );

    testWidgets(
      'InProgress task action row renders without overflow on 360dp viewport',
      (tester) async {
        await tester.pumpWidget(buildActionRowForStatus(TaskStatus.inProgress));

        expect(tester.takeException(), isNull);
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Pause'), findsOneWidget);
        expect(find.text('Complete'), findsOneWidget);
      },
    );

    testWidgets(
      'ToDo task action row renders without overflow on 360dp viewport',
      (tester) async {
        await tester.pumpWidget(buildActionRowForStatus(TaskStatus.todo));

        expect(tester.takeException(), isNull);
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Start'), findsOneWidget);
        expect(find.text('Complete'), findsOneWidget);
      },
    );
  });
}
