# Lingua English

Ứng dụng Flutter học tiếng Anh: bài học theo kỹ năng, quiz, flashcard, tin tức, YouTube, chat và quản trị nội dung.

## Chạy trên máy ảo iOS

Cần Flutter phù hợp với `pubspec.yaml`, Xcode và iOS Simulator.

```sh
flutter pub get
flutter devices
flutter run -d <simulator-id>
```

Tệp `.env` được khai báo trong assets và được Git bỏ qua. Cấu hình các khóa theo chức năng cần thử: `CLIENT_ID` cho Google Sign-In web, `GEMINI_API_KEY` cho AI/dịch, `YOUTUBE_API_KEY` cho YouTube. Firebase dùng cấu hình hiện có trong `lib/firebase_options.dart` và thư mục native. Không commit giá trị bí mật. `.env` trong assets có thể trích xuất từ bản build; khóa backend riêng tư cần đặt ở server khi phát hành.

## Kiểm tra

```sh
flutter analyze --no-pub
flutter test --no-pub
flutter build ios --simulator --debug --no-pub
```

Test không dùng tài khoản hay Firebase thật; bao gồm session guard, vòng đời controller, kết quả bất đồng bộ, UID repository, tiến độ học, RSS fallback và UI root.

Xem [kiến trúc và quy tắc phát triển](docs/architecture.md). Dự án vẫn còn lint và chức năng placeholder từ phiên bản cũ; không coi build thành công là xác nhận mọi chức năng backend.
