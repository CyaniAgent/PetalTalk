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
    if (!_authService.isLoggedIn()) {
      logger.info('ProfileController: 用户未登录，跳过获取个人资料');
      return;
    }

    isLoading.value = true;
    error.value = null;

    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        logger.warning('ProfileController: 即使已登录也无法获取用户ID');
        error.value = '获取用户信息失败：未找到用户ID';
        return;
      }

      logger.info('ProfileController: 正在为用户 $userId 获取个人资料');

      final data = await _userService.getUserProfile(userId);

      if (data != null && data.containsKey('data')) {
        final userData = data['data'];
        logger.debug('ProfileController: 成功获取用户原始数据: $userData');

        try {
          user.value = User.fromJson(userData);
          logger.info('ProfileController: 成功解析用户: ${user.value?.username}');
        } catch (parseError) {
          logger.error('ProfileController: 解析用户数据失败', parseError);
          error.value = '解析用户信息失败';
          return;
        }

        // 处理包含的组信息
        if (data.containsKey('included')) {
          final List<dynamic> included = data['included'];
          final groupItems = included
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
          groups.value = groupItems;
          logger.info('ProfileController: 成功加载 ${groups.length} 个用户组');
        }
      } else {
        logger.warning('ProfileController: API响应中没有数据或响应为空: $data');
        error.value = '加载用户信息失败：服务器未返回数据';
      }
    } catch (e, stackTrace) {
      logger.error('ProfileController: fetchProfile 发生严重错误', e, stackTrace);
      error.value = '发生错误: $e';
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
