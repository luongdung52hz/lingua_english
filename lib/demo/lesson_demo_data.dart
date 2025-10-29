import '../data/models/lesson_model.dart';

class LessonDemoData {
  // ✅ Lấy lessons theo level + skill + topic
  static List<LessonModel> getLessonsByTopic(String level, String skill, String topic) {
    return _allLessons.where((lesson) =>
    lesson.level == level &&
        lesson.skill == skill &&
        lesson.topic == topic
    ).toList();
  }

  // ✅ Lấy danh sách topics theo level + skill
  static List<String> getTopicsByLevelAndSkill(String level, String skill) {
    return _allLessons
        .where((lesson) => lesson.level == level && lesson.skill == skill)
        .map((lesson) => lesson.topic)
        .toSet() // Remove duplicates
        .toList();
  }

  // ✅ Lấy tất cả lessons của level + skill
  static List<LessonModel> getLessonsByLevelAndSkill(String level, String skill) {
    return _allLessons
        .where((lesson) => lesson.level == level && lesson.skill == skill)
        .toList();
  }

  static List<LessonModel> getLessonsByLevel(String level) {
    return _allLessons.where((lesson) => lesson.level == level).toList();
  }

  static List<LessonModel> getLessonsBySkill(String skill) {
    return _allLessons.where((lesson) => lesson.skill == skill).toList();
  }

  static List<LessonModel> getAllLessons() => _allLessons;

