import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehat_hk_mobile/core/storage/session_manager.dart';

void main() {
  group('Assigned Hotels SPRINT Validation Tests', () {
    test('1 assigned hotel - parsing & validation', () {
      final jsonStr = jsonEncode([
        {'id': 1, 'code': 'abadi', 'name': 'Abadi Tasikmalaya'}
      ]);
      final List<dynamic> assignedHotels = jsonDecode(jsonStr);
      
      final session = SessionData(
        userId: 1729,
        username: 'rou',
        role: 'engineer',
        level: 'Engineering',
        hotelId: 'abadi',
        hotelName: 'Abadi Tasikmalaya',
        assignedHotels: assignedHotels,
      );

      expect(session.assignedHotels, isNotNull);
      expect(session.assignedHotels!.length, 1);
      expect(session.assignedHotels![0]['name'], 'Abadi Tasikmalaya');
      expect(session.assignedHotels![0]['id'], 1);
    });

    test('2 assigned hotels - parsing & validation', () {
      final jsonStr = jsonEncode([
        {'id': 4, 'code': 'dagosky', 'name': 'Hotel Dago SKY'},
        {'id': 7, 'code': 'kurnia', 'name': 'Hotel Kurnia'}
      ]);
      final List<dynamic> assignedHotels = jsonDecode(jsonStr);
      
      final session = SessionData(
        userId: 1729,
        username: 'rou',
        assignedHotels: assignedHotels,
      );

      expect(session.assignedHotels!.length, 2);
      expect(session.assignedHotels![0]['name'], 'Hotel Dago SKY');
      expect(session.assignedHotels![1]['name'], 'Hotel Kurnia');
      
      // Verify ordering
      expect(session.assignedHotels![0]['id'], 4);
      expect(session.assignedHotels![1]['id'], 7);
    });

    test('3 assigned hotels - parsing & validation', () {
      final jsonStr = jsonEncode([
        {'id': 4, 'code': 'dagosky', 'name': 'Hotel Dago SKY'},
        {'id': 7, 'code': 'kurnia', 'name': 'Hotel Kurnia'},
        {'id': 14, 'code': 'sentra', 'name': 'Sentra Inn'}
      ]);
      final List<dynamic> assignedHotels = jsonDecode(jsonStr);
      
      final session = SessionData(
        userId: 1729,
        username: 'rou',
        assignedHotels: assignedHotels,
      );

      expect(session.assignedHotels!.length, 3);
      expect(session.assignedHotels![0]['name'], 'Hotel Dago SKY');
      expect(session.assignedHotels![1]['name'], 'Hotel Kurnia');
      expect(session.assignedHotels![2]['name'], 'Sentra Inn');
    });

    test('5 assigned hotels - parsing & validation', () {
      final jsonStr = jsonEncode([
        {'id': 1, 'code': 'abadi', 'name': 'Abadi Tasikmalaya'},
        {'id': 4, 'code': 'dagosky', 'name': 'Hotel Dago SKY'},
        {'id': 7, 'code': 'kurnia', 'name': 'Hotel Kurnia'},
        {'id': 14, 'code': 'sentra', 'name': 'Sentra Inn'},
        {'id': 15, 'code': 'siliwangi', 'name': 'Siliwangi GH'}
      ]);
      final List<dynamic> assignedHotels = jsonDecode(jsonStr);
      
      final session = SessionData(
        userId: 1729,
        username: 'rou',
        assignedHotels: assignedHotels,
      );

      expect(session.assignedHotels!.length, 5);
      
      // Check duplicate check
      final uniqueNames = session.assignedHotels!.map((h) => h['name']).toSet();
      expect(uniqueNames.length, 5);
    });

    test('10 assigned hotels - parsing & validation', () {
      final jsonStr = jsonEncode([
        {'id': 1, 'code': 'abadi', 'name': 'Abadi Tasikmalaya'},
        {'id': 2, 'code': 'alamanda', 'name': 'Alamanda Guesthouse'},
        {'id': 3, 'code': 'assalam', 'name': 'Assalam Syariah'},
        {'id': 4, 'code': 'dagosky', 'name': 'Hotel Dago SKY'},
        {'id': 5, 'code': 'gania', 'name': 'Gania Hotel'},
        {'id': 6, 'code': 'hotel10', 'name': 'Hotel 10 Buah Batu'},
        {'id': 7, 'code': 'kurnia', 'name': 'Hotel Kurnia'},
        {'id': 14, 'code': 'sentra', 'name': 'Sentra Inn'},
        {'id': 15, 'code': 'siliwangi', 'name': 'Siliwangi GH'},
        {'id': 19, 'code': 'hotel_a', 'name': 'Hotel Alpha'}
      ]);
      final List<dynamic> assignedHotels = jsonDecode(jsonStr);
      
      final session = SessionData(
        userId: 1729,
        username: 'rou',
        assignedHotels: assignedHotels,
      );

      expect(session.assignedHotels!.length, 10);
      expect(session.assignedHotels![9]['name'], 'Hotel Alpha');
    });
  });
}
