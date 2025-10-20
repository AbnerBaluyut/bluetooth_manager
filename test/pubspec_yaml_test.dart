import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('pubspec.yaml validation', () {
    late File pubspecFile;
    late YamlMap pubspecContent;

    setUpAll(() {
      // Load the pubspec.yaml file
      pubspecFile = File('pubspec.yaml');
      final yamlString = pubspecFile.readAsStringSync();
      pubspecContent = loadYaml(yamlString) as YamlMap;
    });

    test('pubspec.yaml file exists', () {
      expect(pubspecFile.existsSync(), isTrue,
          reason: 'pubspec.yaml must exist in the project root');
    });

    test('pubspec.yaml is valid YAML', () {
      expect(() {
        final yamlString = pubspecFile.readAsStringSync();
        loadYaml(yamlString);
      }, returnsNormally,
          reason: 'pubspec.yaml must be valid YAML syntax');
    });

    group('Required fields validation', () {
      test('has name field', () {
        expect(pubspecContent.containsKey('name'), isTrue,
            reason: 'pubspec.yaml must have a name field');
        expect(pubspecContent['name'], isNotNull);
        expect(pubspecContent['name'], isNotEmpty);
      });

      test('name is "bluetooth_manager"', () {
        expect(pubspecContent['name'], equals('bluetooth_manager'),
            reason: 'Package name should be bluetooth_manager');
      });

      test('has description field', () {
        expect(pubspecContent.containsKey('description'), isTrue,
            reason: 'pubspec.yaml must have a description field');
        expect(pubspecContent['description'], isNotNull);
        expect(pubspecContent['description'], isNotEmpty);
      });

      test('has version field', () {
        expect(pubspecContent.containsKey('version'), isTrue,
            reason: 'pubspec.yaml must have a version field');
        expect(pubspecContent['version'], isNotNull);
      });

      test('version follows semantic versioning', () {
        final version = pubspecContent['version'].toString();
        final semverRegex = RegExp(r'^\d+\.\d+\.\d+(-[a-zA-Z0-9\-\.]+)?(\+[a-zA-Z0-9\-\.]+)?$');
        expect(semverRegex.hasMatch(version), isTrue,
            reason: 'Version must follow semantic versioning (MAJOR.MINOR.PATCH)');
      });

      test('has environment field', () {
        expect(pubspecContent.containsKey('environment'), isTrue,
            reason: 'pubspec.yaml must have an environment field');
        expect(pubspecContent['environment'], isNotNull);
      });
    });

    group('Environment constraints validation', () {
      late YamlMap environment;

      setUp(() {
        environment = pubspecContent['environment'] as YamlMap;
      });

      test('has Dart SDK constraint', () {
        expect(environment.containsKey('sdk'), isTrue,
            reason: 'Environment must specify Dart SDK constraint');
        expect(environment['sdk'], isNotNull);
      });

      test('Dart SDK constraint is valid', () {
        final sdkConstraint = environment['sdk'].toString();
        // Should start with ^ or >= or contain a range
        expect(
            sdkConstraint.startsWith('^') ||
                sdkConstraint.startsWith('>=') ||
                sdkConstraint.contains(' '),
            isTrue,
            reason: 'SDK constraint should use valid version syntax');
      });

      test('Dart SDK version is 3.7.0 or higher', () {
        final sdkConstraint = environment['sdk'].toString();
        expect(sdkConstraint, contains('3.7.0'),
            reason: 'Project requires Dart SDK 3.7.0');
      });

      test('has Flutter SDK constraint', () {
        expect(environment.containsKey('flutter'), isTrue,
            reason: 'Flutter package must specify Flutter SDK constraint');
        expect(environment['flutter'], isNotNull);
      });

      test('Flutter SDK constraint is valid', () {
        final flutterConstraint = environment['flutter'].toString();
        expect(flutterConstraint, isNotEmpty,
            reason: 'Flutter constraint must not be empty');
      });
    });

    group('Dependencies validation', () {
      late YamlMap dependencies;

      setUp(() {
        dependencies = pubspecContent['dependencies'] as YamlMap;
      });

      test('has dependencies field', () {
        expect(pubspecContent.containsKey('dependencies'), isTrue,
            reason: 'pubspec.yaml must have dependencies field');
        expect(dependencies, isNotNull);
      });

      test('includes flutter SDK dependency', () {
        expect(dependencies.containsKey('flutter'), isTrue,
            reason: 'Flutter package must depend on flutter SDK');
        final flutterDep = dependencies['flutter'];
        expect(flutterDep, isA<YamlMap>());
        expect((flutterDep as YamlMap)['sdk'], equals('flutter'));
      });

      test('includes device_info_plus dependency', () {
        expect(dependencies.containsKey('device_info_plus'), isTrue,
            reason: 'Package requires device_info_plus for device information');
        expect(dependencies['device_info_plus'], isNotNull);
      });

      test('device_info_plus version is 12.1.0 or higher', () {
        final version = dependencies['device_info_plus'].toString();
        expect(version, contains('12.'),
            reason: 'device_info_plus should be version 12.x or higher');
        
        // Verify it's at least 12.1.0
        if (version.startsWith('^')) {
          final versionNumber = version.substring(1);
          final parts = versionNumber.split('.');
          expect(int.parse(parts[0]), greaterThanOrEqualTo(12),
              reason: 'Major version should be at least 12');
          if (int.parse(parts[0]) == 12) {
            expect(int.parse(parts[1]), greaterThanOrEqualTo(1),
                reason: 'Minor version should be at least 1 when major is 12');
          }
        }
      });

      test('includes permission_handler dependency', () {
        expect(dependencies.containsKey('permission_handler'), isTrue,
            reason: 'Package requires permission_handler for permission management');
        expect(dependencies['permission_handler'], isNotNull);
      });

      test('permission_handler version constraint is valid', () {
        final version = dependencies['permission_handler'].toString();
        expect(version, matches(r'^\^?\d+\.\d+\.\d+'),
            reason: 'permission_handler version should be a valid semantic version');
      });

      test('includes flutter_reactive_ble dependency', () {
        expect(dependencies.containsKey('flutter_reactive_ble'), isTrue,
            reason: 'Package requires flutter_reactive_ble for BLE functionality');
        expect(dependencies['flutter_reactive_ble'], isNotNull);
      });

      test('flutter_reactive_ble version constraint is valid', () {
        final version = dependencies['flutter_reactive_ble'].toString();
        expect(version, matches(r'^\^?\d+\.\d+\.\d+'),
            reason: 'flutter_reactive_ble version should be a valid semantic version');
      });

      test('all version constraints use caret syntax or exact versions', () {
        dependencies.forEach((key, value) {
          if (value is String) {
            expect(
                value.startsWith('^') ||
                    RegExp(r'^\d+\.\d+\.\d+$').hasMatch(value) ||
                    value.startsWith('>='),
                isTrue,
                reason: 'Version constraint for $key should use ^, exact version, or >=');
          }
        });
      });

      test('no dependencies use git references', () {
        dependencies.forEach((key, value) {
          if (value is YamlMap) {
            if (key.toString() != 'flutter') {
              expect(value.containsKey('git'), isFalse,
                  reason: 'Dependency $key should not use git reference in published package');
            }
          }
        });
      });
    });

    group('Dev dependencies validation', () {
      late YamlMap devDependencies;

      setUp(() {
        devDependencies = pubspecContent['dev_dependencies'] as YamlMap;
      });

      test('has dev_dependencies field', () {
        expect(pubspecContent.containsKey('dev_dependencies'), isTrue,
            reason: 'pubspec.yaml should have dev_dependencies field');
        expect(devDependencies, isNotNull);
      });

      test('includes flutter_test dependency', () {
        expect(devDependencies.containsKey('flutter_test'), isTrue,
            reason: 'Package should include flutter_test for testing');
        final flutterTest = devDependencies['flutter_test'];
        expect(flutterTest, isA<YamlMap>());
        expect((flutterTest as YamlMap)['sdk'], equals('flutter'));
      });

      test('includes flutter_lints dependency', () {
        expect(devDependencies.containsKey('flutter_lints'), isTrue,
            reason: 'Package should include flutter_lints for code quality');
        expect(devDependencies['flutter_lints'], isNotNull);
      });

      test('flutter_lints version is appropriate', () {
        final version = devDependencies['flutter_lints'].toString();
        expect(version, matches(r'^\^?\d+\.\d+\.\d+'),
            reason: 'flutter_lints version should be a valid semantic version');
      });
    });

    group('Dependency version compatibility', () {
      test('device_info_plus and permission_handler versions are compatible', () {
        final dependencies = pubspecContent['dependencies'] as YamlMap;
        final deviceInfoVersion = dependencies['device_info_plus'].toString();
        final permissionHandlerVersion = dependencies['permission_handler'].toString();
        
        // Both should be recent versions
        expect(deviceInfoVersion, isNotEmpty);
        expect(permissionHandlerVersion, isNotEmpty);
        
        // Verify both use caret syntax (recommended for pub packages)
        expect(deviceInfoVersion.startsWith('^'), isTrue,
            reason: 'device_info_plus should use caret syntax for version');
        expect(permissionHandlerVersion.startsWith('^'), isTrue,
            reason: 'permission_handler should use caret syntax for version');
      });

      test('all dependencies have version constraints', () {
        final dependencies = pubspecContent['dependencies'] as YamlMap;
        dependencies.forEach((key, value) {
          if (value is String) {
            expect(value, isNotEmpty,
                reason: 'Dependency $key must have a version constraint');
          } else if (value is YamlMap && !value.containsKey('sdk')) {
            expect(
                value.containsKey('version') ||
                    value.containsKey('git') ||
                    value.containsKey('path'),
                isTrue,
                reason: 'Dependency $key must have a version or source specification');
          }
        });
      });
    });

    group('Package structure validation', () {
      test('has flutter section', () {
        expect(pubspecContent.containsKey('flutter'), isTrue,
            reason: 'Flutter package should have a flutter section');
      });

      test('description is meaningful', () {
        final description = pubspecContent['description'].toString();
        expect(description.length, greaterThan(10),
            reason: 'Description should be meaningful and descriptive');
      });

      test('version is not 0.0.0', () {
        final version = pubspecContent['version'].toString();
        expect(version, isNot(equals('0.0.0')),
            reason: 'Package version should be properly set');
      });
    });

    group('Specific version requirements', () {
      test('device_info_plus is at minimum version 12.1.0', () {
        final dependencies = pubspecContent['dependencies'] as YamlMap;
        final version = dependencies['device_info_plus'].toString();
        
        // Remove caret and parse version
        final versionString = version.replaceFirst('^', '');
        final parts = versionString.split('.');
        
        final major = int.parse(parts[0]);
        final minor = int.parse(parts[1]);
        
        expect(major, greaterThanOrEqualTo(12),
            reason: 'device_info_plus major version must be at least 12');
        
        if (major == 12) {
          expect(minor, greaterThanOrEqualTo(1),
              reason: 'device_info_plus minor version must be at least 1 for version 12.x');
        }
      });

      test('permission_handler is at minimum version 12.0.0', () {
        final dependencies = pubspecContent['dependencies'] as YamlMap;
        final version = dependencies['permission_handler'].toString();
        
        // Remove caret and parse version
        final versionString = version.replaceFirst('^', '');
        final parts = versionString.split('.');
        
        final major = int.parse(parts[0]);
        
        expect(major, greaterThanOrEqualTo(12),
            reason: 'permission_handler major version must be at least 12');
      });

      test('flutter_reactive_ble is at minimum version 5.4.0', () {
        final dependencies = pubspecContent['dependencies'] as YamlMap;
        final version = dependencies['flutter_reactive_ble'].toString();
        
        // Remove caret and parse version
        final versionString = version.replaceFirst('^', '');
        final parts = versionString.split('.');
        
        final major = int.parse(parts[0]);
        final minor = int.parse(parts[1]);
        
        expect(major, greaterThanOrEqualTo(5),
            reason: 'flutter_reactive_ble major version must be at least 5');
        
        if (major == 5) {
          expect(minor, greaterThanOrEqualTo(4),
              reason: 'flutter_reactive_ble minor version must be at least 4 for version 5.x');
        }
      });
    });

    group('YAML format and structure', () {
      test('file is properly formatted with correct indentation', () {
        final yamlString = pubspecFile.readAsStringSync();
        final lines = yamlString.split('\n');
        
        // Check that indentation is consistent (2 spaces)
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trim().isEmpty || line.trim().startsWith('#')) {
            continue;
          }
          
          // Count leading spaces
          final leadingSpaces = line.length - line.trimLeft().length;
          
          // Should be a multiple of 2
          if (leadingSpaces > 0) {
            expect(leadingSpaces % 2, equals(0),
                reason: 'Line ${i + 1} should use 2-space indentation (found $leadingSpaces spaces)');
          }
        }
      });

      test('no trailing whitespace on lines', () {
        final yamlString = pubspecFile.readAsStringSync();
        final lines = yamlString.split('\n');
        
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.isNotEmpty && line != line.trimRight()) {
            fail('Line ${i + 1} has trailing whitespace');
          }
        }
      });

      test('file ends with newline', () {
        final yamlString = pubspecFile.readAsStringSync();
        expect(yamlString.endsWith('\n'), isTrue,
            reason: 'pubspec.yaml should end with a newline');
      });
    });

    group('Edge cases and error handling', () {
      test('can parse pubspec.yaml multiple times without errors', () {
        for (var i = 0; i < 5; i++) {
          expect(() {
            final yamlString = pubspecFile.readAsStringSync();
            loadYaml(yamlString);
          }, returnsNormally,
              reason: 'pubspec.yaml should be consistently parseable');
        }
      });

      test('has no duplicate keys', () {
        final yamlString = pubspecFile.readAsStringSync();
        final lines = yamlString.split('\n');
        final topLevelKeys = <String>[];
        
        for (final line in lines) {
          if (line.trim().isEmpty || line.trim().startsWith('#')) {
            continue;
          }
          
          // Check if it's a top-level key (no leading spaces and contains ':')
          if (!line.startsWith(' ') && line.contains(':')) {
            final key = line.split(':')[0].trim();
            if (topLevelKeys.contains(key)) {
              fail('Duplicate top-level key found: $key');
            }
            topLevelKeys.add(key);
          }
        }
      });

      test('version numbers do not contain invalid characters', () {
        final dependencies = pubspecContent['dependencies'] as YamlMap;
        final devDependencies = pubspecContent['dev_dependencies'] as YamlMap;
        
        final allDeps = {...dependencies, ...devDependencies};
        
        allDeps.forEach((key, value) {
          if (value is String) {
            // Should only contain numbers, dots, caret, plus, minus, and letters
            expect(
                value,
                matches(r'^[\^>=<\d\.\+\-a-zA-Z\s]+$'),
                reason: 'Version for $key contains invalid characters');
          }
        });
      });

      test('no circular dependencies exist', () {
        final dependencies = pubspecContent['dependencies'] as YamlMap;
        
        // Make sure the package doesn't depend on itself
        dependencies.forEach((key, value) {
          expect(key.toString(), isNot(equals('bluetooth_manager')),
              reason: 'Package should not depend on itself');
        });
      });
    });

    group('Security and best practices', () {
      test('no path dependencies in production', () {
        final dependencies = pubspecContent['dependencies'] as YamlMap;
        
        dependencies.forEach((key, value) {
          if (value is YamlMap) {
            expect(value.containsKey('path'), isFalse,
                reason: 'Dependency $key should not use path reference in published package');
          }
        });
      });

      test('uses HTTPS for any external references', () {
        final yamlString = pubspecFile.readAsStringSync();
        
        // Check if there are any HTTP URLs (not HTTPS)
        final httpUrls = RegExp(r'http://[^\s]+');
        final matches = httpUrls.allMatches(yamlString);
        
        for (final match in matches) {
          final url = match.group(0);
          // Localhost is acceptable
          if (!url!.contains('localhost') && !url.contains('127.0.0.1')) {
            fail('Found insecure HTTP URL: $url. Use HTTPS instead.');
          }
        }
      });

      test('version constraints allow for patch updates', () {
        final dependencies = pubspecContent['dependencies'] as YamlMap;
        
        dependencies.forEach((key, value) {
          if (value is String && value.contains('^')) {
            // Caret allows for minor and patch updates, which is good
            expect(true, isTrue);
          } else if (value is String && !value.contains('>=') && !value.contains('sdk')) {
            // Exact versions are too restrictive
            if (RegExp(r'^\d+\.\d+\.\d+$').hasMatch(value)) {
              fail('Dependency $key uses exact version ($value). Consider using caret (^) for flexibility.');
            }
          }
        });
      });
    });

    group('Metadata completeness', () {
      test('has all recommended metadata fields', () {
        final recommendedFields = ['name', 'description', 'version', 'homepage'];
        
        for (final field in recommendedFields) {
          expect(pubspecContent.containsKey(field), isTrue,
              reason: 'pubspec.yaml should have $field field for completeness');
        }
      });

      test('version follows semantic versioning with all three parts', () {
        final version = pubspecContent['version'].toString();
        final parts = version.split('.');
        
        expect(parts.length, greaterThanOrEqualTo(3),
            reason: 'Version should have MAJOR.MINOR.PATCH format');
        
        for (var i = 0; i < 3; i++) {
          expect(int.tryParse(parts[i].split('-')[0].split('+')[0]), isNotNull,
              reason: 'Version part ${i + 1} should be a number');
        }
      });
    });
  });
}