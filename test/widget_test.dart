import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/models/season.dart';
import 'package:univ_tiaret/models/module.dart';
import 'package:univ_tiaret/models/semester.dart';
import 'package:univ_tiaret/models/activity.dart';
import 'package:univ_tiaret/models/lesson_file.dart';
import 'package:univ_tiaret/models/user_model.dart';
import 'package:univ_tiaret/models/favorite_file.dart';
import 'package:univ_tiaret/models/reminder.dart';
import 'package:univ_tiaret/services/api_service.dart';

void main() {
  group('AppColors', () {
    test('primary color is correct', () {
      expect(AppColors.primary, const Color(0xFF125488));
    });

    test('secondary color is correct', () {
      expect(AppColors.secondaryColor, const Color(0xFF2A93D5));
    });
  });

  group('Constants', () {
    test('default padding is 16', () {
      expect(defaultPadding, 16.0);
    });
  });

  group('ApiService', () {
    test('base URL starts empty until configured', () {
      expect(ApiService.baseUrl, '');
    });

    test('initialize uses exactly what was provided', () {
      ApiService.initialize('http://my-server:8080');
      expect(ApiService.baseUrl, 'http://my-server:8080');
    });
  });

  group('Validators', () {
    test('passwordValidator returns error for short password', () {
      final validator = passwordValidator(
        'required', 'min 8', 'need upper', 'need lower', 'need number', 'need special',
      );
      final result = validator('Ab1!');
      expect(result, isNotNull);
    });

    test('emailValidator returns error for invalid email', () {
      final validator = emailValidator('required', 'invalid');
      final result = validator('not-an-email');
      expect(result, isNotNull);
    });

    test('emailValidator returns null for valid email', () {
      final validator = emailValidator('required', 'invalid');
      final result = validator('test@example.com');
      expect(result, isNull);
    });
  });

  group('Season model', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'name': '2024/2025',
        'is_current': true,
      };
      final season = Season.fromJson(json);
      expect(season.id, 1);
      expect(season.name, '2024/2025');
      expect(season.isCurrent, true);
    });

    test('toJson serializes correctly', () {
      final season = Season(
        id: 1,
        name: '2024/2025',
        isCurrent: true,
      );
      final json = season.toJson();
      expect(json['id'], 1);
      expect(json['name'], '2024/2025');
      expect(json['is_current'], true);
    });
  });

  group('Semester model', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'name': 'Semester 1',
        'level_id': 2,
        'is_current': true,
      };
      final semester = Semester.fromJson(json);
      expect(semester.id, 1);
      expect(semester.name, 'Semester 1');
      expect(semester.levelId, 2);
      expect(semester.isCurrent, true);
    });
  });

  group('Module model', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'name': 'Mathematics',
        'code': 'MATH101',
        'coefficient': 3,
        'credit': 6,
        'semesters': {'id': 1, 'name': 'Semester 1'},
      };
      final module = Module.fromJson(json);
      expect(module.id, 1);
      expect(module.name, 'Mathematics');
      expect(module.coefficient, '3');
      expect(module.credit, 6);
      expect(module.semester.id, 1);
    });
  });

  group('Activity model', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'name': 'Course',
      };
      final activity = Activity.fromJson(json);
      expect(activity.id, 1);
      expect(activity.name, 'Course');
    });
  });

  group('LessonFile model', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'name': 'Chapter 1',
        'description': 'Introduction',
        'url': 'http://example.com/ch1.pdf',
        'file_type': 'pdf',
        'module_id': 1,
        'activity_type_id': 1,
        'activity_type': 'Course',
        'season_id': 1,
        'uploaded_at': '2025-01-01',
      };
      final file = LessonFile.fromJson(json);
      expect(file.id, 1);
      expect(file.name, 'Chapter 1');
      expect(file.fileType, 'pdf');
      expect(file.url, 'http://example.com/ch1.pdf');
      expect(file.moduleId, 1);
    });

    test('fileIcon returns correct icon for pdf', () {
      final json = {
        'id': 1,
        'name': 'doc',
        'description': '',
        'url': '',
        'file_type': 'pdf',
        'module_id': 1,
        'activity_type_id': 1,
        'activity_type': '',
        'season_id': 1,
        'uploaded_at': '',
      };
      final file = LessonFile.fromJson(json);
      expect(file.fileIcon, 'pdf');
    });

    test('fileIcon returns image for jpg', () {
      final json = {
        'id': 2,
        'name': 'img',
        'description': '',
        'url': '',
        'file_type': 'jpg',
        'module_id': 1,
        'activity_type_id': 1,
        'activity_type': '',
        'season_id': 1,
        'uploaded_at': '',
      };
      final file = LessonFile.fromJson(json);
      expect(file.fileIcon, 'image');
    });
  });

  group('UserModel', () {
    test('fromJson parses flat structure correctly', () {
      final json = {
        'id': 1,
        'email': 'john@example.com',
        'first_name': 'John',
        'last_name': 'Doe',
        'gender': 'Male',
        'status': 'active',
        'roles': ['student'],
      };
      final user = UserModel.fromJson(json);
      expect(user.id, 1);
      expect(user.firstName, 'John');
      expect(user.email, 'john@example.com');
      expect(user.status, 'active');
    });

    test('fromJson parses nested profile structure correctly', () {
      final json = {
        'id': 1,
        'email': 'john@example.com',
        'profile': {
          'first_name': 'John',
          'last_name': 'Doe',
          'gender': 'Male',
          'student_id': 'STU123',
          'level': {'id': 1, 'name': 'L3'},
          'speciality': {'id': 2, 'name': 'CS'},
        },
        'roles': ['student'],
      };
      final user = UserModel.fromJson(json);
      expect(user.firstName, 'John');
      expect(user.studentId, 'STU123');
      expect(user.levelId, 1);
      expect(user.levelName, 'L3');
      expect(user.specialityId, 2);
      expect(user.specialityName, 'CS');
    });
  });

  group('FavoriteFile model', () {
    test('fromDb parses correctly', () {
      final row = {
        'id': 1,
        'file_id': 42,
        'file_name': 'Chapter 1',
        'file_type': 'pdf',
        'file_url': 'http://localhost/file.pdf',
        'module_id': 1,
        'module_name': 'Math',
        'season_id': 1,
        'season_name': '2024/2025',
        'semester_name': 'S1',
        'activity_type_id': 1,
        'activity_name': 'Course',
        'created_at': '2025-01-10',
      };
      final fav = FavoriteFile.fromDb(row);
      expect(fav.id, 1);
      expect(fav.fileId, 42);
      expect(fav.fileName, 'Chapter 1');
      expect(fav.moduleName, 'Math');
    });

    test('toDb serializes correctly', () {
      final fav = FavoriteFile(
        fileId: 42,
        fileName: 'Chapter 1',
        fileType: 'pdf',
        fileUrl: 'http://localhost/file.pdf',
        moduleId: 1,
        moduleName: 'Math',
        seasonId: 1,
        seasonName: '2024/2025',
        semesterName: 'S1',
        activityTypeId: 1,
        activityName: 'Course',
        createdAt: '2025-01-10',
      );
      final db = fav.toDb();
      expect(db['file_id'], 42);
      expect(db['file_name'], 'Chapter 1');
      expect(db['module_name'], 'Math');
    });
  });

  group('Reminder model', () {
    test('fromDb parses correctly', () {
      final row = {
        'id': 1,
        'title': 'Study Math',
        'description': 'Review chapter 5',
        'date_time': '2025-01-15 10:00:00.000',
        'created_at': '2025-01-10 08:00:00.000',
      };
      final reminder = Reminder.fromDb(row);
      expect(reminder.id, 1);
      expect(reminder.title, 'Study Math');
      expect(reminder.description, 'Review chapter 5');
    });

    test('toDb serializes correctly', () {
      final reminder = Reminder(
        title: 'Study Math',
        description: 'Review chapter 5',
        dateTime: '2025-01-15 10:00:00.000',
        createdAt: '2025-01-10 08:00:00.000',
      );
      final db = reminder.toDb();
      expect(db['title'], 'Study Math');
      expect(db['description'], 'Review chapter 5');
    });
  });
}