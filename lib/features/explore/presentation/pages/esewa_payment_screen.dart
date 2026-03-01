import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EsewaPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final Map<String, dynamic> formFields;
  final String itemTitle;
  final double totalPrice;

  const EsewaPaymentScreen({
    super.key,
    required this.paymentUrl,
    required this.formFields,
    required this.itemTitle,
    required this.totalPrice,
  });

  @override
  State<EsewaPaymentScreen> createState() => _EsewaPaymentScreenState();
}

class _EsewaPaymentScreenState extends State<EsewaPaymentScreen> {
  static const Color primaryOrange = Color(0xFFFF6518);
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasPopped = false;

  void _popOnce(Map<String, dynamic> result) {
    if (_hasPopped) return;
    _hasPopped = true;
    Navigator.pop(context, result);
  }

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('WebView page started: $url');
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            debugPrint('WebView page finished: $url');
            if (mounted) setState(() => _isLoading = false);
            // Also check the final loaded URL for reservation status
            _checkForReservationResult(url);
          },
          onWebResourceError: (error) {
            // Only log — don't show error UI. Sub-resource failures (images,
            // scripts, analytics) are normal and shouldn't block the payment.
            debugPrint('WebView resource error: ${error.description} (${error.errorCode}) isForMainFrame=${error.isForMainFrame}');
          },
          onNavigationRequest: (request) {
            final url = request.url;
            debugPrint('WebView navigating to: $url');

            // Check for reservation result first (highest priority)
            if (url.contains('reservation=success')) {
              final uri = Uri.tryParse(url);
              final paidAmount = uri?.queryParameters['paid'];
              _popOnce({
                'status': 'success',
                'paidAmount': paidAmount ?? widget.totalPrice.toStringAsFixed(0),
              });
              return NavigationDecision.prevent;
            }
            if (url.contains('reservation=failed')) {
              _popOnce({'status': 'failed'});
              return NavigationDecision.prevent;
            }

            // eSewa redirects to backend success/failure URL on localhost.
            // Android emulator can't reach localhost — rewrite to 10.0.2.2.
            if (url.contains('localhost')) {
              final rewritten = url.replaceAll('localhost', '10.0.2.2');
              debugPrint('Rewriting localhost to: $rewritten');
              _controller.loadRequest(Uri.parse(rewritten));
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    // Submit form data directly via POST request
    _submitPaymentForm();
  }

  /// Double-check the current URL after page finishes loading.
  /// Handles cases where the navigation delegate missed the redirect
  /// (e.g. server-side redirect that settles on a final URL).
  void _checkForReservationResult(String url) {
    if (url.contains('reservation=success')) {
      final uri = Uri.tryParse(url);
      final paidAmount = uri?.queryParameters['paid'];
      _popOnce({
        'status': 'success',
        'paidAmount': paidAmount ?? widget.totalPrice.toStringAsFixed(0),
      });
    } else if (url.contains('reservation=failed')) {
      _popOnce({'status': 'failed'});
    }
  }

  void _submitPaymentForm() {
    final formBody = widget.formFields.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');

    debugPrint('eSewa POST to: ${widget.paymentUrl}');
    debugPrint('eSewa form body: $formBody');

    _controller.loadRequest(
      Uri.parse(widget.paymentUrl),
      method: LoadRequestMethod.post,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: Uint8List.fromList(utf8.encode(formBody)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('eSewa Payment'),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _popOnce({'status': 'cancelled'}),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: primaryOrange),
            ),
        ],
      ),
    );
  }
}
