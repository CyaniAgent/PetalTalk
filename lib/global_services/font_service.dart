import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../core/logger.dart';

class FontService {
  static final FontService _instance = FontService._internal();
  factory FontService() => _instance;
  FontService._internal();

  final Dio _dio = Dio();

  // Font definitions: Name -> URL
  final Map<String, String> _fonts = {
    'MiSans': 'https://resources.imikufans.cn/d/CyaniAgent-E3/ResourceBank/Fonts/MiSans.ttf?sign=LdZWACN2cTdnMUosvWAv2BBJ27OzZj5MPm7s0OxJoxM=:0',
    'Star Rail Font': 'https://resources.imikufans.cn/d/CyaniAgent-E3/ResourceBank/Fonts/StarRailFont.ttf?sign=TsgWg_3qoHhuu2qd_XN9di-k-QP71vOdvzudxKYbEJk=:0',
    'Noto Sans': 'https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSans/NotoSans-Regular.ttf',
  };

  /// Initialize and load fonts
  Future<void> init() async {
    logger.info('Starting FontService initialization...');
    await Future.wait(_fonts.entries.map((entry) => _loadFont(entry.key, entry.value)));
    logger.info('FontService initialization complete.');
  }

  Future<void> _loadFont(String fontFamily, String url) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fontDir = Directory('${dir.path}/fonts');
      if (!await fontDir.exists()) {
        await fontDir.create(recursive: true);
      }

      final fileName = '${fontFamily.replaceAll(" ", "_")}.ttf';
      final file = File('${fontDir.path}/$fileName');

      Uint8List fontData;

      if (await file.exists()) {
        logger.debug('Loading cached font: $fontFamily from ${file.path}');
        fontData = await file.readAsBytes();
      } else {
        logger.info('Downloading font: $fontFamily from $url');
        final response = await _dio.get(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        
        if (response.statusCode == 200) {
          fontData = Uint8List.fromList(response.data);
          await file.writeAsBytes(fontData);
          logger.info('Font downloaded and cached: $fontFamily');
        } else {
          logger.error('Failed to download font $fontFamily: ${response.statusCode}');
          return;
        }
      }

      final fontLoader = FontLoader(fontFamily);
      fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
      await fontLoader.load();
      logger.info('Font loaded successfully: $fontFamily');

    } catch (e, stackTrace) {
      logger.error('Error loading font $fontFamily', e, stackTrace);
    }
  }
}
