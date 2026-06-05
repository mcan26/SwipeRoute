import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsis;
import '../main.dart'; // for SwipeRouteApp and isSupabaseInitialized if needed
import 'main_container_screen.dart';

// -----------------------------------------------------------------------------
// AUTH SCREEN
// -----------------------------------------------------------------------------
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (!isSupabaseInitialized) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C24),
          title: const Text('Giriş Kapalı', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Güvenlik sebebiyle veritabanı bağlantısı akademik projede devre dışı bırakılmıştır.\n\nLütfen projeyi tam kapasite test etmek için "Ziyaretçi Olarak Devam Et" seçeneğini kullanın.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anladım', style: TextStyle(color: Color(0xFF00FFC2))),
            ),
          ],
        ),
      );
      return;
    }

    // macOS'ta Google Sign-In native olarak desteklenmez ve ekstra yapılandırma gerektirir.
    if (Theme.of(context).platform == TargetPlatform.macOS) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C24),
          title: const Text(
            'macOS Uyarısı',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Google ile Giriş özelliği macOS platformunda test edilirken Google Cloud Client ID yapılandırması gerektirir.\n\nLütfen test etmek için "Ziyaretçi Olarak Devam Et" seçeneğini kullanın.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Anladım',
                style: TextStyle(color: Color(0xFF00FFC2)),
              ),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final gsis.GoogleSignIn googleSignIn = gsis.GoogleSignIn.instance;
      final googleUser = await googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      // Access token için yetkilendirme alıyoruz (v7+ için gerekli)
      final googleAuthorization = await googleUser.authorizationClient
          .authorizationForScopes(['email', 'profile', 'openid']);
      final accessToken = googleAuthorization?.accessToken;

      if (accessToken == null || idToken == null) {
        throw 'Google Login Error: Tokens missing';
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Giriş Hatası: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _emailAuth() async {
    if (!isSupabaseInitialized) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C24),
          title: const Text('Giriş Kapalı', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Güvenlik sebebiyle veritabanı bağlantısı akademik projede devre dışı bırakılmıştır.\n\nLütfen projeyi tam kapasite test etmek için "Ziyaretçi Olarak Devam Et" seçeneğini kullanın.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anladım', style: TextStyle(color: Color(0xFF00FFC2))),
            ),
          ],
        ),
      );
      return;
    }

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }
    if (_isSignUp && _nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen isminizi giriniz.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        final res = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          data: {'full_name': _nameController.text.trim()},
        );
        if (mounted) {
          if (res.session != null) {
            // Otomatik giriş yapıldı (Email onayı kapalıysa)
          } else {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1C1C24),
                title: const Text(
                  'Kayıt Başarılı!',
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  'Hesabınız oluşturuldu.\n\nEğer Supabase üzerinde "Email Confirmations" açıksa, lütfen Gmail kutunuzu (ve Spam klasörünü) kontrol edip onay linkine tıklayın. Aksi takdirde giriş yapamazsınız.',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Tamam',
                      style: TextStyle(color: Color(0xFF00FFC2)),
                    ),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC), // Light Theme
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5A5F).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.explore,
                  size: 64,
                  color: Color(0xFFFF5A5F),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'SwipeRoute',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  color: Colors.black87,
                ),
              ),
              const Text(
                'Kartları Kaydır, Maceranı Tasarla!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),

              _buildSocialButton(
                icon: FontAwesomeIcons.google,
                label: 'Google ile Giriş Yap',
                color: Colors.white,
                textColor: Colors.black87,
                onPressed: _signInWithGoogle,
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.black.withOpacity(0.1)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'veya',
                      style: TextStyle(color: Colors.black26, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.black.withOpacity(0.1)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_isSignUp) ...[
                TextField(
                  controller: _nameController,
                  decoration: _inputDecoration(
                    'Ad Soyad',
                    Icons.person_outline,
                  ),
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailController,
                decoration: _inputDecoration('E-posta', Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: _inputDecoration('Şifre', Icons.lock_outline),
                obscureText: true,
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _emailAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5A5F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isSignUp ? 'Kayıt Ol' : 'Giriş Yap',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(
                  _isSignUp
                      ? 'Zaten bir hesabın var mı? Giriş yap'
                      : 'Hesabın yok mu? Kayıt ol',
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ),

              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const MainContainerScreen(isOfflineOnly: false),
                    ),
                  );
                },
                icon: const Icon(Icons.person_outline, size: 18),
                label: const Text('Ziyaretçi Olarak Devam Et'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF5A5F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.black45),
      labelStyle: const TextStyle(color: Colors.black45, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF5A5F), width: 1.5),
      ),
    );
  }

  Widget _buildSocialButton({
    required dynamic icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: FaIcon(icon, color: textColor, size: 20),
        label: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

