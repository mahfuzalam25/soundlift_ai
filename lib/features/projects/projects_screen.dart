import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/project_list_tile.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All'; // Can be 'All', 'Audio', 'Video', or 'Date'

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

  @override
  Widget build(BuildContext context) {
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

          // Search Bar
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: CustomTextField(
              hintText: "Search Project...",
              prefixIcon: Icon(Icons.search, color: AppColors.textGrey),
            ),
          ),

          // Filters Row
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
                  const SizedBox(width: 8),
                  _buildFilterChip("Date", Icons.calendar_today),
                ],
              ),
            ),
          ),

          // Custom Tab Bar
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

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProjectList(filterStatus: 'All'),
                _buildProjectList(filterStatus: 'Processing'),
                _buildProjectList(filterStatus: 'Completed'),
                _buildProjectList(filterStatus: 'Failed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
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

  Widget _buildProjectList({required String filterStatus}) {
    // Dummy dataset carefully constructed without any sensitive or excluded parameters
    final List<Map<String, dynamic>> allProjects = [
      {
        "name": "Corporate_Presentation_Audio.wav",
        "status": "Completed",
        "date": "Today, 10:30 AM",
        "type": Icons.audio_file,
      },
      {
        "name": "Vlog_Travel_Draft.mp4",
        "status": "Processing",
        "date": "Today, 09:15 AM",
        "type": Icons.video_file,
      },
      {
        "name": "Podcast_Ep5_Raw.mp3",
        "status": "Failed",
        "date": "Yesterday, 04:15 PM",
        "type": Icons.audio_file,
      },
      {
        "name": "Client_Interview_Backup.mp4",
        "status": "Completed",
        "date": "Oct 12, 09:00 AM",
        "type": Icons.video_file,
      },
      {
        "name": "Voiceover_Commercial.wav",
        "status": "Completed",
        "date": "Oct 10, 11:20 AM",
        "type": Icons.audio_file,
      },
    ];

    final filteredList = filterStatus == 'All'
        ? allProjects
        : allProjects.where((p) => p['status'] == filterStatus).toList();

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

    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final project = filteredList[index];
        return ProjectListTile(
          projectName: project['name'],
          status: project['status'],
          date: project['date'],
          typeIcon: project['type'],
        );
      },
    );
  }
}
