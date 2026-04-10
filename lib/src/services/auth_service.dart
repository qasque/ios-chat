import 'package:mobile/src/models/app_user.dart';
import 'package:mobile/src/services/local_settings_service.dart';

class AuthService {
  static const _idKey = "mobile.user.id";
  static const _emailKey = "mobile.user.email";
  static const _nameKey = "mobile.user.name";

  final LocalSettingsService _settings;

  AuthService(this._settings);

  Future<AppUser?> currentUser() async {
    final id = await _settings.readString(_idKey);
    final email = await _settings.readString(_emailKey);
    final name = await _settings.readString(_nameKey);
    if (id == null || email == null || name == null) return null;
    return AppUser(id: id, email: email, name: name);
  }

  Future<void> signIn({
    required String id,
    required String email,
    required String name,
  }) async {
    await _settings.writeString(_idKey, id.trim());
    await _settings.writeString(_emailKey, email.trim());
    await _settings.writeString(_nameKey, name.trim());
  }
}
