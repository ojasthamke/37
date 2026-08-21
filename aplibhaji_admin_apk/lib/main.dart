import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ApliBhaji Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    params = const PlatformWebViewControllerCreationParams();

    _controller = WebViewController.fromPlatformCreationParams(params);

    // Enable hybrid composition on Android for keyboard support
    if (_controller.platform is AndroidWebViewController) {
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
              if (mounted) setState(() => _isLoading = false);
              _controller.evaluateJavaScript("document.body.focus();");
            },
        ),
      )
      ..loadRequest(Uri.parse('https://37-iota.vercel.app/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight - MediaQuery.of(context).viewInsets.bottom;
            return SizedBox(
              height: height,
              child: Stack(
                children: [
                  WebViewWidget(
                    controller: _controller,
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<VerticalDragGestureRecognizer>(
                        () => VerticalDragGestureRecognizer(),
                      ),
                      Factory<HorizontalDragGestureRecognizer>(
                        () => HorizontalDragGestureRecognizer(),
                      ),
                      Factory<TapGestureRecognizer>(
                        () => TapGestureRecognizer(),
                      ),
                      Factory<LongPressGestureRecognizer>(
                        () => LongPressGestureRecognizer(),
                      ),
                    },
                  ),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
