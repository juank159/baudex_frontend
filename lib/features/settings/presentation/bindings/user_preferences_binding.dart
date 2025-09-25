import 'package:get/get.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/network/network_info.dart';
import '../../data/datasources/user_preferences_remote_datasource.dart';
import '../../data/repositories/user_preferences_repository_impl.dart';
import '../../domain/repositories/user_preferences_repository.dart';
import '../../domain/usecases/get_user_preferences_usecase.dart';
import '../../domain/usecases/update_user_preferences_usecase.dart';
import '../controllers/user_preferences_controller.dart';

class UserPreferencesBinding extends Bindings {
  @override
  void dependencies() {
    // Data sources
    Get.lazyPut<UserPreferencesRemoteDataSource>(
      () => UserPreferencesRemoteDataSourceImpl(
        dioClient: Get.find<DioClient>(),
      ),
    );

    // Repository
    Get.lazyPut<UserPreferencesRepository>(
      () => UserPreferencesRepositoryImpl(
        remoteDataSource: Get.find<UserPreferencesRemoteDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
    );

    // Use cases
    Get.lazyPut(() => GetUserPreferencesUseCase(Get.find<UserPreferencesRepository>()));
    Get.lazyPut(() => UpdateUserPreferencesUseCase(Get.find<UserPreferencesRepository>()));

    // Controller
    Get.lazyPut<UserPreferencesController>(
      () => UserPreferencesController(
        getUserPreferencesUseCase: Get.find<GetUserPreferencesUseCase>(),
        updateUserPreferencesUseCase: Get.find<UpdateUserPreferencesUseCase>(),
      ),
    );
  }
}