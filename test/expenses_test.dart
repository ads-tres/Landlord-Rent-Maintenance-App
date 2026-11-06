import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/api/api_client.dart';
import 'package:landlord_app/core/storage/secure_store.dart';
import 'package:landlord_app/features/expenses/data/expenses_repository.dart';
import 'package:landlord_app/features/expenses/domain/expense.dart';
import 'package:landlord_app/features/expenses/presentation/add_expense_screen.dart';
import 'package:landlord_app/features/expenses/presentation/expenses_screen.dart';
import 'package:landlord_app/features/properties/data/properties_repository.dart';
import 'package:landlord_app/features/properties/domain/property.dart';
import 'package:landlord_app/features/properties/domain/unit.dart';
import 'package:landlord_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockExpensesRepository extends Mock implements ExpensesRepository {}

class MockPropertiesRepository extends Mock implements PropertiesRepository {}

Map<String, dynamic> expenseJson(
  int id, {
  String category = 'land_lease',
  int amount = 1200000,
  String spentOn = '2026-11-10',
  String? description = 'Yearly land lease',
  Map<String, dynamic>? source,
}) => {
  'id': id,
  'property_id': 1,
  'property_name': 'Bole Compound',
  'unit_id': null,
  'unit_label': null,
  'category': category,
  'amount': amount,
  'spent_on': spentOn,
  'description': description,
  'vendor': null,
  'source': source,
  'photos': [],
};

Widget harness(Widget child, List overrides) => ProviderScope(
  overrides: [
    keyValueStoreProvider.overrideWithValue(
      MemoryKeyValueStore({'locale': 'en'}),
    ),
    ...overrides,
  ],
  child: MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  ),
);

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(ExpenseCategory.other);
  });

  test('list reads the filtered total and automatic sources', () async {
    final dio = MockDio();
    when(() => dio.get('/expenses', queryParameters: {'property_id': 1}))
        .thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/expenses'),
            data: {
              'data': [
                expenseJson(
                  2,
                  category: 'repair',
                  source: {'type': 'repair', 'id': 9},
                ),
              ],
              'meta': {'total': 85000},
            },
          ),
        );

    final list = await ExpensesRepository(ApiClient(dio)).list(propertyId: 1);

    expect(list.total, 85000);
    expect(list.items.single.category, ExpenseCategory.repair);
    expect(list.items.single.source, ExpenseSource.repair);
    expect(list.items.single.isAutomatic, isTrue);
  });

  test('creating an expense posts multipart fields in santim', () async {
    final dio = MockDio();
    when(() => dio.post('/expenses', data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/expenses'),
        statusCode: 201,
        data: {'data': expenseJson(1)},
      ),
    );

    await ExpensesRepository(ApiClient(dio)).create(
      propertyId: 1,
      category: ExpenseCategory.landLease,
      amount: 1200000,
      spentOn: DateTime(2026, 11, 10),
      description: 'Yearly land lease',
      vendor: '',
    );

    final form =
        verify(() => dio.post('/expenses', data: captureAny(named: 'data')))
                .captured
                .single
            as FormData;
    final fields = Map.fromEntries(form.fields);
    expect(fields, {
      'property_id': '1',
      'category': 'land_lease',
      'amount': '1200000',
      'spent_on': '2026-11-10',
      'description': 'Yearly land lease',
    });
    expect(form.files, isEmpty);
  });

  testWidgets('lists expenses by month and deletes a manual one', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = MockExpensesRepository();
    when(() => repo.list(propertyId: 1)).thenAnswer(
      (_) async => (
        items: [
          Expense.fromJson(expenseJson(1)),
          Expense.fromJson(
            expenseJson(
              2,
              category: 'repair',
              amount: 85000,
              spentOn: '2026-10-20',
              description: 'Kitchen sink leaking',
              source: {'type': 'repair', 'id': 9},
            ),
          ),
        ],
        total: 1285000,
      ),
    );
    when(() => repo.delete(1)).thenAnswer((_) async {});

    await tester.pumpWidget(
      harness(const ExpensesScreen(propertyId: 1), [
        expensesRepositoryProvider.overrideWithValue(repo),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Br 12,850'), findsOneWidget); // total
    expect(find.text('Yearly land lease'), findsOneWidget);
    expect(find.textContaining('Automatic'), findsOneWidget);

    // Automatic expenses can't be deleted here.
    await tester.tap(find.byKey(const Key('expense-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('deleteExpense')), findsNothing);
    expect(find.textContaining('Change it there'), findsOneWidget);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('expense-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteExpense')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDeleteExpense')));
    await tester.pumpAndSettle();

    verify(() => repo.delete(1)).called(1);
  });

  testWidgets('adding an expense sends birr as santim', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = MockExpensesRepository();
    final properties = MockPropertiesRepository();
    const property = Property(
      id: 1,
      name: 'Bole Compound',
      units: [Unit(id: 10, propertyId: 1, label: 'Room 1')],
    );
    when(properties.list).thenAnswer((_) async => [property]);
    when(() => properties.get(1)).thenAnswer((_) async => property);
    when(
      () => repo.create(
        propertyId: any(named: 'propertyId'),
        unitId: any(named: 'unitId'),
        category: any(named: 'category'),
        amount: any(named: 'amount'),
        spentOn: any(named: 'spentOn'),
        description: any(named: 'description'),
        vendor: any(named: 'vendor'),
        photoPath: any(named: 'photoPath'),
        clientRef: any(named: 'clientRef'),
      ),
    ).thenAnswer((_) async => Expense.fromJson(expenseJson(3)));

    await tester.pumpWidget(
      harness(const AddExpenseScreen(propertyId: 1), [
        expensesRepositoryProvider.overrideWithValue(repo),
        propertiesRepositoryProvider.overrideWithValue(properties),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Whole property'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('expenseAmountField')),
      '1,250.50',
    );
    await tester.enterText(
      find.byKey(const Key('expenseDescriptionField')),
      'New pump',
    );
    await tester.tap(find.byKey(const Key('saveExpense')));
    await tester.pumpAndSettle();

    verify(
      () => repo.create(
        propertyId: 1,
        unitId: null,
        category: ExpenseCategory.repair,
        amount: 125050,
        spentOn: any(named: 'spentOn'),
        description: 'New pump',
        vendor: '',
        photoPath: null,
        clientRef: any(named: 'clientRef'),
      ),
    ).called(1);
  });
}
