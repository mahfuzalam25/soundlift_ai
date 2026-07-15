import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

class FaqModel {
  final String id;
  final String question;
  final String answer;

  FaqModel({required this.id, required this.question, required this.answer});

  factory FaqModel.fromJson(Map<String, dynamic> json) => FaqModel(
    id: json['id'],
    question: json['question'] ?? '',
    answer: json['answer'] ?? '',
  );
}

class TutorialModel {
  final String id;
  final String title;
  final String description;
  final String? videoUrl;

  TutorialModel({
    required this.id,
    required this.title,
    required this.description,
    this.videoUrl,
  });

  factory TutorialModel.fromJson(Map<String, dynamic> json) => TutorialModel(
    id: json['id'],
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    videoUrl: json['video_url'],
  );

  String? get youtubeId {
    if (videoUrl == null) return null;
    final regExp = RegExp(
      r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([^&?\n]+)',
    );
    final match = regExp.firstMatch(videoUrl!);
    return match?.group(1);
  }
}

class DocModel {
  final String id;
  final String title;
  final String content;

  DocModel({required this.id, required this.title, required this.content});

  factory DocModel.fromJson(Map<String, dynamic> json) => DocModel(
    id: json['id'],
    title: json['title'] ?? '',
    content: json['content'] ?? '',
  );
}

class ContactTicketModel {
  final String id;
  final String subject;
  final String message;
  final String? adminReply;
  final bool isReplied;
  final DateTime createdAt;

  ContactTicketModel({
    required this.id,
    required this.subject,
    required this.message,
    this.adminReply,
    required this.isReplied,
    required this.createdAt,
  });

  factory ContactTicketModel.fromJson(Map<String, dynamic> json) =>
      ContactTicketModel(
        id: json['id'],
        subject: json['subject'] ?? '',
        message: json['message'] ?? '',
        adminReply: json['admin_reply'],
        isReplied: json['is_replied'] ?? false,
        createdAt: DateTime.parse(json['created_at']).toLocal(),
      );
}

// Repository
class SupportRepository {
  final Dio _dio;
  SupportRepository(this._dio);

  Future<List<FaqModel>> fetchFaqs() async {
    final response = await _dio.get('/api/support/faqs/');
    return (response.data as List).map((x) => FaqModel.fromJson(x)).toList();
  }

  Future<List<TutorialModel>> fetchTutorials() async {
    final response = await _dio.get('/api/support/tutorials/');
    return (response.data as List)
        .map((x) => TutorialModel.fromJson(x))
        .toList();
  }

  Future<List<DocModel>> fetchDocs() async {
    final response = await _dio.get('/api/support/docs/');
    return (response.data as List).map((x) => DocModel.fromJson(x)).toList();
  }

  Future<List<ContactTicketModel>> fetchTickets() async {
    final response = await _dio.get('/api/support/contact/');
    return (response.data as List)
        .map((x) => ContactTicketModel.fromJson(x))
        .toList();
  }

  Future<void> submitTicket(String subject, String message) async {
    await _dio.post(
      '/api/support/contact/',
      data: {"subject": subject, "message": message},
    );
  }
}

final supportRepositoryProvider = Provider(
  (ref) => SupportRepository(ref.watch(dioProvider)),
);

// Future Providers
final faqsProvider = FutureProvider.autoDispose<List<FaqModel>>((ref) {
  return ref.watch(supportRepositoryProvider).fetchFaqs();
});

final tutorialsProvider = FutureProvider.autoDispose<List<TutorialModel>>((
  ref,
) {
  return ref.watch(supportRepositoryProvider).fetchTutorials();
});

final docsProvider = FutureProvider.autoDispose<List<DocModel>>((ref) {
  return ref.watch(supportRepositoryProvider).fetchDocs();
});

final ticketsProvider = FutureProvider.autoDispose<List<ContactTicketModel>>((
  ref,
) {
  return ref.watch(supportRepositoryProvider).fetchTickets();
});

// Ticket Submission Controller
class SubmitTicketState {
  final bool isLoading;
  final String? error;
  SubmitTicketState({this.isLoading = false, this.error});
}

class SubmitTicketController extends StateNotifier<SubmitTicketState> {
  final SupportRepository _repository;

  SubmitTicketController(this._repository) : super(SubmitTicketState());

  Future<bool> submit(String subject, String message) async {
    state = SubmitTicketState(isLoading: true);
    try {
      await _repository.submitTicket(subject, message);
      state = SubmitTicketState(isLoading: false);
      return true;
    } catch (e) {
      String errorMessage = "Failed to send message";
      if (e is DioException) {
        errorMessage =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            errorMessage;
      }
      state = SubmitTicketState(isLoading: false, error: errorMessage);
      return false;
    }
  }
}

final submitTicketControllerProvider =
    StateNotifierProvider<SubmitTicketController, SubmitTicketState>((ref) {
      return SubmitTicketController(ref.watch(supportRepositoryProvider));
    });
