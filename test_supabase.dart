import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  try {
    await Supabase.initialize(
      url: 'https://heegbkehvnyosjzsfjlk.supabase.co',
      anonKey: 'sb_publishable_-frVsX_M3YVDwRLI4Wd0og_OvUKJRMt',
    );
    print("Success");
  } catch (e) {
    print("Error: $e");
  }
}
