import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/custom_dropdown_field.dart';
import '../../shared/buttons/primary_button.dart';
import '../../shared/dialogs/custom_snackbar.dart';
import 'profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;

  String? _selectedCountry;
  String? _selectedTimezone;

  fp.PlatformFile? _profileImage;

  final List<String> _countries = [
    "United States",
    "United Kingdom",
    "Canada",
    "Bangladesh",
    "India",
  ];

  final List<String> _timezones = [
    "America/New_York (EST)",
    "Europe/London (GMT)",
    "Asia/Dhaka (+06:00)",
    "Asia/Kolkata (+05:30)",
  ];

  @override
  void initState() {
    super.initState();

    // Read the current profile
    final profile = ref.read(profileControllerProvider).profile;

    _nameController = TextEditingController(text: profile?.name ?? "");
    _emailController = TextEditingController(text: profile?.email ?? "");
    _bioController = TextEditingController(text: profile?.bio ?? "");

    if (profile != null && _countries.contains(profile.country)) {
      _selectedCountry = profile.country;
    } else {
      _selectedCountry = "Bangladesh";
    }

    if (profile != null && _timezones.contains(profile.timezone)) {
      _selectedTimezone = profile.timezone;
    } else {
      _selectedTimezone = "Asia/Dhaka (+06:00)";
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
        type: fp.FileType.image,
      );

      if (result != null) {
        setState(() {
          _profileImage = result.files.first;
        });

        if (mounted) {
          CustomSnackbar.show(
            context: context,
            message: "Profile picture selected!",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: "Failed to pick image. Please try again.",
          isError: true,
        );
      }
    }
  }

  void _handleSave() async {
    final success = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(
          bio: _bioController.text.trim(),
          country: _selectedCountry ?? "",
          timezone: _selectedTimezone ?? "",
          profilePicturePath: _profileImage?.path,
        );

    if (success && mounted) {
      CustomSnackbar.show(
        context: context,
        message: "Profile updated successfully!",
      );
      context.pop();
    } else if (mounted) {
      final error = ref.read(profileControllerProvider).error;
      CustomSnackbar.show(
        context: context,
        message: error ?? "Update failed",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cards,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.cards,
                      backgroundImage:
                          _profileImage != null && _profileImage!.path != null
                          ? FileImage(File(_profileImage!.path!))
                                as ImageProvider
                          : (profile?.profilePicture != null
                                ? NetworkImage(profile!.profilePicture!)
                                : null),
                      child:
                          _profileImage == null &&
                              profile?.profilePicture == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickProfileImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Form Fields
            const Text(
              "Personal Information",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Read-Only Fields
            IgnorePointer(
              child: Opacity(
                opacity: 0.5,
                child: Column(
                  children: [
                    CustomTextField(
                      hintText: "Full Name",
                      controller: _nameController,
                    ),
                    CustomTextField(
                      hintText: "Email",
                      controller: _emailController,
                    ),
                  ],
                ),
              ),
            ),

            CustomTextField(
              hintText: "Bio",
              controller: _bioController,
              keyboardType: TextInputType.multiline,
            ),

            const SizedBox(height: 24),
            const Text(
              "Location Details",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            CustomDropdownField(
              hintText: "Country",
              value: _selectedCountry,
              items: _countries,
              onChanged: (val) => setState(() => _selectedCountry = val),
            ),

            CustomDropdownField(
              hintText: "Timezone",
              value: _selectedTimezone,
              items: _timezones,
              onChanged: (val) => setState(() => _selectedTimezone = val),
            ),

            const SizedBox(height: 40),

            // Save Button
            PrimaryButton(
              text: "Save Changes",
              isLoading: profileState.isLoading,
              onPressed: profileState.isLoading ? () {} : _handleSave,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
