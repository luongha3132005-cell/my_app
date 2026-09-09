import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

/// Product item entity
@JsonSerializable()
class ProductModel extends Equatable {
  final int id;
  final String title;
  final String? description;
  final String? category;
  final double price;
  final double? discountPercentage;
  final double? rating;
  final int? stock;
  final String? brand;
  final String? thumbnail;
  final List<String>? images;

  const ProductModel({
    required this.id,
    required this.title,
    this.description,
    this.category,
    required this.price,
    this.discountPercentage,
    this.rating,
    this.stock,
    this.brand,
    this.thumbnail,
    this.images,
  });

  /// Calculate discounted price
  double get discountedPrice {
    if (discountPercentage == null || discountPercentage! <= 0) return price;
    return price * (1 - discountPercentage! / 100);
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        price,
        discountPercentage,
        rating,
        stock,
        brand,
        thumbnail,
        images,
      ];
}
