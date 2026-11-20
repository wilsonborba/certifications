// certifications#52: development entry point for the design gallery. The
// app itself starts in main.dart; this target is never deployed.
import 'package:certifications/core/utils/my_theme.dart';
import 'package:certifications/presentation/widgets/design_gallery.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerDesignLicenses();
  runApp(const DesignGallery());
}
