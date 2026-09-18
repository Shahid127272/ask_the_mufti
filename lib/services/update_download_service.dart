import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class UpdateDownloadService {
  static const String apkFileName = 'ask_the_mufti_update.apk';

  final Dio _dio = Dio();

  Future<String> downloadUpdate({
    required String downloadUrl,
    required void Function(int received, int total) onProgress,
  }) async {
    final Directory directory = await getTemporaryDirectory();

    final String filePath = '${directory.path}/$apkFileName';

    final File apkFile = File(filePath);

    if (await apkFile.exists()) {
      await apkFile.delete();
    }

    await _dio.download(
      downloadUrl,
      filePath,
      onReceiveProgress: onProgress,
      options: Options(
        followRedirects: true,
        responseType: ResponseType.bytes,
        validateStatus: (status) {
          return status != null && status >= 200 && status < 400;
        },
      ),
    );

    if (!await apkFile.exists()) {
      throw Exception('APK download failed.');
    }

    final int fileSize = await apkFile.length();

    if (fileSize <= 0) {
      throw Exception('Downloaded APK is empty.');
    }

    return filePath;
  }

  Future<bool> installUpdate(String filePath) async {
    final result = await OpenFilex.open(
      filePath,
      type: 'application/vnd.android.package-archive',
    );

    return result.type == ResultType.done;
  }
}