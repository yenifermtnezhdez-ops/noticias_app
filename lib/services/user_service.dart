
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _phoneKeyPrefix = 'profile_phone_';
  Future<String> getPhone(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('$_phoneKeyPrefix$userId') ?? '';
  }
  Future<void> savePhone({
    required String userId,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      '$_phoneKeyPrefix$userId',
      phone.trim(),
    );
  }
  Future<String?> getProfileImagePath(String userId) async {
    final directory = await getApplicationDocumentsDirectory();

    final folder = Directory(directory.path);

    if (!await folder.exists()) {
      return null;
    }

    final prefix = 'profile_$userId.';

    await for (final entity in folder.list()) {
      if (entity is File &&
          entity.uri.pathSegments.last.startsWith(prefix)) {
        if (await entity.exists()) {
          return entity.path;
        }
      }
    }

    return null;
  }
  Future<String> saveProfileImage({
    required String userId,
    required XFile image,
  }) async {
    final sourceFile = File(image.path);

    // Comprueba que la imagen exista.
    if (!await sourceFile.exists()) {
      throw Exception('La imagen seleccionada no existe.');
    }
    final fileSize = await sourceFile.length();

    if (fileSize == 0) {
      throw Exception('La imagen seleccionada está vacía.');
    }
    final sourcePath = image.path;
    final dotIndex = sourcePath.lastIndexOf('.');
    final separatorIndex = sourcePath.lastIndexOf(
      Platform.pathSeparator,
    );

    String extension = '.jpg';

    if (dotIndex > separatorIndex) {
      final candidate = sourcePath.substring(dotIndex).toLowerCase();

      const allowedExtensions = [
        '.jpg',
        '.jpeg',
        '.png',
        '.webp',
        '.heic',
      ];

      if (allowedExtensions.contains(candidate)) {
        extension = candidate;
      }
    }

    final directory = await getApplicationDocumentsDirectory();

    final destinationPath =
        '${directory.path}/profile_$userId$extension';

    final destinationFile = File(destinationPath);
    await sourceFile.copy(destinationFile.path);
    if (!await destinationFile.exists() ||
        await destinationFile.length() == 0) {
      throw Exception('No fue posible guardar la fotografía.');
    }
    await for (final entity in Directory(directory.path).list()) {
      if (entity is File &&
          entity.path != destinationFile.path &&
          entity.uri.pathSegments.last.startsWith(
            'profile_$userId.',
          )) {
        await entity.delete();
      }
    }

    return destinationFile.path;
  }
  Future<void> deleteLocalProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('$_phoneKeyPrefix$userId');

    final directory = await getApplicationDocumentsDirectory();

    final folder = Directory(directory.path);

    if (!await folder.exists()) return;
    await for (final entity in folder.list()) {
      if (entity is File &&
          entity.uri.pathSegments.last.startsWith(
            'profile_$userId.',
          )) {
        await entity.delete();
      }
    }
  }
}
