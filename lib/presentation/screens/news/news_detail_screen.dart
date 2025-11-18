// presentation/screens/news/news_detail_screen.dart - Simple & Clean Design
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:learn_english/resources/styles/text_styles.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../data/models/news_article_model.dart';
import '../../../resources/styles/colors.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsArticle article;

  const NewsDetailScreen({
    super.key,
    required this.article,
  });

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    if (Platform.isAndroid) {
      // Android-specific setup if needed
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (progress == 100) setState(() => _isLoading = false);
          },
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.article.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          widget.article.title,
          style: AppTextStyles.headlineb,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _controller.reload();
            },
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary,),
              ),
            ),
        ],
      ),
    );
  }
}