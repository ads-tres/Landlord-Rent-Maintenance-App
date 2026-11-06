import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/reports/data/reports_repository.dart';
import 'package:landlord_app/features/reports/domain/annual_report.dart';
import 'package:landlord_app/features/reports/presentation/annual_report_screen.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockReportsRepository extends Mock implements ReportsRepository {}

AnnualReport report(int year) => AnnualReport.fromJson({
  'year': year,
  'label': 'Fiscal year $year',
  'from_display': '1 Hamle ${year - 1}',
  'to_display': '30 Sene $year',
  'income': 3000000,
  'refunded': 0,
  'expenses': 200000,
  'net': 2800000,
  'average_occupancy': 25,
  'months': [
    {
      'label': 'Hamle ${year - 1}',
      'income': 1000000,
      'refunded': 0,
      'expenses': 0,
      'net': 1000000,
      'occupancy': 50,
    },
    {
      'label': 'Nehase ${year - 1}',
      'income': 1000000,
      'refunded': 0,
      'expenses': 200000,
      'net': 800000,
      'occupancy': 50,
    },
  ],
});

void main() {
  testWidgets('shows the year and moves to the previous one', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = MockReportsRepository();
    when(repo.annual).thenAnswer((_) async => report(2019));
    when(() => repo.annual(year: 2018)).thenAnswer((_) async => report(2018));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(
            MemoryKeyValueStore({'locale': 'en'}),
          ),
          reportsRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: AnnualReportScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fiscal year 2019'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('annualNet'))).data,
      'Br 28,000',
    );
    expect(find.text('Nehase 2018'), findsOneWidget);
    expect(find.textContaining('50% let'), findsNWidgets(2));
    expect(find.text('25%'), findsOneWidget);

    await tester.tap(find.byKey(const Key('previousYear')));
    await tester.pumpAndSettle();
    expect(find.text('Fiscal year 2018'), findsOneWidget);
  });
}
