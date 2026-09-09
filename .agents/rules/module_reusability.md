---
description: Quy tắc thiết kế và tái sử dụng module GetX trong dự án Flutter
trigger: always_on
---

# Quy Tắc Tái Sử Dụng Module GetX

Khi tạo mới hoặc mở rộng các module trong `lib/app/modules/`:

1. **Bộ 4 thành phần bắt buộc:**
   - `<feature>_page.dart`: Kế thừa `GetView<<Feature>Controller>`, chỉ chứa UI, không xử lý business logic.
   - `<feature>_controller.dart`: Kế thừa `GetxController`, quản lý `Rx` state, phụ thuộc vào một Repository.
   - `<feature>_binding.dart`: Kế thừa `Bindings`, khai báo `Get.lazyPut` cho Controller và Repository.
   - `<feature>_repository.dart`: Tầng IO, gọi API qua `ApiProvider.safeCall<T>()`.

2. **Quy tắc nhúng/tái sử dụng Page:**
   - Nếu nhúng Widget/Page từ Module A vào Module B (ví dụ dùng `IndexedStack` hoặc `TabBar`):
     - `BBinding` phải đăng ký Controller & Repository của Module A.
     - Luôn dùng `Get.lazyPut` hoặc kiểm tra `Get.isRegistered<AController>()`.

3. **Quy tắc tái sử dụng Service/Repository:**
   - Dùng `Get.find<T>()` để lấy thể hiện đã được khởi tạo.
   - Các Service/Provider toàn cục (`ApiProvider`, `LoadingService`) được quản lý ở `InitialBinding` với `permanent: true`.

4. **Style & Resource Guidelines:**
   - Màu sắc: `AppColors.*` hoặc `AppColor.*`.
   - Typography: `AppTextStyles.*` hoặc `AppTextStyle.*`.
   - Chuỗi: Khai báo từ khóa trong `en_us.dart` & `vi_vn.dart` và gọi `'key'.tr`.
   - Comment ngắn gọn, súc tích.
