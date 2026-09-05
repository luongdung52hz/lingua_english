import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:learn_english/data/repositories/news_repository.dart';

void main() {
  test('RSS source failure falls back and returns parsed articles', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      if (requests == 1) return http.Response('unavailable', 503);
      return http.Response('''<rss><channel><item>
        <title>English practice</title><link>https://example.test/article</link>
        <description>Daily reading lesson</description>
        <pubDate>Sat, 05 Sep 2026 10:00:00 GMT</pubDate>
      </item></channel></rss>''', 200);
    });
    addTearDown(client.close);
    final result = await NewsRepository(client: client).fetchDailyNews();
    expect(requests, 2);
    expect(result.single.title, 'English practice');
  });

  test(
    'all source failures are exposed instead of silently returning empty data',
    () async {
      final client = MockClient((_) async => http.Response('unavailable', 503));
      addTearDown(client.close);
      await expectLater(
        NewsRepository(client: client).fetchDailyNews(),
        throwsStateError,
      );
    },
  );
}
