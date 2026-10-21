import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Academic Calculation Tests', () {
    test('Attendance Predictor - Safe Zone Bunk Calculation', () {
      int attended = 16;
      int total = 20; // 80%
      int canMiss = ((attended / 0.75) - total).floor();
      expect(canMiss, 1);
    });

    test('Attendance Predictor - Catch-up Target Calculation', () {
      int attended = 10;
      int total = 20; // 50%
      int mustAttend = ((0.75 * total - attended) / 0.25).ceil();
      expect(mustAttend, 20);
    });

    test('Anna University GPA Calculation Logic', () {
      final courses = [
        {'credit': 4, 'grade': 10}, // O
        {'credit': 3, 'grade': 9},  // A+
        {'credit': 3, 'grade': 8},  // A
      ];
      int totalCredits = 0;
      double totalPoints = 0;
      for (var c in courses) {
        totalCredits += c['credit'] as int;
        totalPoints += (c['credit'] as int) * (c['grade'] as int);
      }
      double gpa = totalPoints / totalCredits;
      expect(gpa, closeTo(9.10, 0.01));
    });
  });
}

