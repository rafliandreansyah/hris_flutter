import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/widgets/request_card_shimmer_loading.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  Widget buildTestWidget({
    Brightness brightness = Brightness.light,
    int itemCount = 4,
    EdgeInsetsGeometry? padding,
  }) {
    return MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(
        body: RequestCardShimmerLoading(
          itemCount: itemCount,
          padding: padding,
        ),
      ),
    );
  }

  group('RequestCardShimmerLoading Widget Tests', () {
    testWidgets('renders Shimmer with specified item count in light theme', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(itemCount: 3));

      expect(find.byType(RequestCardShimmerLoading), findsOneWidget);
      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);

      final listView = tester.widget<ListView>(find.byType(ListView));
      final delegate = listView.childrenDelegate as SliverChildBuilderDelegate;
      expect(delegate.childCount, 5); // 3 items + 2 separators
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(brightness: Brightness.dark, itemCount: 2),
      );

      expect(find.byType(RequestCardShimmerLoading), findsOneWidget);
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('respects custom padding', (tester) async {
      const customPadding = EdgeInsets.all(24);
      await tester.pumpWidget(
        buildTestWidget(padding: customPadding, itemCount: 2),
      );

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.padding, customPadding);
    });
  });
}
