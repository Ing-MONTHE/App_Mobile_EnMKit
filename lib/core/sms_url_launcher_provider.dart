import 'package:enmkit/core/sms_url_launcher_service.dart';
import 'package:enmkit/repositories/kit_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enmkit/core/db_service.dart';

/// Provider pour le service SMS avec URL Launcher
/// À utiliser en alternative au smsService classique
final smsUrlLauncherServiceProvider = Provider<SmsUrlLauncherService>((ref) {
  final dbService = DBService();
  final kitRepo = KitRepository(dbService);
  return SmsUrlLauncherService(kitRepo);
});
