const recipeCategories = {
  'vorspeisen': 'Vorspeisen',
  'hauptgerichte': 'Hauptgerichte',
  'desserts': 'Desserts',
  'salate': 'Salate',
  'suppen': 'Suppen',
  'backen': 'Backen',
  'fruehstueck': 'Frühstück',
  'getraenke': 'Getränke',
  'sonstiges': 'Sonstiges',
};

const recipeCategoryIcons = {
  'vorspeisen': '🥗',
  'hauptgerichte': '🍽️',
  'desserts': '🍰',
  'salate': '🥬',
  'suppen': '🍲',
  'backen': '🍞',
  'fruehstueck': '🥐',
  'getraenke': '🥤',
  'sonstiges': '🍴',
};

const stepCategories = {
  'vorbereitung': 'Vorbereitung',
  'hauptgang': 'Hauptgang',
  'beilage': 'Beilage',
  'garnierung': 'Garnierung',
  'sonstiges': 'Sonstiges',
};

class Recipe {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String? dietaryTags;
  final String? image;
  final int servings;
  final String creatorId;
  final String createdAt;
  final String updatedAt;

  const Recipe({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.dietaryTags,
    this.image,
    required this.servings,
    required this.creatorId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      dietaryTags: json['dietaryTags'] as String?,
      image: json['image'] as String?,
      servings: json['servings'] as int,
      creatorId: json['creatorId'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  String get categoryLabel => recipeCategories[category] ?? category;
}

class RecipeListItem extends Recipe {
  final double? avgRating;
  final int ratingCount;

  const RecipeListItem({
    required super.id,
    required super.title,
    super.description,
    required super.category,
    super.dietaryTags,
    super.image,
    required super.servings,
    required super.creatorId,
    required super.createdAt,
    required super.updatedAt,
    this.avgRating,
    this.ratingCount = 0,
  });

  factory RecipeListItem.fromJson(Map<String, dynamic> json) {
    return RecipeListItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      dietaryTags: json['dietaryTags'] as String?,
      image: json['image'] as String?,
      servings: json['servings'] as int,
      creatorId: json['creatorId'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      avgRating: (json['avgRating'] as num?)?.toDouble(),
      ratingCount: json['ratingCount'] as int? ?? 0,
    );
  }
}

class RecipeDetail extends Recipe {
  final double? avgRating;
  final int ratingCount;
  final bool isBookmarked;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;

  const RecipeDetail({
    required super.id,
    required super.title,
    super.description,
    required super.category,
    super.dietaryTags,
    super.image,
    required super.servings,
    required super.creatorId,
    required super.createdAt,
    required super.updatedAt,
    this.avgRating,
    this.ratingCount = 0,
    this.isBookmarked = false,
    this.ingredients = const [],
    this.steps = const [],
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    return RecipeDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      dietaryTags: json['dietaryTags'] as String?,
      image: json['image'] as String?,
      servings: json['servings'] as int,
      creatorId: json['creatorId'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      avgRating: (json['avgRating'] as num?)?.toDouble(),
      ratingCount: json['ratingCount'] as int? ?? 0,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      ingredients: (json['ingredients'] as List? ?? [])
          .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List? ?? [])
          .map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RecipeIngredient {
  final String id;
  final double amount;
  final String unit;
  final String name;
  final int order;

  const RecipeIngredient({
    required this.id,
    required this.amount,
    required this.unit,
    required this.name,
    this.order = 0,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
      name: json['name'] as String,
      order: json['order'] as int? ?? 0,
    );
  }
}

class RecipeStep {
  final String id;
  final String category;
  final String? title;
  final String description;
  final int order;

  const RecipeStep({
    required this.id,
    required this.category,
    this.title,
    required this.description,
    this.order = 0,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String?,
      description: json['description'] as String,
      order: json['order'] as int? ?? 0,
    );
  }

  String get categoryLabel => stepCategories[category] ?? category;
}

class RecipeReview {
  final String id;
  final String recipeId;
  final String userId;
  final int rating;
  final String? comment;
  final String createdAt;

  const RecipeReview({
    required this.id,
    required this.recipeId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory RecipeReview.fromJson(Map<String, dynamic> json) {
    return RecipeReview(
      id: json['id'] as String,
      recipeId: json['recipeId'] as String,
      userId: json['userId'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }
}

class RecipeListResponse {
  final List<RecipeListItem> data;
  final PaginationMeta meta;

  const RecipeListResponse({required this.data, required this.meta});

  factory RecipeListResponse.fromJson(Map<String, dynamic> json) {
    final recipes = (json['data'] as List)
        .map((e) => RecipeListItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>);
    return RecipeListResponse(data: recipes, meta: meta);
  }
}

class RecipeDetailResponse {
  final RecipeDetail data;

  const RecipeDetailResponse({required this.data});

  factory RecipeDetailResponse.fromJson(Map<String, dynamic> json) {
    return RecipeDetailResponse(
      data: RecipeDetail.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class RecipeBookmarkListResponse {
  final List<RecipeListItem> data;
  final PaginationMeta meta;

  const RecipeBookmarkListResponse({required this.data, required this.meta});

  factory RecipeBookmarkListResponse.fromJson(Map<String, dynamic> json) {
    final recipes = (json['data'] as List)
        .map((e) => RecipeListItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>);
    return RecipeBookmarkListResponse(data: recipes, meta: meta);
  }
}

class RecipeReviewListResponse {
  final List<RecipeReview> data;
  final PaginationMeta meta;

  const RecipeReviewListResponse({required this.data, required this.meta});

  factory RecipeReviewListResponse.fromJson(Map<String, dynamic> json) {
    final reviews = (json['data'] as List)
        .map((e) => RecipeReview.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>);
    return RecipeReviewListResponse(data: reviews, meta: meta);
  }
}

class RecipeBookmarkStatus {
  final bool bookmarked;

  const RecipeBookmarkStatus({required this.bookmarked});

  factory RecipeBookmarkStatus.fromJson(Map<String, dynamic> json) {
    return RecipeBookmarkStatus(bookmarked: json['bookmarked'] as bool);
  }
}

class PaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  bool get hasMore => page < totalPages;
}

class RecipeCreateRequest {
  final String title;
  final String? description;
  final String category;
  final String? dietaryTags;
  final String? image;
  final int servings;
  final List<RecipeIngredientCreateRequest>? ingredients;
  final List<RecipeStepCreateRequest>? steps;

  const RecipeCreateRequest({
    required this.title,
    this.description,
    required this.category,
    this.dietaryTags,
    this.image,
    this.servings = 4,
    this.ingredients,
    this.steps,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'title': title,
      'category': category,
      'servings': servings,
    };
    if (description != null) map['description'] = description;
    if (dietaryTags != null) map['dietaryTags'] = dietaryTags;
    if (image != null) map['image'] = image;
    if (ingredients != null) {
      map['ingredients'] = ingredients!.map((e) => e.toJson()).toList();
    }
    if (steps != null) {
      map['steps'] = steps!.map((e) => e.toJson()).toList();
    }
    return map;
  }
}

class RecipeUpdateRequest {
  final String? title;
  final String? description;
  final String? category;
  final String? dietaryTags;
  final String? image;
  final int? servings;
  final List<RecipeIngredientCreateRequest>? ingredients;
  final List<RecipeStepCreateRequest>? steps;

  const RecipeUpdateRequest({
    this.title,
    this.description,
    this.category,
    this.dietaryTags,
    this.image,
    this.servings,
    this.ingredients,
    this.steps,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    if (category != null) map['category'] = category;
    if (dietaryTags != null) map['dietaryTags'] = dietaryTags;
    if (image != null) map['image'] = image;
    if (servings != null) map['servings'] = servings;
    if (ingredients != null) {
      map['ingredients'] = ingredients!.map((e) => e.toJson()).toList();
    }
    if (steps != null) {
      map['steps'] = steps!.map((e) => e.toJson()).toList();
    }
    return map;
  }
}

class RecipeIngredientCreateRequest {
  final double amount;
  final String unit;
  final String name;
  final int order;

  const RecipeIngredientCreateRequest({
    required this.amount,
    required this.unit,
    required this.name,
    this.order = 0,
  });

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'unit': unit,
    'name': name,
    'order': order,
  };
}

class RecipeStepCreateRequest {
  final String category;
  final String? title;
  final String description;
  final int order;

  const RecipeStepCreateRequest({
    this.category = 'sonstiges',
    this.title,
    required this.description,
    this.order = 0,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'category': category,
      'description': description,
      'order': order,
    };
    if (title != null) map['title'] = title;
    return map;
  }
}

class RecipeReviewCreateRequest {
  final int rating;
  final String? comment;

  const RecipeReviewCreateRequest({required this.rating, this.comment});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'rating': rating};
    if (comment != null) map['comment'] = comment;
    return map;
  }
}

class RecipeReviewUpdateRequest {
  final int? rating;
  final String? comment;

  const RecipeReviewUpdateRequest({this.rating, this.comment});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (rating != null) map['rating'] = rating;
    if (comment != null) {
      map['comment'] = comment;
    } else {
      map['comment'] = null;
    }
    return map;
  }
}
