import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/team_coworkers_card.dart';

void main() {
  testWidgets('pakai totalCount dari API untuk judul & tombol, bukan jumlah pratinjau', (
    tester,
  ) async {
    final preview = List.generate(
      5,
      (i) => CoworkerItem(name: 'Rekan $i', role: 'Staff', initials: 'R$i'),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TeamCoworkersCard(coworkers: preview, totalCount: 12, onViewAll: () {}),
        ),
      ),
    ));

    expect(find.text('TEAM COWORKERS (12)'), findsOneWidget);
    expect(find.text('Lihat Semua Rekan Kerja (12)'), findsOneWidget);
    expect(find.text('Rekan 4'), findsOneWidget);
  });
}
