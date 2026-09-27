import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Keeps the pictures a user picked for their lists.
///
/// The picked file is copied into the app's own support directory: a path
/// handed over by the gallery or by a macOS open-panel is only readable for
/// that moment, so pointing a list at it would break on the next launch.
class BackgroundStore {
  BackgroundStore._();

  static final BackgroundStore instance = BackgroundStore._();

  late final Directory _directory;

  Future<void> init() async {
    final Directory support = await getApplicationSupportDirectory();
    _directory = Directory('${support.path}/backgrounds');
    if (!_directory.existsSync()) {
      _directory.createSync(recursive: true);
    }
  }

  String pathOf(String fileName) => '${_directory.path}/$fileName';

  /// Copies [sourcePath] into the store and returns the stored file name.
  Future<String> import(String sourcePath) async {
    final int dot = sourcePath.lastIndexOf('.');
    final String extension =
        dot == -1 ? '.jpg' : sourcePath.substring(dot).toLowerCase();
    final String fileName =
        'bg_${DateTime.now().microsecondsSinceEpoch}$extension';
    await File(sourcePath).copy(pathOf(fileName));
    return fileName;
  }

  void remove(String fileName) {
    final File file = File(pathOf(fileName));
    if (file.existsSync()) file.deleteSync();
  }
}

/// Asks the platform for a picture: the photo gallery on phones, the regular
/// open dialog on desktop. Returns the path of the chosen file, or null.
Future<String?> pickBackgroundImage() async {
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android) {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // Downscale on the way in: a 12MP phone photo is far more than any
      // screen needs, and the copy would sit in app storage forever.
      maxWidth: 2560,
      maxHeight: 2560,
      imageQuality: 88,
    );
    return picked?.path;
  }

  const XTypeGroup images = XTypeGroup(
    label: 'Images',
    extensions: <String>['jpg', 'jpeg', 'png', 'heic', 'webp'],
  );
  final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[images]);
  return file?.path;
}
