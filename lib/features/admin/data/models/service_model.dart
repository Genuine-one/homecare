/// KLE HOMECARE — Service Catalogue Model
/// Mirrors the backend Service document exactly.
/// All ObjectIds are plain strings.
class ServiceModel {
  final String  id;
  final String  name;
  final String  description;
  final String  category;
  final String? icon;
  final bool    isActive;
  final String  createdBy;
  final String? updatedBy;
  final String  createdAt;
  final String  updatedAt;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.icon,
    required this.isActive,
    required this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> j) => ServiceModel(
        id:          j['id']          as String,
        name:        j['name']        as String,
        description: j['description'] as String,
        category:    j['category']    as String,
        icon:        j['icon']        as String?,
        isActive:    j['is_active']   as bool,
        createdBy:   j['created_by']  as String,
        updatedBy:   j['updated_by']  as String?,
        createdAt:   j['created_at']  as String,
        updatedAt:   j['updated_at']  as String,
      );

  Map<String, dynamic> toJson() => {
        'id':          id,
        'name':        name,
        'description': description,
        'category':    category,
        'icon':        icon,
        'is_active':   isActive,
        'created_by':  createdBy,
        'updated_by':  updatedBy,
        'created_at':  createdAt,
        'updated_at':  updatedAt,
      };

  ServiceModel copyWith({
    String? name,
    String? description,
    String? category,
    String? icon,
    bool?   isActive,
  }) =>
      ServiceModel(
        id:          id,
        name:        name        ?? this.name,
        description: description ?? this.description,
        category:    category    ?? this.category,
        icon:        icon        ?? this.icon,
        isActive:    isActive    ?? this.isActive,
        createdBy:   createdBy,
        updatedBy:   updatedBy,
        createdAt:   createdAt,
        updatedAt:   updatedAt,
      );
}
