import 'package:get/get.dart';
import '../api/services/user_service.dart';
import '../api/services/auth_service.dart';
import '../api/models/user.dart';
import '../core/logger.dart';

class ProfileController extends GetxController {
  final UserService _userService = Get.find<UserService>();
  final AuthService _authService = Get.find<AuthService>();

  final Rxn<User> user = Rxn<User>();
  final RxList<Map<String, dynamic>> groups = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    if (!_authService.isLoggedIn()) return;

    isLoading.value = true;
    error.value = null;

    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        error.value = '无法获取当前用户ID';
        return;
      }

      final data = await _userService.getUserProfile(userId);
      if (data != null && data.containsKey('data')) {
        final userData = data['data'];
        user.value = User.fromJson(userData);

        // 处理包含的组信息
        if (data.containsKey('included')) {
          final List<dynamic> included = data['included'];
          groups.value = included
              .where((item) => item['type'] == 'groups')
              .map(
                (item) => {
                  'id': item['id'] as String,
                  'nameSingular': item['attributes']['nameSingular'] as String,
                  'namePlural': item['attributes']['namePlural'] as String,
                  'color': item['attributes']['color'] as String?,
                  'icon': item['attributes']['icon'] as String?,
                },
              )
              .toList();
        }
      } else {
        error.value = '加载用户信息失败';
      }
    } catch (e, stackTrace) {
      logger.error('ProfileController fetchProfile 出错', e, stackTrace);
      error.value = '发生未知错误: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void logout() async {
    await _authService.logout();
    user.value = null;
    groups.clear();
  }
}
