import 'package:logger/logger.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  late final Logger _logger;

  factory LogService() {
    return _instance;
  }

  LogService._internal() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 5,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
    );
  }

  void verbose(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.v('$message\nError: $error\nStacktrace: $stackTrace');
    } else {
      _logger.v(message);
    }
  }

  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.d('$message\nError: $error\nStacktrace: $stackTrace');
    } else {
      _logger.d(message);
    }
  }

  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.i('$message\nError: $error\nStacktrace: $stackTrace');
    } else {
      _logger.i(message);
    }
  }

  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.w('$message\nError: $error\nStacktrace: $stackTrace');
    } else {
      _logger.w(message);
    }
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.e('$message\nError: $error\nStacktrace: $stackTrace');
    } else {
      _logger.e(message);
    }
  }

  void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.wtf('$message\nError: $error\nStacktrace: $stackTrace');
    } else {
      _logger.wtf(message);
    }
  }
}

final log = LogService();