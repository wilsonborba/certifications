// on_quiz_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:accredit/presentation/components/quiz/futuristic_loading.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:accredit/domain/models/topic_identifications.dart';
import 'package:accredit/presentation/components/quiz/quiz_controller.dart';
import 'package:accredit/presentation/screen_adjuster.dart';
import 'package:accredit/presentation/widgets/quiz/desktop_quiz.dart';
import 'package:accredit/presentation/widgets/quiz/mobile_quiz.dart';
import 'package:accredit/domain/services/pdf_frontend_prescan_manager.dart'
    as pre;
import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/core/utils/my_nagivation.dart';

// --------- Background parse (same as before) ----------
ContextInfo _parseContextInfoBody(Map<String, dynamic> args) {
  final body = args['body'] as String;
  final statusCode = args['statusCode'] as int;

  final jsonMap = json.decode(body) as Map<String, dynamic>;
  final msg = (jsonMap['message'] ?? '') as String;

  List<dynamic> data;
  if (jsonMap['data'] is List<dynamic>) {
    data = jsonMap['data'] as List<dynamic>;
  } else {
    data = <dynamic>[];
  }

  return ContextInfo(message: msg, data: data, statusCode: statusCode);
}

class OnQuizScreen extends StatefulWidget {
  final CertificationFormData formData;

  /// documentId (PDF mode) OR inputIdentification (topic mode)
  final String contextId;

  /// true -> PDF flow uses `getPdfContextFromApi`
  /// false -> Topic flow uses `getTopicContextFromApi`
  final bool isForPDF;

  /// required when `isForPDF == false`
  final String? itemName;

  const OnQuizScreen({
    super.key,
    required this.formData,
    required this.contextId,
    this.isForPDF = true,
    this.itemName,
  });

  @override
  State<OnQuizScreen> createState() => _OnQuizScreenState();
}

class _OnQuizScreenState extends State<OnQuizScreen> {
  bool _loading = true;
  String? _error;
  String _loadingMessage = "Contacting server...";
  ContextInfo? _resp;
  QuizController? _controller;

  final List<String> _messages = const [
    "Contacting server...",
    "Loading…",
    "Preparing your questions...",
    "Almost there…",
  ];
  int _msgIndex = 0;
  Timer? _msgTicker;

  @override
  void initState() {
    super.initState();
    _startMessageTicker();
    _bootstrap();
  }

  @override
  void dispose() {
    _msgTicker?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _startMessageTicker() {
    _loadingMessage = _messages.first;
    _msgTicker?.cancel();
    _msgTicker = Timer.periodic(const Duration(seconds: 4), (t) {
      if (!_loading || !mounted) {
        t.cancel();
        return;
      }
      _msgIndex = (_msgIndex + 1) % _messages.length;
      setState(() {
        _loadingMessage = _messages[_msgIndex];
      });
    });
  }

  Future<ContextInfo> _fetch() async {
    http.Response resp;
    if (widget.isForPDF) {
      resp = await pre.getPdfContextFromApi(
        documentId: widget.contextId,
        selectedLanguage: widget.formData.language,
      );
    } else {
      resp = await pre.getTopicContextFromApi(
        inputIdentification: widget.contextId,
        itemName: widget.itemName!,
        selectedLanguage: widget.formData.language,
      );
    }
    return compute(_parseContextInfoBody, {
      'body': resp.body,
      'statusCode': resp.statusCode,
    });
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
      _resp = null;
      _controller = null;
      _loadingMessage = _messages.first;
      _msgIndex = 0;
    });

    try {
      final got = await _fetch().timeout(const Duration(seconds: 3000));

      if (!mounted) return;

      if (got.statusCode != 200) {
        setState(() {
          _resp = got; // so UI can check code (e.g. 409)
          _error = _mapStatusCodeToMessage(got.statusCode, got.message);
          _loading = false;
        });
        _msgTicker?.cancel();
        return;
      }

      final controller = QuizController(
        formData: widget.formData,
        payload: got,
        isForPDF: widget.isForPDF,
        contextId: widget.contextId,
      );

      setState(() {
        _resp = got;
        _controller = controller;
        _loading = false;
      });
      _msgTicker?.cancel();
      //debug('Fetched ContextInfo: ${got.data}');
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error = "Request timed out. Please try again in a moment.";
        _loading = false;
      });
      _msgTicker?.cancel();
    } on http.ClientException catch (e) {
      // Common on web: "XMLHttpRequest error." / CORS / offline
      final msg = (e.message ?? '').toLowerCase();
      final looksNetworky =
          msg.contains('xmlhttprequest') ||
          msg.contains('failed host lookup') ||
          msg.contains('network');
      if (!mounted) return;
      setState(() {
        _error = looksNetworky
            ? "Network error. Check your connection and try again."
            : "Request failed. Please try again.";
        _loading = false;
      });
      _msgTicker?.cancel();
    } catch (e) {
      // Last resort: still keep a friendly message
      if (!mounted) return;
      setState(() {
        _error = "Could not continue. Please contact support@asodya.com.";
        _loading = false;
      });
      _msgTicker?.cancel();
      debug('Error in OnQuizScreen: $e');
    }
  }

  String _mapStatusCodeToMessage(int code, String msg) {
    const supportEmail = "support@asodya.com";
    switch (code) {
      case 400:
        return "Bad request, please contact $supportEmail";
      case 404:
        return "Not found, please contact $supportEmail";
      case 409:
        return "Blocked, suspicious activity detected...";
      case 412:
        return "Minimal content context not met, please contact $supportEmail";
      case 415:
        return "Unsupported file, please contact $supportEmail";
      case 422:
        return "We couldn't process your request, please contact $supportEmail";
      case 503:
        return "Service unavailable, please contact $supportEmail";
      default:
        return msg.isNotEmpty
            ? msg
            : "Please contact $supportEmail (code $code)";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: FuturisticLoading(
          messages: const [
            "Contacting server...",
            "Go take a short break… It takes time!",
            "Preparing your quiz…",
            "Almost ready, we are generating questions…",
            "Tip: You have 10 minutes for 1 up to 15 questions.",
            "Tip: Normally in English more questions are generated.",
            "Rule: You can only set your certification title once.",
            "Rule: You can only set your full name once.",
            "Security: AI injection attempts are automatically blocked.",
            "Need help? Contact support@asodya.com",
            "Sorry for the delay, it's our first time doing this at scale!",
          ],
          isActive: _loading,
          //imageAsset: "lib/presentation/assets/img/temp_logo.png", // optional, remove if not used
        ),
      );
    }

    if (_error != null) {
      final code = _resp?.statusCode;
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.shade100.withAlpha((0.4 * 255).toInt()),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Oops! Something went wrong.",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                  softWrap: true,
                ),
                const SizedBox(height: 32),
                if (code != 409)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade400,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      "Try Again",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    onPressed: _bootstrap,
                  ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade400,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Go Back",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  onPressed: () async {
                    await defaultLogout();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Success: render quiz
    return ScreenAdjuster<Widget>(
      mobileWidget: MobileQuiz(controller: _controller!),
      desktopWidget: DesktopQuiz(controller: _controller!),
    ).adjust(context);
  }
}
