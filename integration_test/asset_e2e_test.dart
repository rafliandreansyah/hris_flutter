import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/asset/presentation/pages/asset_detail_screen.dart';
import 'package:hris_flutter/features/asset/presentation/pages/asset_list_screen.dart';
import 'package:hris_flutter/features/asset/presentation/widgets/asset_card.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest('ASSET-01/02: daftar asset, detail, dan filter', ($) async {
    await launchAndLogin($);
    await openMenu($, 'Asset', screen: AssetListScreen);

    expect(find.text('Asset Saya'), findsOneWidget);
    final hasData = await waitForListLoaded($, card: AssetCard);
    expectNoErrorState();

    if (hasData) {
      final target = find.byType(AssetCard).hitTestable();
      await $.tester.ensureVisible(target.first);
      await $.pump(const Duration(milliseconds: 300));
      await $.tester.tap(target.first);
      await $.pump();
      await waitFor($, find.byType(AssetDetailScreen), reason: 'AssetDetailScreen');
      await pumpFor($, const Duration(seconds: 1));
      expectNoErrorState();
      await goBack($);
      await waitFor($, find.byType(AssetListScreen), reason: 'kembali ke daftar');
    }

    await openAndCancelFilterSheet($);
    await goBackToDashboard($);
  });
}
