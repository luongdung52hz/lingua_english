// presentation/screens/home/components/daily_news_section.dart - Widget riêng cho news horizontal list (no controller param, use Get.find)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/news_article_model.dart';

import 'package:go_router/go_router.dart';

import '../../../resources/styles/colors.dart';
import '../../controllers/news_controller.dart';
import '../../widgets/info_card.dart';

class DailyNewsSection extends StatelessWidget {
  const DailyNewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final newsController = Get.find<NewsController>();

    return Obx(() {
      if (newsController.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator(color: AppColors.primary
            ,)),
        );
      }
      if (newsController.error.value.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              Expanded(child: Text('Lỗi news: ${newsController.error.value}')),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: newsController.fetchDailyNews,
              ),
            ],
          ),
        );
      }
      if (newsController.articles.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(8),
          child: Text('Không có bài báo hôm nay'),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Báo Hôm Nay',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10,),
          SizedBox(
            height: 120, // Chiều cao fixed cho horizontal scroll
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: newsController.articles.length,
              itemBuilder: (context, index) {
                final article = newsController.articles[index];
                final truncatedSubtitle = article.description.length > 100
                    ? '${article.description.substring(0, 100)}...'
                    : article.description;

                return Container(
                  width: 300,
                  margin: const EdgeInsets.only(right: 12),
                  child: InfoCard(
                    title: article.title,
                  //  subtitle: truncatedSubtitle,
                    infoPairs: [IconTextPair(Icons.date_range, article.publishedAt.split('T')[0])],
                    leading: const Icon(
                      Icons.article_outlined,
                      size: 30,
                      color: Colors.grey,
                    ),
                    onTap: () => _openArticle(context, article),
                    trailing: const Icon(Icons.arrow_forward_ios,color: Colors.grey,),
                    gradientStartColor: Colors.blue.shade50,
                    gradientEndColor: Colors.blue.shade100,
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  void _openArticle(BuildContext context, NewsArticle article) {
    context.push('/news/detail', extra: article);
  }
}