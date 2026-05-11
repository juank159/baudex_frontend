import 'package:get/get.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/network/network_info.dart';
import '../../data/datasources/employee_remote_datasource.dart';
import '../../data/repositories/employee_repository_impl.dart';
import '../../domain/repositories/employee_repository.dart';
import '../controllers/employee_list_controller.dart';

class EmployeeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EmployeeRemoteDataSource>(
      () => EmployeeRemoteDataSourceImpl(dio: Get.find<DioClient>()),
      fenix: true,
    );
    Get.lazyPut<EmployeeRepository>(
      () => EmployeeRepositoryImpl(
        remote: Get.find<EmployeeRemoteDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
      fenix: true,
    );
    Get.lazyPut<EmployeeListController>(
      () => EmployeeListController(repository: Get.find<EmployeeRepository>()),
      fenix: true,
    );
  }
}
