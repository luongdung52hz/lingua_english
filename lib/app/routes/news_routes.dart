import '../../presentation/controllers/auth_controller.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/news_article_model.dart';
import '../../presentation/screens/news/daily_news.dart';
import '../../presentation/screens/news/news_detail_screen.dart'; // ✅ THÊM: Import NewsDetailScreen

List<RouteBase> newsRoutes(AuthController session) => [
  GoRoute(
    path: '/news',
    builder: (context, state) {
      return const DailyNewsSection();
    },
    routes: [
      GoRoute(
        path: 'detail',
        builder: (context, state) {
          final article = state.extra;
          if (article is! NewsArticle) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Không tìm thấy bài báo. Vui lòng mở lại từ danh sách.',
                ),
              ),
            );
          }
          return NewsDetailScreen(
            article: article,
          ); // ✅ FIX: Return NewsDetailScreen với extra
        },
      ),
    ],
  ),
];
