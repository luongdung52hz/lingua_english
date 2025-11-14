// lib/data/data_question_demo.dart
import 'package:uuid/uuid.dart';
import '../data/models/question_model.dart';

final List<QuestionModel> demoQuestions = [
  QuestionModel(
    id: const Uuid().v4(),
    question: 'What is the capital of France?',
    options: ['Paris', 'London', 'Berlin', 'Madrid'],
    correctAnswer: 'Paris',
  ),
  QuestionModel(
    id: const Uuid().v4(),
    question: 'Which language is used to develop Flutter apps?',
    options: ['Dart', 'Java', 'Kotlin', 'Swift'],
    correctAnswer: 'Dart',
  ),
];
