class Routes {
  // Core
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const admin = '/admin';

  // Auth
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const forgotPassword = '/auth/forgot-password';


  // Learn
  static const learn = '/learn';
  static const learnDetail = '/learn/detail';
  static const listening = '/learn/listening';
  static const speaking = '/learn/speaking';
  static const reading = '/learn/reading';
  static const writing = '/learn/writing';

  // Quiz
  static const quiz = '/quiz';
  static const quizDetail = '/quiz/detail';
  static const quizTaking = '/quiz/taking';
  static const quizCreate = '/quiz/create';


  static const quizDuel = '/quiz/duel';

  static const grammar = '/grammar';
  static const grammarTopic = '/grammar/subtopics';
  static const grammarDetail = '/grammar/detail';

  // Flashcards
  static const flashcards = '/flashcards';
  static const flashcardDetail = '/flashcards/detail';  // Đã có
  static const flashcardCreate = '/flashcards/create';  // Mới
  static const flashcardStudy = '/flashcards/study';    // Mới
  static const folders = '/flashcards/folders';         // Mới

  // Chats
  static const chat = '/chat';
  static const chatRoom = '/chat/room';

  // Thêm: Route cho tìm kiếm bạn bè trong chat
  static const chatFriends = '/chat/friends';

  // YOUTUBE MODULE - THÊM MỚI
  static const youtubeChannels = '/youtube/channels';
  static const youtubeVideos = '/youtube/channels/videos';
  static const youtubePlayer = '/youtube/channels/videos/player';

  static const news = '/news';
  static const newsDetail = '/detail';

  // AI
  static const aiChat = '/ai/chat';
  static const aiCorrection = '/ai/correction';

  // Profile
  static const profile = '/profile';
  static const settings = '/profile/settings';
}