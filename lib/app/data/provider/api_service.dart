import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../model/create_todo_request.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';
import '../model/product_list_response.dart';
import '../model/product_model.dart';
import '../model/todo_list_response.dart';
import '../model/todo_model.dart';

part 'api_service.g.dart';

/// Retrofit REST API interface for DummyJSON
@RestApi()
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  // ---------------- Authentication ---------------- //

  /// Authenticate user credentials
  @POST('/auth/login')
  Future<LoginResponse> login(@Body() LoginRequest request);

  // ---------------- Todos ---------------- //

  /// Fetch paginated list of todos
  @GET('/todos')
  Future<TodoListResponse> getTodos(
    @Query('limit') int limit,
    @Query('skip') int skip,
  );

  /// Create a new todo task
  @POST('/todos/add')
  Future<TodoModel> addTodo(@Body() CreateTodoRequest request);

  /// Update existing todo item
  @PUT('/todos/{id}')
  Future<TodoModel> updateTodo(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  /// Delete a todo task
  @DELETE('/todos/{id}')
  Future<TodoModel> deleteTodo(@Path('id') int id);

  // ---------------- Products ---------------- //

  /// Fetch paginated products list
  @GET('/products')
  Future<ProductListResponse> getProducts(
    @Query('limit') int limit,
    @Query('skip') int skip,
  );

  /// Fetch single product details by id
  @GET('/products/{id}')
  Future<ProductModel> getProductById(@Path('id') int id);

  /// Search products by keyword query
  @GET('/products/search')
  Future<ProductListResponse> searchProducts(@Query('q') String query);
}
