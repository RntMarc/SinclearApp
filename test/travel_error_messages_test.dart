import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/features/travel/travel_error_messages.dart';
import 'package:sinclear_beyond/features/travel/travel_planning_error_messages.dart';

ApiException _error(String code) => ApiException(
  statusCode: 409,
  errorCode: code,
  message: null,
);

void main() {
  test('trip_not_active is translated', () {
    expect(
      travelErrorMessage(_error('trip_not_active')),
      contains('Planung'),
    );
  });

  test('inconsistent_planning_data is translated', () {
    expect(
      planningErrorMessage(_error('inconsistent_planning_data')),
      contains('unvollständig'),
    );
  });

  test('unknown code falls back to server message', () {
    expect(
      travelErrorMessage(
        const ApiException(
          statusCode: 409,
          errorCode: 'weird',
          message: 'Boom',
        ),
      ),
      'Boom',
    );
  });
}
