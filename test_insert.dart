import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  try {
    await Supabase.initialize(
      url: 'https://heegbkehvnyosjzsfjlk.supabase.co',
      anonKey: 'sb_publishable_-frVsX_M3YVDwRLI4Wd0og_OvUKJRMt',
    );
    // Since we can't easily auth a user in a script without a password,
    // we can try an anonymous insert. It will probably fail with RLS.
    // Let's just try to read the schema.
    final res = await Supabase.instance.client.from('saved_routes').select().limit(1);
    print(res);
  } catch (e) {
    print("Error: $e");
  }
}
