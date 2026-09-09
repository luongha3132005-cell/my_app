# Quy Tắc Phát Triển & Tái Sử Dụng Module (Flutter + GetX)

Tài liệu này định nghĩa các quy tắc chuẩn để tạo mới và tái sử dụng các module trong dự án `my_app`.

---

## 1. Cấu Trúc Chuẩn Cho Mỗi Module

Mỗi tính năng được tổ chức độc lập trong thư mục `lib/app/modules/<feature_name>/`:

```
lib/app/modules/<feature_name>/
├── <feature_name>_page.dart         # Giao diện (UI only), kế thừa GetView<<Feature>Controller>
├── <feature_name>_controller.dart   # Quản lý state (Rx), vòng đời và logic nghiệp vụ
├── <feature_name>_binding.dart      # Đăng ký Dependency Injection (DI) qua Get.lazyPut
└── <feature_name>_repository.dart   # Tầng dữ liệu nghiệp vụ, gọi ApiProvider.safeCall<T>()
```

---

## 2. Quy Tắc Tái Sử Dụng Giữa Các Module

### A. Tái sử dụng Page làm Widget/Tab con (ví dụ nhúng vào HomePage)
1. **Đăng ký Binding cấp cha:**
   - Khi trang cha (như `HomePage`) nhúng `TodoPage` hay `ProductPage`, `HomeBinding` **phải đăng ký sẵn** Repository và Controller của các trang con:
   ```dart
   class HomeBinding extends Bindings {
     @override
     void dependencies() {
       Get.lazyPut<HomeController>(() => HomeController());
       // Đăng ký module con để trang con GetView có thể tìm thấy Controller
       Get.lazyPut<TodoRepository>(() => TodoRepository());
       Get.lazyPut<TodoController>(() => TodoController(repository: Get.find<TodoRepository>()));
     }
   }
   ```
2. **Tránh lỗi Dependency:**
   - Trước khi gọi `Get.find<SomeController>()`, luôn kiểm tra `Get.isRegistered<SomeController>()` nếu controller đó có thể chưa được nạp.

### B. Tái sử dụng Repository giữa các Controller
- Một Controller có thể phụ thuộc vào một Repository từ module khác nếu cần dữ liệu liên quan:
  ```dart
  class OrderController extends GetxController {
    final ProductRepository productRepository;
    OrderController({required this.productRepository});
  }
  ```
- Nếu Repository được dùng ở nhiều hơn 2 module độc lập, hãy đưa nó vào `lib/app/data/repositories/`.

### C. Giao tiếp State giữa các Controller
- Truy xuất Controller khác:
  ```dart
  final authController = Get.find<AuthController>();
  ```
- Lắng nghe thay đổi dữ liệu từ Controller khác bằng Worker:
  ```dart
  @override
  void onInit() {
    super.onInit();
    // Tự động reload khi người dùng đăng nhập/đổi tài khoản
    ever(Get.find<AuthController>().currentUser, (_) => reloadData());
  }
  ```

---

## 3. Quy Chuẩn Điều Hướng (Routing)

- **Không hardcode string:** Luôn khai báo hằng số trong [`app_routes.dart`](file:///d:/dev/my_app/lib/app/routes/app_routes.dart).
- **Đăng ký route:** Luôn đăng ký `GetPage` kèm theo `binding` tương ứng trong [`app_pages.dart`](file:///d:/dev/my_app/lib/app/routes/app_pages.dart).
- **Chuyển màn hình:** Sử dụng `Get.toNamed(AppRoutes.xyz)` hoặc `Get.offAllNamed(AppRoutes.xyz)`.

---

## 4. Quy Chuẩn UI & Theme

- **Màu sắc:** Luôn sử dụng [`AppColors`](file:///d:/dev/my_app/lib/app/core/theme/app_colors.dart) hoặc `AppColor` (ví dụ `AppColor.primary`, `AppColor.surfaceLight`).
- **Typography:** Luôn sử dụng [`AppTextStyles`](file:///d:/dev/my_app/lib/app/core/theme/app_text_style.dart) hoặc `AppTextStyle` (ví dụ `AppTextStyle.titleLarge`, `AppTextStyle.bodyMedium`).
- **Văn bản:** Luôn sử dụng `.tr` để hỗ trợ đa ngôn ngữ (Tiếng Anh + Tiếng Việt).
- **Comment:** Viết comment ngắn gọn, súc tích giải thích vai trò của class và method.