  // ✅ DATA MỚI: Có thêm field "topic"
  static final List<LessonModel> _allLessons = [
    // ═══════════════════════════════════════════════════════════
    // LEVEL A1 - LISTENING
    // ═══════════════════════════════════════════════════════════

    // Topic: Greetings & Introductions
    LessonModel(
      id: 'a1_listen_greet_01',
      title: 'Chào hỏi cơ bản',
      description: 'Học các cách chào hỏi thông dụng',
      level: 'A1',
      skill: 'listening',
      topic: 'Greetings & Introductions',
      duration: 8,
      difficulty: 1,
      content: {
        'transcript': 'Good morning! How are you today? I am fine, thank you.',
        'questions': [
          {
            'id': 'q1',
            'question': 'What time of day is it?',
            'options': ['Morning', 'Afternoon', 'Evening', 'Night'],
            'correctAnswer': 'Morning',
          },
        ],
      },
    ),
    LessonModel(
      id: 'a1_listen_greet_02',
      title: 'Giới thiệu bản thân',
      description: 'Học cách giới thiệu tên, tuổi và quê quán',
      level: 'A1',
      skill: 'listening',
      topic: 'Greetings & Introductions',
      duration: 10,
      difficulty: 1,
      content: {
        'transcript': 'Hello, my name is John. I am 25 years old. I am from Vietnam.',
        'questions': [
          {
            'id': 'q1',
            'question': 'What is his name?',
            'options': ['John', 'Mike', 'Tom', 'Peter'],
            'correctAnswer': 'John',
          },
          {
            'id': 'q2',
            'question': 'How old is he?',
            'options': ['20', '25', '30', '35'],
            'correctAnswer': '25',
          },
        ],
      },
    ),
    LessonModel(
      id: 'a1_listen_greet_03',
      title: 'Hỏi thăm sức khỏe',
      description: 'Cách hỏi và trả lời về sức khỏe',
      level: 'A1',
      skill: 'listening',
      topic: 'Greetings & Introductions',
      duration: 7,
      difficulty: 1,
      content: {
        'transcript': 'A: How are you feeling today? B: I am very well, thanks!',
        'questions': [
          {
            'id': 'q1',
            'question': 'How is person B feeling?',
            'options': ['Sick', 'Tired', 'Very well', 'Sad'],
            'correctAnswer': 'Very well',
          },
        ],
      },
    ),

    // Topic: Family & Friends
    LessonModel(
      id: 'a1_listen_family_01',
      title: 'Giới thiệu gia đình',
      description: 'Nghe về các thành viên trong gia đình',
      level: 'A1',
      skill: 'listening',
      topic: 'Family & Friends',
      duration: 10,
      difficulty: 1,
      content: {
        'transcript': 'This is my father. He is 45 years old. My mother is a teacher.',
        'questions': [
          {
            'id': 'q1',
            'question': 'What does the mother do?',
            'options': ['Doctor', 'Teacher', 'Engineer', 'Nurse'],
            'correctAnswer': 'Teacher',
          },
        ],
      },
    ),
    LessonModel(
      id: 'a1_listen_family_02',
      title: 'Anh chị em',
      description: 'Nghe về anh chị em trong gia đình',
      level: 'A1',
      skill: 'listening',
      topic: 'Family & Friends',
      duration: 9,
      difficulty: 1,
      content: {
        'transcript': 'I have one brother and two sisters. My brother is older than me.',
        'questions': [
          {
            'id': 'q1',
            'question': 'How many sisters does the speaker have?',
            'options': ['One', 'Two', 'Three', 'None'],
            'correctAnswer': 'Two',
          },
        ],
      },
    ),

    // Topic: Daily Activities
    LessonModel(
      id: 'a1_listen_daily_01',
      title: 'Thói quen buổi sáng',
      description: 'Nghe về hoạt động buổi sáng',
      level: 'A1',
      skill: 'listening',
      topic: 'Daily Activities',
      duration: 10,
      difficulty: 1,
      content: {
        'transcript': 'I wake up at 7 AM. I brush my teeth and have breakfast.',
        'questions': [
          {
            'id': 'q1',
            'question': 'What time does the person wake up?',
            'options': ['6 AM', '7 AM', '8 AM', '9 AM'],
            'correctAnswer': '7 AM',
          },
        ],
      },
    ),

    // ═══════════════════════════════════════════════════════════
    // LEVEL A1 - SPEAKING
    // ═══════════════════════════════════════════════════════════

    // Topic: Pronunciation Basics
    LessonModel(
      id: 'a1_speak_pronun_01',
      title: 'Phát âm nguyên âm',
      description: 'Luyện phát âm các nguyên âm cơ bản',
      level: 'A1',
      skill: 'speaking',
      topic: 'Pronunciation Basics',
      duration: 15,
      difficulty: 1,
      content: {
        'words': ['cat', 'bat', 'mat', 'hat', 'rat'],
        'pronunciation': {
          'cat': '/kæt/',
          'bat': '/bæt/',
          'mat': '/mæt/',
        },
        'instructions': 'Repeat after the audio and record your voice',
      },
    ),
    LessonModel(
      id: 'a1_speak_pronun_02',
      title: 'Phát âm phụ âm',
      description: 'Luyện phát âm các phụ âm khó',
      level: 'A1',
      skill: 'speaking',
      topic: 'Pronunciation Basics',
      duration: 12,
      difficulty: 1,
      content: {
        'words': ['thin', 'this', 'ship', 'sheep', 'very', 'berry'],
        'tips': [
          'th: Put tongue between teeth',
          'sh: Round your lips',
          'v: Upper teeth touch lower lip',
        ],
      },
    ),

    // Topic: Greetings & Introductions
    LessonModel(
      id: 'a1_speak_greet_01',
      title: 'Tự giới thiệu',
      description: 'Nói về bản thân một cách tự nhiên',
      level: 'A1',
      skill: 'speaking',
      topic: 'Greetings & Introductions',
      duration: 12,
      difficulty: 1,
      content: {
        'sentences': [
          'My name is...',
          'I am from...',
          'I am ... years old.',
          'Nice to meet you!',
        ],
        'practice': 'Record yourself introducing to a new friend',
      },
    ),

    // Topic: Family & Friends
    LessonModel(
      id: 'a1_speak_family_01',
      title: 'Giới thiệu gia đình',
      description: 'Nói về các thành viên trong gia đình',
      level: 'A1',
      skill: 'speaking',
      topic: 'Family & Friends',
      duration: 12,
      difficulty: 2,
      content: {
        'topics': ['father', 'mother', 'sister', 'brother'],
        'sentences': [
          'This is my father.',
          'My mother is a teacher.',
          'I have one sister.',
        ],
      },
    ),

    // ═══════════════════════════════════════════════════════════
    // LEVEL A1 - READING
    // ═══════════════════════════════════════════════════════════

    // Topic: Simple Texts
    LessonModel(
      id: 'a1_read_simple_01',
      title: 'Đọc email đơn giản',
      description: 'Đọc và hiểu email cơ bản',
      level: 'A1',
      skill: 'reading',
      topic: 'Simple Texts',
      duration: 10,
      difficulty: 1,
      content: {
        'text': '''
Hi Sarah,

How are you? I am fine. I am in Hanoi now. The weather is nice.
I visit the Old Quarter every day. The food is delicious!

See you soon,
Tom
        ''',
        'questions': [
          {
            'id': 'q1',
            'question': 'Where is Tom?',
            'options': ['Hanoi', 'London', 'Paris', 'Tokyo'],
            'correctAnswer': 'Hanoi',
          },
          {
            'id': 'q2',
            'question': 'How is the weather?',
            'options': ['Bad', 'Nice', 'Cold', 'Hot'],
            'correctAnswer': 'Nice',
          },
        ],
      },
    ),
    LessonModel(
      id: 'a1_read_simple_02',
      title: 'Đọc thông báo ngắn',
      description: 'Hiểu thông báo công cộng',
      level: 'A1',
      skill: 'reading',
      topic: 'Simple Texts',
      duration: 8,
      difficulty: 1,
      content: {
        'text': '''
LIBRARY NOTICE

Opening hours:
Monday - Friday: 8 AM - 8 PM
Saturday: 9 AM - 5 PM
Sunday: CLOSED

Please return books on time.
        ''',
        'questions': [
          {
            'id': 'q1',
            'question': 'When is the library closed?',
            'options': ['Monday', 'Saturday', 'Sunday', 'Friday'],
            'correctAnswer': 'Sunday',
          },
        ],
      },
    ),

    // Topic: Everyday Life
    LessonModel(
      id: 'a1_read_everyday_01',
      title: 'Đọc menu nhà hàng',
      description: 'Hiểu thực đơn tiếng Anh',
      level: 'A1',
      skill: 'reading',
      topic: 'Everyday Life',
      duration: 8,
      difficulty: 1,
      content: {
        'text': '''
RESTAURANT MENU

Main Dishes:
- Chicken Rice: \$5
- Beef Noodles: \$6
- Vegetable Soup: \$4

Drinks:
- Water: \$1
- Coffee: \$2
- Tea: \$2
        ''',
        'questions': [
          {
            'id': 'q1',
            'question': 'How much is chicken rice?',
            'options': ['\$4', '\$5', '\$6', '\$7'],
            'correctAnswer': '\$5',
          },
        ],
      },
    ),

    // ═══════════════════════════════════════════════════════════
    // LEVEL A1 - WRITING
    // ═══════════════════════════════════════════════════════════

    // Topic: Basic Sentences
    LessonModel(
      id: 'a1_write_basic_01',
      title: 'Viết câu đơn giản',
      description: 'Tạo câu với chủ ngữ và động từ',
      level: 'A1',
      skill: 'writing',
      topic: 'Basic Sentences',
      duration: 15,
      difficulty: 1,
      content: {
        'exercises': [
          {
            'prompt': 'Write a sentence about your name',
            'example': 'My name is ...',
            'keywords': ['name', 'is'],
          },
          {
            'prompt': 'Write a sentence about your age',
            'example': 'I am ... years old',
            'keywords': ['age', 'years'],
          },
        ],
        'grammar': {
          'pattern': 'Subject + Verb + Object',
          'examples': ['I like apples', 'She reads books'],
        },
      },
    ),
    LessonModel(
      id: 'a1_write_basic_02',
      title: 'Viết về sở thích',
      description: 'Viết câu đơn về những gì bạn thích',
      level: 'A1',
      skill: 'writing',
      topic: 'Basic Sentences',
      duration: 12,
      difficulty: 1,
      content: {
        'prompt': 'Write 3 sentences about things you like',
        'examples': [
          'I like pizza.',
          'I like watching movies.',
          'I like my family.',
        ],
        'vocabulary': ['like', 'love', 'enjoy', 'prefer'],
      },
    ),

    // Topic: Personal Information
    LessonModel(
      id: 'a1_write_personal_01',
      title: 'Viết email ngắn',
      description: 'Viết email giới thiệu bản thân',
      level: 'A1',
      skill: 'writing',
      topic: 'Personal Information',
      duration: 20,
      difficulty: 2,
      content: {
        'template': '''
Hi [Name],

My name is [Your Name]. I am from [Country].
I am [Age] years old. I like [Hobby].

Best regards,
[Your Name]
        ''',
        'requirements': [
          'Use at least 30 words',
          'Include: name, country, age, hobby',
          'Start with greeting',
          'End with closing',
        ],
      },
    ),

    // ═══════════════════════════════════════════════════════════
    // LEVEL A2 - LISTENING
    // ═══════════════════════════════════════════════════════════

    // Topic: Shopping & Money
    LessonModel(
      id: 'a2_listen_shop_01',
      title: 'Hội thoại mua sắm',
      description: 'Nghe và hiểu đoạn hội thoại tại cửa hàng',
      level: 'A2',
      skill: 'listening',
      topic: 'Shopping & Money',
      duration: 12,
      difficulty: 2,
      content: {
        'transcript': '''
Customer: How much is this shirt?
Seller: It's 20 dollars.
Customer: Do you have it in blue?
Seller: Yes, we do. Here you are.
        ''',
        'questions': [
          {
            'id': 'q1',
            'question': 'How much is the shirt?',
            'options': ['\$10', '\$15', '\$20', '\$25'],
            'correctAnswer': '\$20',
          },
        ],
      },
    ),

    // Topic: Daily Routines
    LessonModel(
      id: 'a2_listen_routine_01',
      title: 'Nghe về thói quen hàng ngày',
      description: 'Hiểu mô tả về một ngày làm việc',
      level: 'A2',
      skill: 'listening',
      topic: 'Daily Routines',
      duration: 10,
      difficulty: 2,
      content: {
        'transcript': 'I wake up at 6 AM. I go to work at 8 AM. I come home at 5 PM.',
        'questions': [
          {
            'id': 'q1',
            'question': 'What time does the person go to work?',
            'options': ['6 AM', '7 AM', '8 AM', '9 AM'],
            'correctAnswer': '8 AM',
          },
        ],
      },
    ),

    // ═══════════════════════════════════════════════════════════
    // LEVEL A2 - SPEAKING
    // ═══════════════════════════════════════════════════════════

    // Topic: Descriptions
    LessonModel(
      id: 'a2_speak_desc_01',
      title: 'Mô tả ngoại hình',
      description: 'Học cách mô tả người khác',
      level: 'A2',
      skill: 'speaking',
      topic: 'Descriptions',
      duration: 15,
      difficulty: 2,
      content: {
        'vocabulary': [
          'tall', 'short', 'thin', 'fat',
          'long hair', 'short hair', 'glasses', 'beard'
        ],
        'sentences': [
          'He is tall and thin.',
          'She has long black hair.',
          'He wears glasses.',
        ],
      },
    ),

    // ═══════════════════════════════════════════════════════════
    // LEVEL A2 - READING
    // ═══════════════════════════════════════════════════════════

    // Topic: Stories & Articles
    LessonModel(
      id: 'a2_read_story_01',
      title: 'Đọc bài viết ngắn',
      description: 'Đọc về cuộc sống hàng ngày',
      level: 'A2',
      skill: 'reading',
      topic: 'Stories & Articles',
      duration: 15,
      difficulty: 2,
      content: {
        'text': '''
My Daily Routine

I wake up at 6 AM every day. First, I brush my teeth and take a shower.
Then I have breakfast with my family. I usually eat bread and drink milk.
I go to work at 8 AM. I work in an office. I come home at 5 PM.
In the evening, I watch TV or read books. I go to bed at 10 PM.
        ''',
        'questions': [
          {
            'id': 'q1',
            'question': 'What time does the person wake up?',
            'options': ['5 AM', '6 AM', '7 AM', '8 AM'],
            'correctAnswer': '6 AM',
          },
          {
            'id': 'q2',
            'question': 'What does the person eat for breakfast?',
            'options': ['Rice', 'Noodles', 'Bread', 'Soup'],
            'correctAnswer': 'Bread',
          },
        ],
      },
    ),

    // ═══════════════════════════════════════════════════════════
    // LEVEL A2 - WRITING
    // ═══════════════════════════════════════════════════════════

    // Topic: Paragraphs
    LessonModel(
      id: 'a2_write_para_01',
      title: 'Viết về sở thích',
      description: 'Viết đoạn văn ngắn về sở thích',
      level: 'A2',
      skill: 'writing',
      topic: 'Paragraphs',
      duration: 20,
      difficulty: 2,
      content: {
        'prompt': 'Write about your hobby (50-70 words)',
        'structure': [
          'What is your hobby?',
          'When did you start?',
          'Why do you like it?',
          'How often do you do it?',
        ],
        'vocabulary': [
          'hobby', 'enjoy', 'interesting', 'fun',
          'every day', 'sometimes', 'usually', 'always'
        ],
      },
    ),

    // ═══════════════════════════════════════════════════════════
    // LEVEL B1 - LISTENING
    // ═══════════════════════════════════════════════════════════

    // Topic: News & Media
    LessonModel(
      id: 'b1_listen_news_01',
      title: 'Nghe tin tức',
      description: 'Nghe và hiểu bản tin ngắn',
      level: 'B1',
      skill: 'listening',
      topic: 'News & Media',
      duration: 15,
      difficulty: 3,
      content: {
        'transcript': '''
Good evening. Here is the weather forecast.
Tomorrow will be sunny in the morning with temperatures around 25 degrees.
In the afternoon, there might be some rain.
Remember to bring an umbrella if you go out.
        ''',
        'questions': [
          {
            'id': 'q1',
            'question': 'What will the weather be like tomorrow morning?',
            'options': ['Rainy', 'Sunny', 'Cloudy', 'Windy'],
            'correctAnswer': 'Sunny',
          },
        ],
      },
    ),

    // ═══════════════════════════════════════════════════════════
    // LEVEL B1 - SPEAKING
    // ═══════════════════════════════════════════════════════════

    // Topic: Plans & Goals
    LessonModel(
      id: 'b1_speak_plan_01',
      title: 'Thảo luận kế hoạch',
      description: 'Nói về kế hoạch tương lai',
      level: 'B1',
      skill: 'speaking',
      topic: 'Plans & Goals',
      duration: 18,
      difficulty: 3,
      content: {
        'topics': ['Travel plans', 'Career goals', 'Study plans'],
        'grammar': ['Future tense', 'Going to', 'Will'],
        'expressions': [
          'I am going to...',
          'I plan to...',
          'In the future, I will...',
        ],
      },
    ),

    // ═══════════════════════════════════════════════════════════
    // LEVEL B1 - READING
    // ═══════════════════════════════════════════════════════════

    // Topic: Current Issues
    LessonModel(
      id: 'b1_read_issue_01',
      title: 'Đọc bài báo',
      description: 'Đọc hiểu bài báo về môi trường',
      level: 'B1',
      skill: 'reading',
      topic: 'Current Issues',
      duration: 20,
      difficulty: 3,
      content: {
        'text': '''
Climate Change and Our Planet

Climate change is one of the biggest challenges facing our planet today.
Scientists have been warning us for decades about rising temperatures.
The main cause is greenhouse gas emissions from human activities.
We must take action now to protect our environment for future generations.
Simple actions like recycling, using public transport, and saving energy can help.
        ''',
        'questions': [
          {
            'id': 'q1',
            'question': 'What is the main cause of climate change?',
            'options': [
              'Natural disasters',
              'Greenhouse gases',
              'Ocean pollution',
              'Forest fires'
            ],
            'correctAnswer': 'Greenhouse gases',
          },
        ],
      },
    ),

    // ═══════════════════════════════════════════════════════════
    // LEVEL B1 - WRITING
    // ═══════════════════════════════════════════════════════════

    // Topic: Formal Writing
    LessonModel(
      id: 'b1_write_formal_01',
      title: 'Viết thư phàn nàn',
      description: 'Viết thư khiếu nại lịch sự',
      level: 'B1',
      skill: 'writing',
      topic: 'Formal Writing',
      duration: 25,
      difficulty: 3,
      content: {
        'situation': 'You bought a product online but it arrived damaged',
        'structure': [
          'Opening: State the purpose',
          'Body: Explain the problem',
          'Closing: Request a solution',
        ],
        'useful_phrases': [
          'I am writing to complain about...',
          'I would like to request...',
          'I look forward to hearing from you',
        ],
      },
    ),
  ];
}