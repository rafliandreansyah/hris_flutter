import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/widgets/filter/app_date_range_picker.dart';
import 'package:hris_flutter/core/widgets/filter/filter_field_selector.dart';
import 'package:hris_flutter/core/widgets/filter/filter_option_selector_modal.dart';
import 'package:hris_flutter/core/widgets/filter/filter_status_segmented_row.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  Widget buildTestableWidget({
    required Widget child,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MaterialApp(
      themeMode: themeMode,
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  group('Filter Modular Components Tests', () {
    group('FilterFieldSelector Widget Tests', () {
      testWidgets('renders label, value, icon and triggers onTap', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          buildTestableWidget(
            child: FilterFieldSelector(
              label: 'Perusahaan',
              value: 'PT Oasish Digital',
              icon: LucideIcons.building2,
              onTap: () => tapped = true,
            ),
          ),
        );

        expect(find.text('Perusahaan'), findsOneWidget);
        expect(find.text('PT Oasish Digital'), findsOneWidget);
        expect(find.byIcon(LucideIcons.building2), findsOneWidget);

        await tester.tap(find.text('PT Oasish Digital'));
        await tester.pump();
        expect(tapped, isTrue);
      });

      testWidgets('shows lock icon and helper text when disabled', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          buildTestableWidget(
            child: FilterFieldSelector(
              label: 'Departemen',
              value: 'Semua Departemen',
              icon: LucideIcons.network,
              isEnabled: false,
              helperText: 'Pilih perusahaan terlebih dahulu',
              onTap: () => tapped = true,
            ),
          ),
        );

        expect(find.text('Pilih perusahaan terlebih dahulu'), findsOneWidget);
        expect(find.byIcon(LucideIcons.lock), findsOneWidget);

        await tester.tap(find.text('Semua Departemen'));
        await tester.pump();
        expect(tapped, isFalse);
      });

      testWidgets('shows clear button and invokes onClear callback', (tester) async {
        bool cleared = false;

        await tester.pumpWidget(
          buildTestableWidget(
            child: FilterFieldSelector(
              label: 'Filter Tanggal',
              value: '01 Jan 2026 - 31 Jan 2026',
              icon: LucideIcons.calendar,
              onClear: () => cleared = true,
            ),
          ),
        );

        expect(find.byIcon(LucideIcons.x), findsOneWidget);
        await tester.tap(find.byIcon(LucideIcons.x));
        await tester.pump();
        expect(cleared, isTrue);
      });

      testWidgets('shows loading indicator when isLoading is true', (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: const FilterFieldSelector(
              label: 'Memuat...',
              value: 'Loading',
              icon: LucideIcons.loader,
              isLoading: true,
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('FilterStatusSegmentedRow Widget Tests', () {
      testWidgets('renders all default status options and handles selection', (tester) async {
        String selected = 'requested';

        await tester.pumpWidget(
          buildTestableWidget(
            child: StatefulBuilder(
              builder: (context, setState) {
                return FilterStatusSegmentedRow(
                  selectedValue: selected,
                  onSelected: (val) {
                    setState(() {
                      selected = val;
                    });
                  },
                );
              },
            ),
          ),
        );

        expect(find.text('Semua'), findsOneWidget);
        expect(find.text('Diajukan'), findsOneWidget);
        expect(find.text('Disetujui'), findsOneWidget);
        expect(find.text('Ditolak'), findsOneWidget);

        await tester.tap(find.text('Disetujui'));
        await tester.pump();

        expect(selected, 'approved');
      });
    });

    group('FilterOptionSelectorModal Tests', () {
      testWidgets('opens modal and selects an option', (tester) async {
        String chosen = '';

        await tester.pumpWidget(
          buildTestableWidget(
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showFilterOptionSelector(
                      context,
                      title: 'Pilih Divisi',
                      options: const ['Engineering', 'Design', 'Marketing', 'Finance'],
                      selectedValue: 'Design',
                      onSelected: (val) => chosen = val,
                    );
                  },
                  child: const Text('Buka Modal'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Buka Modal'));
        await tester.pumpAndSettle();

        expect(find.text('Pilih Divisi'), findsOneWidget);
        expect(find.text('Engineering'), findsOneWidget);
        expect(find.text('Design'), findsOneWidget);
        expect(find.byIcon(LucideIcons.check), findsOneWidget);

        await tester.tap(find.text('Engineering'));
        await tester.pumpAndSettle();

        expect(chosen, 'Engineering');
      });

      testWidgets('filters options when search query is entered in modal', (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showFilterOptionSelector(
                      context,
                      title: 'Pilih Anggota',
                      options: const [
                        'Alpha',
                        'Beta',
                        'Charlie',
                        'Delta',
                        'Echo',
                        'Foxtrot',
                      ],
                      selectedValue: 'Alpha',
                      onSelected: (_) {},
                    );
                  },
                  child: const Text('Buka Modal Search'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Buka Modal Search'));
        await tester.pumpAndSettle();

        // Search bar should be rendered because options > 5
        expect(find.byType(TextField), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Echo');
        await tester.pump();

        expect(find.widgetWithText(ListTile, 'Echo'), findsOneWidget);
        expect(find.text('Alpha'), findsNothing);
      });
    });

    group('AppDateRangePicker Tests', () {
      testWidgets('opens date range picker dialog without error', (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showAppDateRangePicker(
                      context,
                      initialDateRange: DateTimeRange(
                        start: DateTime(2026, 1, 1),
                        end: DateTime(2026, 1, 15),
                      ),
                    );
                  },
                  child: const Text('Buka Kalender'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Buka Kalender'));
        await tester.pumpAndSettle();

        expect(find.text('PILIH RENTANG TANGGAL'), findsOneWidget);
      });
    });
  });
}
