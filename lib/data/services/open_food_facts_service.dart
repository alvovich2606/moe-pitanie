import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/app_logger.dart';
import '../models/food_item.dart';
import 'built_in_food_catalog.dart';

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}

class OpenFoodFactsService {
  final http.Client _client;
  final Map<String, List<FoodItem>> _searchCache = {};

  static const String _userAgent =
      'MoePitanieAndroid/1.0 (ru.novikov.kbzhu_diary)';
  static const Duration _singleRequestTimeout = Duration(milliseconds: 3500);
  static const Duration _totalRetryWindow = Duration(seconds: 8);
  static const int _maxAttempts = 4;
  static const int maxResultsLimit = 50;

  static const List<String> _hosts = [
    'ru.openfoodfacts.org',
    'world.openfoodfacts.org',
  ];

  // Украинские буквы кириллицы (Є, є, І, і, Ї, ї, Ґ, ґ), латинская i не затрагивается
  static final RegExp _ukrainianLettersRegex =
      RegExp(r'[\u0404\u0454\u0406\u0456\u0407\u0457\u0490\u0491]');

  OpenFoodFactsService({http.Client? client})
      : _client = client ?? http.Client();

  bool _isRetryableStatus(int statusCode) {
    return statusCode == 429 ||
        statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  static List<String> _extractCountriesTags(Map<String, dynamic> raw) {
    final tags = raw['countries_tags'];
    if (tags is List) {
      return tags.map((e) => e.toString().toLowerCase()).toList();
    }
    return const [];
  }

  static bool _shouldExcludeProduct(
    Map<String, dynamic> raw,
    FoodItem item,
    List<String> countriesTags,
  ) {
    if (_ukrainianLettersRegex.hasMatch(item.name)) {
      return true;
    }
    if (item.brand != null && _ukrainianLettersRegex.hasMatch(item.brand!)) {
      return true;
    }

    final rawNameRu = (raw['product_name_ru'] as String?) ?? '';
    final rawName = (raw['product_name'] as String?) ?? '';
    if (_ukrainianLettersRegex.hasMatch(rawNameRu) ||
        _ukrainianLettersRegex.hasMatch(rawName)) {
      return true;
    }

    final hasUkraine = countriesTags.any(
      (t) => t.contains('ukraine') || t.contains('україна'),
    );
    final hasRussia = countriesTags.any(
      (t) => t.contains('russia') || t.contains('россия'),
    );

    if (hasUkraine && !hasRussia) {
      return true;
    }

    return false;
  }

  static List<String> extractStems(String query) {
    return query
        .toLowerCase()
        .replaceAll('ё', 'е')
        .split(RegExp(r'[\s,.\-()"/]+'))
        .where((w) => w.length >= 2)
        .map((w) {
          if (w.length <= 4) return w;
          final cut = w.length - 2;
          return w.substring(0, cut < 4 ? 4 : cut);
        })
        .toList();
  }

  static int relevanceScore(
    String productName,
    String rawQuery, {
    bool isRussia = false,
  }) {
    final name = productName.toLowerCase().replaceAll('ё', 'е').trim();
    final query = rawQuery.toLowerCase().replaceAll('ё', 'е').trim();
    if (query.isEmpty) return 0;

    final stems = extractStems(query);
    int matchedStems = 0;
    for (final stem in stems) {
      if (name.contains(stem)) {
        matchedStems++;
      }
    }

    int score = 0;

    if (name == query) {
      score += 2000;
    } else if (name.startsWith('$query ') ||
        name.startsWith('$query,') ||
        name.startsWith(query)) {
      score += 1200;
    } else if (name.contains(query)) {
      score += 800;
    }

    if (stems.isNotEmpty) {
      if (matchedStems == stems.length) {
        score += 600;
      } else if (matchedStems > 0) {
        score += matchedStems * 220;
      } else {
        score -= 800;
      }
    }

    if (isRussia) {
      score += 400;
    }

    score -= name.length * 3;

    return score;
  }

  Future<http.Response> _getWithRetry(
    String path,
    Map<String, String> queryParams,
  ) async {
    final stopwatch = Stopwatch()..start();
    var attempt = 0;
    ApiException? lastException;

    while (attempt < _maxAttempts &&
        (attempt == 0 || stopwatch.elapsed < _totalRetryWindow)) {
      final host = _hosts[attempt % _hosts.length];
      attempt++;

      final uri = Uri.https(host, path, queryParams);

      try {
        final response = await _client
            .get(uri, headers: {'User-Agent': _userAgent})
            .timeout(_singleRequestTimeout);

        if (response.statusCode == 200 || response.statusCode == 404) {
          return response;
        }

        if (_isRetryableStatus(response.statusCode)) {
          AppLogger.warning(
            'API ($host) вернул ${response.statusCode}, попытка $attempt/$_maxAttempts',
          );
          lastException = ApiException(
            'Сервер Open Food Facts временно перегружен (${response.statusCode}). Попробуйте ещё раз.',
          );
        } else {
          AppLogger.warning('API вернул статус ${response.statusCode}');
          throw ApiException(
            'Сервер вернул ошибку (${response.statusCode}). Попробуйте позже.',
          );
        }
      } on SocketException catch (e) {
        final code = e.osError?.errorCode;
        if (code == 7 || code == 101 || code == 11001) {
          AppLogger.warning('Нет подключения к интернету при запросе к API');
          throw const ApiException('Нет подключения к интернету.');
        }
        AppLogger.warning(
          'Сетевой сбой при запросе к $host, попытка $attempt/$_maxAttempts',
        );
        lastException = const ApiException(
          'Не удалось подключиться к серверу. Проверьте интернет.',
        );
      } on TlsException {
        AppLogger.warning(
          'Ошибка TLS при подключении к $host, попытка $attempt/$_maxAttempts',
        );
        lastException = const ApiException(
          'Защищённое соединение с сервером прервано. Попробуйте ещё раз.',
        );
      } on HttpException {
        AppLogger.warning(
          'HTTP ошибка при запросе к $host, попытка $attempt/$_maxAttempts',
        );
        lastException = const ApiException(
          'Ошибка передачи данных от сервера. Попробуйте ещё раз.',
        );
      } on http.ClientException {
        AppLogger.warning(
          'Ошибка клиента при запросе к $host, попытка $attempt/$_maxAttempts',
        );
        lastException = const ApiException(
          'Сбой соединения с сервером. Попробуйте ещё раз.',
        );
      } on TimeoutException {
        AppLogger.warning(
          'Таймаут запроса к $host, попытка $attempt/$_maxAttempts',
        );
        lastException = const ApiException(
          'Сервер не ответил вовремя. Попробуйте ещё раз.',
        );
      }

      if (attempt < _maxAttempts && stopwatch.elapsed < _totalRetryWindow) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }

    throw lastException ??
        const ApiException('Не удалось получить ответ от Open Food Facts.');
  }

  Future<List<FoodItem>> searchProducts(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final cacheKey = trimmed.toLowerCase().replaceAll('ё', 'е');
    final cached = _searchCache[cacheKey];
    if (cached != null) {
      AppLogger.info('Поиск из кэша: ${cached.length} продуктов');
      return cached;
    }

    final localMatches = BuiltInFoodCatalog.search(trimmed);

    AppLogger.info('API запрос поиска продуктов');

    try {
      final response = await _getWithRetry(
        '/cgi/search.pl',
        {
          'search_terms': trimmed,
          'search_simple': '1',
          'action': 'process',
          'json': '1',
          'lc': 'ru',
          'page_size': '35',
          'fields':
              'code,product_name,product_name_ru,brands,nutriments,countries_tags',
        },
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final products = (data['products'] as List<dynamic>?) ?? [];

      final seenKeys = <String>{};
      final combined = <FoodItem>[];

      for (final localItem in localMatches) {
        final key =
            '${localItem.name.toLowerCase()}_${localItem.caloriesPer100g.round()}';
        if (seenKeys.add(key)) {
          combined.add(localItem);
        }
      }

      final scoredApiItems = <({FoodItem item, int score})>[];

      for (final raw in products) {
        if (raw is Map<String, dynamic>) {
          final item = FoodItem.fromOpenFoodFactsJson(raw);
          if (item.name == 'Без названия' || item.caloriesPer100g <= 0) {
            continue;
          }

          final countriesTags = _extractCountriesTags(raw);
          if (_shouldExcludeProduct(raw, item, countriesTags)) {
            continue;
          }

          final dedupKey =
              '${item.name.toLowerCase()}_${item.caloriesPer100g.round()}';
          if (seenKeys.add(dedupKey)) {
            final isRussia = countriesTags.any(
              (t) => t.contains('russia') || t.contains('россия'),
            );
            scoredApiItems.add((
              item: item,
              score: relevanceScore(item.name, trimmed, isRussia: isRussia),
            ));
          }
        }
      }

      scoredApiItems.sort((a, b) => b.score.compareTo(a.score));
      combined.addAll(scoredApiItems.map((e) => e.item));

      final limited = combined.take(maxResultsLimit).toList();
      _searchCache[cacheKey] = limited;

      AppLogger.info('Всего найдено валидных продуктов: ${limited.length}');
      return limited;
    } on ApiException {
      if (localMatches.isNotEmpty) {
        AppLogger.info(
          'API недоступен, показаны блюда из справочника: ${localMatches.length}',
        );
        return localMatches.take(maxResultsLimit).toList();
      }
      rethrow;
    } on FormatException catch (e) {
      AppLogger.error('Ошибка разбора JSON от API', e);
      if (localMatches.isNotEmpty) {
        return localMatches.take(maxResultsLimit).toList();
      }
      throw const ApiException('Не удалось обработать ответ сервера.');
    }
  }

  Future<FoodItem?> getProductByBarcode(String barcode) async {
    final cleanCode = barcode.trim();
    if (cleanCode.isEmpty) return null;

    AppLogger.info('API запрос продукта по штрихкоду');

    try {
      final response = await _getWithRetry(
        '/api/v2/product/$cleanCode.json',
        {
          'fields': 'code,product_name,product_name_ru,brands,nutriments',
        },
      );

      if (response.statusCode == 404) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as int?;
      final product = data['product'] as Map<String, dynamic>?;

      if (status != 1 || product == null) {
        return null;
      }

      return FoodItem.fromOpenFoodFactsJson(product);
    } on ApiException {
      rethrow;
    } on FormatException catch (e) {
      AppLogger.error('Ошибка разбора JSON по штрихкоду', e);
      throw const ApiException('Не удалось обработать ответ сервера.');
    }
  }
}