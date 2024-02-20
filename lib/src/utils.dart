part of 'app.dart';

class LogHelper {
  LogHelper({String? name}) : _nameCache = name;

  String? _nameCache;

  void logER(
    Object? message, {
    DateTime? time,
    int? sequenceNumber,
    int level = 0,
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (shouldLog) {
      log(
        message.toString(),
        time: time ?? DateTime.now(),
        sequenceNumber: sequenceNumber,
        level: level,
        name: name ?? (_nameCache ??= _getName),
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void printER(Object? message, {String? name, int? wrapWidth}) {
    debugPrint(
      "[${name ?? (_nameCache ??= _getName)}] $message",
      wrapWidth: wrapWidth,
    );
  }

  String get _getName {
    if (this is State) {
      return (this as State).widget.runtimeType.toString();
    } else {
      // ignore: no_runtimetype_tostring
      return runtimeType.toString();
    }
  }

  final bool shouldLog = kDebugMode;
}

mixin LogHelperMixin {
  String? _nameCache;

  void logER(
    Object? message, {
    DateTime? time,
    int? sequenceNumber,
    int level = 0,
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (shouldLog) {
      log(
        message.toString(),
        time: time ?? DateTime.now(),
        sequenceNumber: sequenceNumber,
        level: level,
        name: name ?? (_nameCache ??= _getName),
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void printER(Object? message, {String? name, int? wrapWidth}) {
    debugPrint(
      "[${name ?? (_nameCache ??= _getName)}] $message",
      wrapWidth: wrapWidth,
    );
  }

  String get _getName {
    if (this is State) {
      return (this as State).widget.runtimeType.toString();
    } else {
      // ignore: no_runtimetype_tostring
      return runtimeType.toString();
    }
  }

  final bool shouldLog = kDebugMode;
}

mixin class FireOnCalm {
  Duration? _timeToCalmDown;
  AsyncCallback? _callback;

  void initializeFireOnCalm({
    required Duration calmDownTime,
    required AsyncCallback callbackOnCalm,
  }) {
    _timeToCalmDown = calmDownTime;
    _callback = callbackOnCalm;
  }

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  void notCalm() {
    if (kDebugMode && ((_timeToCalmDown == null) || (_callback == null))) {
      log(
        "FireOnCalm must be initialized before use by calling initializeFireOnCalm()",
        error:
            "FireOnCalm must be initialized before use by calling initializeFireOnCalm()",
      );
      return;
    }
    _stopwatch.start();
    _stopwatch.reset();
    _timer?.cancel();
    _timer = Timer(
      _timeToCalmDown!,
      () async {
        if (_stopwatch.elapsed >= _timeToCalmDown!) {
          await _callback!.call();
          _stopwatch.stop();
          _stopwatch.reset();
        }
      },
    );
  }
}

extension on Size {
  Size addSize(Size other) {
    return Size(width + other.width, height + other.height);
  }

  Size addNum(num x) {
    return Size(width + x, height + x);
  }

  Size addOffset(Offset offset) {
    return Size(width + offset.dx, height + offset.dy);
  }

  Size resizeKeepingAspectRatioForWidth(double newWidth) {
    final double newHeight = newWidth / width * height;
    return Size(newWidth, newHeight);
  }

  Size resizeKeepingAspectRatioForHeight(double newHeight) {
    final double newWidth = newHeight / height * width;
    return Size(newWidth, newHeight);
  }

  Size resizeKeepingAspectRatioForHeightBy(double heightDelta) {
    final double newHeight = height + heightDelta;
    return resizeKeepingAspectRatioForHeight(newHeight);
  }
}
