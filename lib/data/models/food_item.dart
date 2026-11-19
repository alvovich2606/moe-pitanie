class FoodItem {
  final int? id;
  final String name;
  final String? brand;
  final String? barcode;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double fatPer100g;
  final double carbsPer100g;
  final bool isCustom;

  const FoodItem({
    this.id,
    required this.name,
    this.brand,
    this.barcode,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.fatPer100g,
    required this.carbsPer100g,
    this.isCustom = false,
  });

  FoodItem copyWith({
    int? id,
    String? name,
    String? brand,
    String? barcode,
    double? caloriesPer100g,
    double? proteinPer100g,
    double? fatPer100g,
    double? carbsPer100g,
    bool? isCustom,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      barcode: barcode ?? this.barcode,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'brand': brand,
      'barcode': barcode,
      'calories_per_100g': caloriesPer100g,
      'protein_per_100g': proteinPer100g,
      'fat_per_100g': fatPer100g,
      'carbs_per_100g': carbsPer100g,
    };
  }

  factory FoodItem.fromDbMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      brand: map['brand'] as String?,
      barcode: map['barcode'] as String?,
      caloriesPer100g: (map['calories_per_100g'] as num).toDouble(),
      proteinPer100g: (map['protein_per_100g'] as num).toDouble(),
      fatPer100g: (map['fat_per_100g'] as num).toDouble(),
      carbsPer100g: (map['carbs_per_100g'] as num).toDouble(),
      isCustom: true,
    );
  }

  factory FoodItem.fromOpenFoodFactsJson(Map<String, dynamic> json) {
    final nutriments = (json['nutriments'] as Map<String, dynamic>?) ?? {};

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0.0;
    }

    final nameRu = (json['product_name_ru'] as String?)?.trim();
    final nameDefault = (json['product_name'] as String?)?.trim();
    final resolvedName = (nameRu != null && nameRu.isNotEmpty)
        ? nameRu
        : ((nameDefault != null && nameDefault.isNotEmpty)
            ? nameDefault
            : 'Без названия');

    final rawBrand = (json['brands'] as String?)?.trim();
    final brand = (rawBrand != null && rawBrand.isNotEmpty) ? rawBrand : null;

    final rawBarcode = (json['code'] as String?)?.trim();
    final barcode =
        (rawBarcode != null && rawBarcode.isNotEmpty) ? rawBarcode : null;

    double kcal = parseDouble(nutriments['energy-kcal_100g']);
    if (kcal == 0.0) {
      final kj = parseDouble(nutriments['energy-kj_100g']);
      if (kj > 0) {
        kcal = kj / 4.184;
      }
    }

    return FoodItem(
      name: resolvedName,
      brand: brand,
      barcode: barcode,
      caloriesPer100g: double.parse(kcal.toStringAsFixed(1)),
      proteinPer100g: double.parse(
        parseDouble(nutriments['proteins_100g']).toStringAsFixed(1),
      ),
      fatPer100g: double.parse(
        parseDouble(nutriments['fat_100g']).toStringAsFixed(1),
      ),
      carbsPer100g: double.parse(
        parseDouble(nutriments['carbohydrates_100g']).toStringAsFixed(1),
      ),
      isCustom: false,
    );
  }
}