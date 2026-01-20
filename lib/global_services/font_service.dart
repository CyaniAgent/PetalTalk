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

  // Public getter for fonts map
  Map<String, String> get supportedFonts => _fonts;

  // Font definitions: Name -> URL
  final Map<String, String> _fonts = {
    'MiSans':
        'https://resources.imikufans.cn/d/CyaniAgent-E3/ResourceBank/Fonts/MiSans.ttf?sign=LdZWACN2cTdnMUosvWAv2BBJ27OzZj5MPm7s0OxJoxM=:0',
    'Star Rail Font':
        'https://resources.imikufans.cn/d/CyaniAgent-E3/ResourceBank/Fonts/StarRailFont.ttf?sign=TsgWg_3qoHhuu2qd_XN9di-k-QP71vOdvzudxKYbEJk=:0',
    'Noto Sans':
        'https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSans/NotoSans-Regular.ttf',
  };

  /// Initialize and load cached fonts
  Future<void> init() async {
    logger.info('Starting FontService initialization...');
    await _loadCachedFonts();
    logger.info('FontService initialization complete.');
  }

  /// Check if a specific font is already cached
  Future<bool> isFontCached(String fontFamily) async {
    if (!_fonts.containsKey(fontFamily)) return false;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fontDir = Directory('${dir.path}/fonts');
      final fileName = '${fontFamily.replaceAll(" ", "_")}.ttf';
      final file = File('${fontDir.path}/$fileName');
      return await file.exists();
    } catch (e) {
      logger.error('Error checking font cache status: $fontFamily', e);
      return false;
    }
  }

  /// Download a specific font
  Future<void> downloadFont(
    String fontFamily, {
    Function(int, int)? onReceiveProgress,
  }) async {
    if (!_fonts.containsKey(fontFamily)) {
      throw Exception('Font $fontFamily not supported');
    }

    final url = _fonts[fontFamily]!;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fontDir = Directory('${dir.path}/fonts');
      if (!await fontDir.exists()) {
        await fontDir.create(recursive: true);
      }

      final fileName = '${fontFamily.replaceAll(" ", "_")}.ttf';
      final file = File('${fontDir.path}/$fileName');

      logger.info('Downloading font: $fontFamily from $url');
      await _dio.download(url, file.path, onReceiveProgress: onReceiveProgress);

      logger.info('Font downloaded and cached: $fontFamily');

      // Load the font immediately after download
      await _loadSingleFont(fontFamily, file);
    } catch (e, stackTrace) {
      logger.error('Error downloading font $fontFamily', e, stackTrace);
      rethrow;
    }
  }

  /// Load all fonts that are already cached
  Future<void> _loadCachedFonts() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fontDir = Directory('${dir.path}/fonts');
      if (!await fontDir.exists()) return;

      for (final entry in _fonts.entries) {
        final fontFamily = entry.key;
        final fileName = '${fontFamily.replaceAll(" ", "_")}.ttf';
        final file = File('${fontDir.path}/$fileName');

        if (await file.exists()) {
          await _loadSingleFont(fontFamily, file);
        }
      }
    } catch (e, stackTrace) {
      logger.error('Error loading cached fonts', e, stackTrace);
    }
  }

  /// Load a single font from file
  Future<void> _loadSingleFont(String fontFamily, File file) async {
    try {
      final fontData = await file.readAsBytes();
      final fontLoader = FontLoader(fontFamily);
      fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
      await fontLoader.load();
      logger.info('Font loaded successfully: $fontFamily');
    } catch (e) {
      logger.error('Error loading font file for $fontFamily', e);
    }
  }
}
