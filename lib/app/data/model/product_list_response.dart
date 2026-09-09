import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'product_model.dart';

part 'product_list_response.g.dart';

/// Paginated product list response
@JsonSerializable()
class ProductListResponse extends Equatable {
  final List<ProductModel> products;
  final int total;
  final int skip;
  final int limit;

  const ProductListResponse({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory ProductListResponse.fromJson(Map<String, dynamic> json) =>
      _$ProductListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ProductListResponseToJson(this);

  @override
  List<Object?> get props => [products, total, skip, limit];
}
