import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/project_list_tile.dart';
import '../../shared/dialogs/custom_snackbar.dart';
import 'providers/project_provider.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final minuteStr = date.minute.toString().padLeft(2, '0');
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final ampm = date.hour >= 12 ? 'PM' : 'AM';
      return "${months[date.month - 1]} ${date.day}, $hour:$minuteStr $ampm";
    } catch (e) {
      return "Unknown Date";
    }
  }

  // DOWNLOAD LOGIC
  Future<void> _handleDownload(
    String projectId,
    String projectName,
    String format,
  ) async {
    try {
      CustomSnackbar.show(context: context, message: "Starting download...");

      final downloadUrl = await ref
          .read(projectRepositoryProvider)
          .getDownloadUrl(projectId);

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception("Could not access local storage.");
      }

      String safeProjectName = projectName.replaceAll(' ', '_');
      String savePath =
          "${directory.path}/${safeProjectName}_processed.$format";

      final dio = Dio();
      await dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // int percentage = ((received / total) * 100).floor();
          }
        },
      );

      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: "Saved successfully to your device:\n$savePath",
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: "Failed to download file. Please check storage permissions.",
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncProjects = ref.watch(projectListProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              "Your Projects",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: CustomTextField(
              hintText: "Search Project...",
              prefixIcon: Icon(Icons.search, color: AppColors.textGrey),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
            ).copyWith(bottom: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip("All", Icons.apps),
                  const SizedBox(width: 8),
                  _buildFilterChip("Audio", Icons.multitrack_audio),
                  const SizedBox(width: 8),
                  _buildFilterChip("Video", Icons.video_file),
                ],
              ),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.textGrey.withOpacity(0.1)),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textGrey,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: "All"),
                Tab(text: "Processing"),
                Tab(text: "Completed"),
                Tab(text: "Failed"),
              ],
            ),
          ),

          Expanded(
            child: asyncProjects.when(
              data: (projects) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProjectList(projects, filterStatus: 'All'),
                    _buildProjectList(projects, filterStatus: 'Processing'),
                    _buildProjectList(projects, filterStatus: 'Completed'),
                    _buildProjectList(projects, filterStatus: 'Failed'),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => const Center(
                child: Text(
                  "Error fetching projects",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.cards,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.textGrey.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textGrey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textGrey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectList(
    List<dynamic> allProjects, {
    required String filterStatus,
  }) {
    final filteredList = allProjects.where((p) {
      final status = p['status'].toString().toLowerCase();
      bool matchesTab = false;

      if (filterStatus == 'All') {
        matchesTab = true;
      } else if (filterStatus == 'Processing') {
        matchesTab = (status == 'processing' || status == 'queued');
      } else {
        matchesTab = (status == filterStatus.toLowerCase());
      }

      bool matchesChip = true;
      final format = p['media_file']?['format']?.toString().toLowerCase() ?? '';
      final videoFormats = ['mp4', 'mov', 'avi', 'mkv'];

      if (_selectedFilter == 'Audio') {
        matchesChip = !videoFormats.contains(format);
      } else if (_selectedFilter == 'Video') {
        matchesChip = videoFormats.contains(format);
      }

      return matchesTab && matchesChip;
    }).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: AppColors.textGrey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "No $filterStatus projects found.",
              style: const TextStyle(color: AppColors.textGrey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.cards,
      onRefresh: () async {
        ref.invalidate(projectListProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(24.0),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final project = filteredList[index];

          final isCompleted = project['status'] == 'completed';
          final format =
              project['media_file']?['format']?.toString().toLowerCase() ??
              'mp4';
          final projectName = project['project_name'];
          final typeIcon = ['mp4', 'mov', 'avi', 'mkv'].contains(format)
              ? Icons.video_file
              : Icons.audio_file;

          String displayStatus = project['status'].toString();
          displayStatus =
              displayStatus[0].toUpperCase() + displayStatus.substring(1);

          return GestureDetector(
            onTap: () {
              if (isCompleted) {
                context.push('/project/${project['id']}');
              } else {
                CustomSnackbar.show(
                  context: context,
                  message:
                      "Media viewer is only available for completed projects.",
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: ProjectListTile(
                projectName: projectName,
                status: displayStatus,
                date: _formatDate(project['created_at']),
                typeIcon: typeIcon,
                trailing: isCompleted
                    ? IconButton(
                        icon: const Icon(
                          Icons.download,
                          color: AppColors.primary,
                        ),
                        onPressed: () =>
                            _handleDownload(project['id'], projectName, format),
                        tooltip: "Download Processed File",
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
