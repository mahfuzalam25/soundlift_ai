import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class ProjectState {
  final bool isLoading;
  final String? error;
  final int progress;
  final String status;
  final String? downloadUrl;

  ProjectState({
    this.isLoading = false,
    this.error,
    this.progress = 0,
    this.status = 'queued',
    this.downloadUrl,
  });

  ProjectState copyWith({
    bool? isLoading,
    String? error,
    int? progress,
    String? status,
    String? downloadUrl,
    bool clearError = false,
  }) {
    return ProjectState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      progress: progress ?? this.progress,
      status: status ?? this.status,
      downloadUrl: downloadUrl ?? this.downloadUrl,
    );
  }
}

// REPOSITORY
class ProjectRepository {
  final Dio _dio;
  ProjectRepository(this._dio);

  Future<Map<String, dynamic>> createProject({
    required String name,
    required String type,
    required String filePath,
  }) async {
    FormData formData = FormData.fromMap({
      'project_name': name,
      'project_type': type,
      'original_file': await MultipartFile.fromFile(filePath),
    });

    final response = await _dio.post(
      '/api/projects/',
      data: formData,
      options: Options(
        sendTimeout: const Duration(minutes: 10),
        receiveTimeout: const Duration(minutes: 10),
      ),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getProjectStatus(String projectId) async {
    final response = await _dio.get('/api/projects/$projectId/status/');
    return response.data;
  }

  // Fetch all projects
  Future<List<dynamic>> getProjects() async {
    final response = await _dio.get('/api/projects/');
    return response.data;
  }

  // Fetch Download URL
  Future<String> getDownloadUrl(String projectId) async {
    final response = await _dio.get('/api/projects/$projectId/download/');
    return response.data['download_url'];
  }

  Future<Map<String, dynamic>> getProjectDetails(String projectId) async {
    final response = await _dio.get('/api/projects/$projectId/');
    return response.data;
  }
}

final projectRepositoryProvider = Provider(
  (ref) => ProjectRepository(ref.watch(dioProvider)),
);


final projectListProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final repository = ref.watch(projectRepositoryProvider);
  return await repository.getProjects();
});

// CONTROLLER
class ProjectController extends StateNotifier<ProjectState> {
  final ProjectRepository _repository;
  Timer? _pollingTimer;

  ProjectController(this._repository) : super(ProjectState());

  String _extractError(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final data = error.response?.data;
        if (data.containsKey('original_file')) {
          return data['original_file'][0];
        }
        if (data.containsKey('error')) return data['error'];
        return "An API error occurred.";
      }
      return error.message ?? "A network error occurred.";
    }
    return error.toString();
  }

  Future<String?> submitProject({
    required String name,
    required String type,
    required String filePath,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.createProject(
        name: name,
        type: type,
        filePath: filePath,
      );
      state = state.copyWith(isLoading: false);
      return response['id'];
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return null;
    }
  }

  void startPolling(String projectId) {
    state = ProjectState();
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(const Duration(milliseconds: 2500), (
      timer,
    ) async {
      try {
        final data = await _repository.getProjectStatus(projectId);
        final currentStatus = data['job_status'];

        state = state.copyWith(
          status: currentStatus,
          progress: data['progress'],
          downloadUrl: data['processed_file_url'],
        );

        if (currentStatus == 'completed' || currentStatus == 'failed') {
          stopPolling();
        }
      } catch (e) {
        stopPolling();
        state = state.copyWith(error: _extractError(e), status: 'failed');
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

final projectControllerProvider =
    StateNotifierProvider<ProjectController, ProjectState>(
      (ref) => ProjectController(ref.watch(projectRepositoryProvider)),
    );

final projectDetailsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) async {
      return ref.watch(projectRepositoryProvider).getProjectDetails(id);
    });
