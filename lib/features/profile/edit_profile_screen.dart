import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/custom_dropdown_field.dart';
import '../../shared/buttons/primary_button.dart';
import '../../shared/dialogs/custom_snackbar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _bioController;

  String? _selectedCountry = "Bangladesh";
  String? _selectedTimezone = "Asia/Dhaka (+06:00)";

  fp.PlatformFile? _profileImage;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: "Md Mahfuz Alam");
    _lastNameController = TextEditingController(text: "Chowdhury");
    _bioController = TextEditingController(
      text: "Full Stack Developer at meetsfixer",
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
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

  @override
  Widget build(BuildContext context) {
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
            // 1. Profile Picture Area
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
                          : null,
                      child: _profileImage == null
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

            // 2. Form Fields
            const Text(
              "Personal Information",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    hintText: "First Name",
                    controller: _firstNameController,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    hintText: "Last Name",
                    controller: _lastNameController,
                  ),
                ),
              ],
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
              items: const [
                "United States",
                "United Kingdom",
                "Canada",
                "Bangladesh",
                "India",
              ],
              onChanged: (val) => setState(() => _selectedCountry = val),
            ),

            CustomDropdownField(
              hintText: "Timezone",
              value: _selectedTimezone,
              items: const [
                "America/New_York (EST)",
                "Europe/London (GMT)",
                "Asia/Dhaka (+06:00)",
                "Asia/Kolkata (+05:30)",
              ],
              onChanged: (val) => setState(() => _selectedTimezone = val),
            ),

            const SizedBox(height: 40),

            // 3. Save Button
            PrimaryButton(
              text: "Save Changes",
              onPressed: () {
                CustomSnackbar.show(
                  context: context,
                  message: "Profile updated successfully!",
                );
                context.pop();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
