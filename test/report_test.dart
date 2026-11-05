import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/reports/data/reports_repository.dart';
import 'package:landlord_app/features/reports/domain/quarterly_report.dart';
import 'package:landlord_app/features/reports/presentation/quarterly_report_screen.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockReportsRepository extends Mock implements ReportsRepository {}

QuarterlyReport report(int year, int quarter, {int total = 7500000}) =>
    QuarterlyReport.fromJson({
      'year': year,
      'quarter': quarter,
      'calendar': 'ethiopian',
      'label': 'Q$quarter, fiscal year $year',
      'from_display': '1 Tikimt 2019',
      'to_display': '30 Tahsas 2019',
      'total': total,
      'payments_count': total == 0 ? 0 : 6,
      'by_month': [
        if (total > 0)
          {
            'key': '2019-02',
            'label': 'Tikimt 2019',
            'total': 2500000,
            'count': 2,
          },
      ],
      'by_property': [
        if (total > 0)
          {
            'property': 'Bole Compound',
            'total': total,
            'units': [
              {'unit': 'Room 1', 'total': 3000000, 'count': 3},
            ],
          },
      ],
      'by_method': [
        if (total > 0) {'method': 'telebirr', 'total': total},
      ],
    });

void main() {
  test('quarter navigation wraps around the year', () {
    expect(previousQuarter(2019, 1), (year: 2018, quarter: 4));
    expect(nextQuarter(2019, 4), (year: 2020, quarter: 1));
    expect(nextQuarter(2019, 2), (year: 2019, quarter: 3));
  });

  testWidgets('shows the current quarter and moves to the previous one', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = MockReportsRepository();
    when(() => repo.quarterly()).thenAnswer((_) async => report(2019, 2));
    when(() => repo.quarterly(year: 2019, quarter: 1))
        .thenAnswer((_) async => report(2019, 1, total: 0));

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
          home: QuarterlyReportScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Q2, fiscal year 2019'), findsOneWidget);
    expect(find.text('Br 75,000'), findsWidgets);
    expect(find.text('6 payments'), findsOneWidget);
    expect(find.text('Tikimt 2019'), findsOneWidget);
    expect(find.text('Room 1'), findsOneWidget);
    expect(find.text('Telebirr'), findsOneWidget);
    expect(find.text('Share PDF'), findsOneWidget);

    await tester.tap(find.byKey(const Key('previousQuarter')));
    await tester.pumpAndSettle();

    expect(find.text('Q1, fiscal year 2019'), findsOneWidget);
    expect(find.text('No rent received in this quarter.'), findsOneWidget);
  });
}
