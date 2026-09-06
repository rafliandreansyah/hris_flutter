/// Model respons dari endpoint `/auth/menus`.
class MenuResponseModel {
  final bool success;
  final String? message;
  final List<MenuItemModel> data;

  const MenuResponseModel({
    required this.success,
    this.message,
    this.data = const [],
  });

  factory MenuResponseModel.fromJson(Map<String, dynamic> json) {
    return MenuResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (message != null) 'message': message,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

/// Model item menu individual dari `/auth/menus`.
class MenuItemModel {
  final String id;
  final String name;
  final String code;
  final String? platform;
  final String? description;
  final String? icon;
  final String? path;
  final String? parentId;
  final int? order;
  final dynamic status;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.code,
    this.platform,
    this.description,
    this.icon,
    this.path,
    this.parentId,
    this.order,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      platform: json['platform'] as String?,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      path: json['path'] as String?,
      parentId: json['parentId'] as String?,
      order: (json['order'] as num?)?.toInt(),
      status: json['status'],
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      deletedAt: json['deletedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'platform': platform,
      'description': description,
      'icon': icon,
      'path': path,
      'parentId': parentId,
      'order': order,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
    };
  }
}
