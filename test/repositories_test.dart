import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landlord_app/core/api/api_client.dart';
import 'package:landlord_app/core/api/api_exception.dart';
import 'package:landlord_app/features/auth/data/auth_repository.dart';
import 'package:landlord_app/features/properties/data/properties_repository.dart';
import 'package:landlord_app/features/properties/domain/unit.dart';
import 'package:landlord_app/features/tenants/data/tenants_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

Response<dynamic> ok(String path, Object data, [int status = 200]) => Response(
  requestOptions: RequestOptions(path: path),
  data: data,
  statusCode: status,
);

void main() {
  late MockDio dio;
  late ApiClient api;

  setUp(() {
    dio = MockDio();
    api = ApiClient(dio);
  });

  test('verify returns token and user', () async {
    when(() => dio.post('/auth/verify', data: any(named: 'data'))).thenAnswer(
      (_) async => ok('/auth/verify', {
        'token': '1|abc',
        'is_new': true,
        'user': {
          'id': 1,
          'phone': '+251911234567',
          'name': null,
          'locale': 'am',
          'calendar_pref': 'ethiopian',
        },
      }),
    );

    final result = await AuthRepository(api)
        .verify('+251911234567', '123456', locale: 'am');

    expect(result.token, '1|abc');
    expect(result.isNew, isTrue);
    expect(result.user.phone, '+251911234567');
  });

  test('validation errors become field errors', () async {
    final request = RequestOptions(path: '/auth/verify');
    when(() => dio.post('/auth/verify', data: any(named: 'data'))).thenThrow(
      DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 422,
          data: {
            'message': 'The code is wrong or has expired.',
            'errors': {
              'code': ['The code is wrong or has expired.'],
            },
          },
        ),
      ),
    );

    expect(
      () => AuthRepository(api).verify('+251911234567', '000000', locale: 'en'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.isValidation, 'isValidation', isTrue)
            .having(
              (e) => e.fieldErrors['code'],
              'code error',
              'The code is wrong or has expired.',
            ),
      ),
    );
  });

  test('connection failures are network errors', () async {
    when(
      () => dio.get(
        '/properties',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/properties'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(
      () => PropertiesRepository(api).list(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.isNetworkError,
          'isNetworkError',
          isTrue,
        ),
      ),
    );
  });

  test('properties list parses counts and units', () async {
    when(
      () => dio.get(
        '/properties/5',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => ok('/properties/5', {
        'data': {
          'id': 5,
          'name': 'Bole Compound',
          'sub_city': 'Bole',
          'woreda': '3',
          'units_count': 2,
          'vacant_units_count': 1,
          'units': [
            {
              'id': 1,
              'property_id': 5,
              'label': 'Room 1',
              'bedrooms': 1,
              'status': 'occupied',
            },
            {
              'id': 2,
              'property_id': 5,
              'label': 'Room 2',
              'bedrooms': null,
              'status': 'vacant',
            },
          ],
        },
      }),
    );

    final property = await PropertiesRepository(api).get(5);

    expect(property.location('Woreda'), 'Bole, Woreda 3');
    expect(property.unitsCount, 2);
    expect(property.units.first.status, UnitStatus.occupied);
    expect(property.units.last.bedrooms, isNull);
  });

  test('creating a tenant sends the privacy-notice confirmation', () async {
    when(() => dio.post('/tenants', data: any(named: 'data'))).thenAnswer(
      (_) async => ok('/tenants', {
        'data': {
          'id': 9,
          'full_name': 'Abebe Kebede',
          'phone': '+251922111222',
          'has_id_number': false,
        },
      }, 201),
    );

    final tenant = await TenantsRepository(api).create(
      fullName: 'Abebe Kebede',
      phone: '+251922111222',
      privacyNoticeShown: true,
      noticeLocale: 'am',
    );

    expect(tenant.id, 9);
    final sent =
        verify(() => dio.post('/tenants', data: captureAny(named: 'data')))
                .captured
                .single
            as Map;
    expect(sent['privacy_notice_shown'], isTrue);
    expect(sent['notice_locale'], 'am');
    expect(sent.containsKey('id_number'), isFalse);
  });
}
