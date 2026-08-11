import 'package:flutter/material.dart';

// ── InheritedWidget ───────────────────────────────────────────────────────────

class LangScope extends InheritedWidget {
  const LangScope({super.key, required this.lang, required super.child});
  final String lang;

  static String of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LangScope>()?.lang ?? 'en';

  @override
  bool updateShouldNotify(LangScope old) => old.lang != lang;
}

// ── Strings accessor ──────────────────────────────────────────────────────────

class S {
  const S._(this.lang);
  final String lang;
  bool get _vi => lang == 'vi';

  static S of(BuildContext context) => S._(LangScope.of(context));

  // ── Bottom nav ──────────────────────────────────────────────────────────────
  String get navHome => _vi ? 'Trang chủ' : 'Home';
  String get navSearch => _vi ? 'Tìm kiếm' : 'Search';
  String get navRecs => _vi ? 'Gợi ý' : 'Recs';
  String get navFavorites => _vi ? 'Yêu thích' : 'Favorites';

  // ── Shared ──────────────────────────────────────────────────────────────────
  String get cancel => _vi ? 'Hủy' : 'Cancel';
  String get delete => _vi ? 'Xóa' : 'Delete';
  String get retry => _vi ? 'Thử lại' : 'Retry';
  String get save => _vi ? 'Lưu' : 'Save';

  // ── Greeting ────────────────────────────────────────────────────────────────
  String get goodMorning => _vi ? 'Chào buổi sáng 🌅' : 'Good morning 🌅';
  String get goodAfternoon => _vi ? 'Chào buổi chiều ☀️' : 'Good afternoon ☀️';
  String get goodEvening => _vi ? 'Chào buổi tối 🌙' : 'Good evening 🌙';

  // ── Home screen ─────────────────────────────────────────────────────────────
  String get myRecipes => _vi ? 'Công thức của tôi' : 'My Recipes';
  String recipeCount(int n) => _vi ? '$n công thức' : '$n recipe${n == 1 ? '' : 's'}';
  String get noRecipesYet => _vi ? 'Chưa có công thức nào' : 'No recipes yet';
  String get noRecipesDesc =>
      _vi ? 'Thêm công thức của bạn và chia sẻ sáng tạo ẩm thực' : 'Add your own recipes and share your culinary creations';
  String get addFirstRecipe => _vi ? 'Thêm công thức đầu tiên' : 'Add your first recipe';
  String get unableToLoadRecipes => _vi ? 'Không thể tải công thức.' : 'Unable to load recipes.';
  String get fillAllFields => _vi ? 'Vui lòng điền đầy đủ thông tin.' : 'Please fill in all required fields.';
  String get unableToSaveRecipe => _vi ? 'Không thể lưu công thức.' : 'Unable to save recipe.';

  // Add recipe panel
  String get newRecipeTitle => _vi ? 'Công thức mới' : 'New Recipe';
  String get recipeNameHint => _vi ? 'Tên công thức…' : 'Recipe name…';
  String get minSuffix => _vi ? 'phút' : 'min';
  String get calSuffix => _vi ? 'calo' : 'cal';
  String get ingredientsLabel => _vi ? 'Nguyên liệu' : 'Ingredients';
  String ingredientHint(int i) => _vi ? 'Nguyên liệu ${i + 1}' : 'Ingredient ${i + 1}';
  String get addIngredient => _vi ? 'Thêm nguyên liệu' : 'Add ingredient';
  String get instructionsLabel => _vi ? 'Hướng dẫn' : 'Instructions';
  String stepHint(int i) => _vi ? 'Bước ${i + 1}...' : 'Step ${i + 1}...';
  String get addStep => _vi ? 'Thêm bước' : 'Add step';
  String get labelsLabel => _vi ? 'Nhãn' : 'Labels';
  String get saveRecipe => _vi ? 'Lưu công thức' : 'Save Recipe';

  // ── Search screen ───────────────────────────────────────────────────────────
  String get searchRecipesTitle => _vi ? 'Tìm kiếm công thức' : 'Search Recipes';
  String get searchHint => _vi ? 'Tìm công thức, nguyên liệu...' : 'Search recipes, ingredients...';
  String get popularCategories => _vi ? 'Danh mục phổ biến' : 'Popular categories';
  String get recentRecipes => _vi ? 'Công thức gần đây' : 'Recent recipes';
  String resultCount(int n) => _vi ? '$n kết quả' : '$n result${n == 1 ? '' : 's'}';
  String get unableToSearch => _vi ? 'Không thể tìm kiếm công thức.' : 'Unable to search recipes.';

  // Search category display labels (values stay English for API filtering)
  String categoryDisplay(String value) {
    if (!_vi) return value;
    const map = {
      'Breakfast': 'Bữa sáng',
      'Lunch': 'Bữa trưa',
      'Dinner': 'Bữa tối',
      'Quick Meals': 'Nấu nhanh',
      'Alcoholic': 'Có cồn',
      'Beverage': 'Đồ uống',
      'Dairy Free': 'Không sữa',
      'Gluten Free': 'Không gluten',
      'Nut Free': 'Không hạt',
      'Pescetarian': 'Hải sản',
      'Vegan': 'Thuần chay',
      'Vegetarian': 'Ăn chay',
    };
    return map[value] ?? value;
  }

  // ── Favorites screen ────────────────────────────────────────────────────────
  String get favoritesTitle => _vi ? 'Yêu thích' : 'Favorites';
  String get savedRecipesWithNotes => _vi ? 'Công thức đã lưu kèm ghi chú' : 'Saved recipes with your notes';
  String get savedLabel => _vi ? 'Đã lưu' : 'Saved';
  String get withNotesLabel => _vi ? 'Có ghi chú' : 'With Notes';
  String get noFavoritesYet => _vi ? 'Chưa có yêu thích' : 'No favorites yet';
  String get removeFromFavorites => _vi ? 'Xóa khỏi yêu thích?' : 'Remove from favorites?';
  String removeConfirm(String name) => _vi
      ? 'Bạn có muốn xóa "$name" khỏi danh sách đã lưu?'
      : 'Do you want to remove "$name" from your saved recipes?';
  String get unfavoriteLabel => _vi ? 'Bỏ yêu thích' : 'Unfavorite';
  String get myNote => _vi ? 'Ghi chú của tôi' : 'My Note';
  String get writeNoteHint => _vi ? 'Viết ghi chú...' : 'Write your note...';
  String get saveNote => _vi ? 'Lưu ghi chú' : 'Save Note';
  String get addNote => _vi ? 'Thêm ghi chú' : 'Add Note';
  String get editNote => _vi ? 'Sửa ghi chú' : 'Edit Note';
  String get unableToLoadFavorites => _vi ? 'Không thể tải yêu thích.' : 'Unable to load favorites.';

  // ── AI Recs screen ──────────────────────────────────────────────────────────
  String get aiCompanion => _vi ? 'Trợ lý AI' : 'AI Companion';
  String phaseLabel(String phase) => _vi ? 'Giai đoạn: $phase' : 'Phase: $phase';
  String get startingSession => _vi ? 'Đang khởi động phiên trợ lý...' : 'Starting companion session...';
  String get waitingForAi => _vi ? 'Đang chờ phản hồi từ AI...' : 'Queued — waiting for AI...';
  String get resetChatTitle => _vi ? 'Đặt lại cuộc trò chuyện?' : 'Reset chat?';
  String get resetChatDesc =>
      _vi ? 'Thao tác này sẽ xóa cuộc trò chuyện và các dữ liệu đã nhận diện. Tùy chọn hồ sơ vẫn được giữ nguyên.'
          : 'This clears the conversation and compose detections. Your profile preferences stay the same.';
  String get resetLabel => _vi ? 'Đặt lại' : 'Reset';
  String get askForRecipesHint => _vi ? 'Hỏi về công thức...' : 'Ask for recipes...';
  String get editDishesLabel => _vi ? 'Sửa món ăn' : 'Edit dishes';
  String get editIngredientsLabel => _vi ? 'Sửa nguyên liệu' : 'Edit ingredients';
  String unableToOpenRecipe(String name) =>
      _vi ? 'Không thể mở chi tiết "$name".' : 'Could not open details for "$name".';
  String get unableToReachAi =>
      _vi ? 'Không thể kết nối với trợ lý AI. Vui lòng thử lại.' : 'Unable to reach AI assistant. Please try again.';

  // ── Recipe detail / cooking mode ────────────────────────────────────────────
  String get addPhoto => _vi ? 'Thêm ảnh' : 'Add Photo';
  String get recipeTitleHint => _vi ? 'Tên món ăn...' : 'Recipe title...';
  String get changePhoto => _vi ? 'Đổi ảnh' : 'Change Photo';

  String get startCooking => _vi ? 'Bắt đầu nấu' : 'Start Cooking';
  String get prepareIngredients => _vi ? 'Chuẩn bị nguyên liệu' : 'Prepare Ingredients';
  String stepOf(int step, int total) => _vi ? 'Bước $step / $total' : 'Step $step of $total';
  String stepLabel(int n) => _vi ? 'Bước $n' : 'Step $n';
  String ofTotal(int n) => _vi ? '/ $n' : 'of $n';
  String get getReady => _vi ? 'Sẵn sàng thôi' : 'Get Ready';
  String ingredientsToPrepare(int n) =>
      _vi ? '$n nguyên liệu cần chuẩn bị' : '$n ingredient${n == 1 ? '' : 's'} to prepare';
  String estimatedTimePerStep(int m) => _vi ? '~$m phút' : '~$m min';
  String get takeYourTimeWithStep => _vi ? 'Hãy từ từ với bước này' : 'Take your time with this step';
  String get takeYourTime => _vi ? 'Hãy từ từ — nhấn Tiếp khi sẵn sàng' : 'Take your time — tap Next when ready';
  String get back => _vi ? 'Quay lại' : 'Back';
  String get next => _vi ? 'Tiếp' : 'Next';
  String get finish => _vi ? 'Hoàn thành! 🎉' : 'Finish! 🎉';
  String get edit => _vi ? 'Chỉnh sửa' : 'Edit';
  String get saved => _vi ? 'Đã lưu' : 'Saved';
  String get completed => _vi ? 'Hoàn thành!' : 'Completed!';
  String get greatJobChef => _vi ? 'Bạn nấu quá tuyệt! 👨‍🍳' : 'Great job chef 👨‍🍳';
  String cookingMinutesDisplay(int m) => _vi ? '$m phút' : '$m min';

  // ── Profile screen ──────────────────────────────────────────────────────────
  String get yourProfile => _vi ? 'Hồ sơ của bạn' : 'Your Profile';
  String get settingsPreferences => _vi ? 'Cài đặt & tùy chọn' : 'Settings & preferences';
  String get appearance => _vi ? 'Giao diện' : 'Appearance';
  String get themeLabel => _vi ? 'Chủ đề' : 'Theme';
  String get darkMode => _vi ? 'Chế độ tối' : 'Dark mode';
  String get lightMode => _vi ? 'Chế độ sáng' : 'Light mode';
  String get languageLabel => _vi ? 'Ngôn ngữ' : 'Language';
  String get langVietnamese => 'Tiếng Việt';
  String get langEnglish => 'English';
  String get personalInformation => _vi ? 'Thông tin cá nhân' : 'Personal Information';
  String get updateProfileDetails => _vi ? 'Cập nhật thông tin hồ sơ' : 'Update your profile details';
  String get fullNameLabel => _vi ? 'Họ và tên' : 'Full Name';
  String get emailLabel => 'Email';
  String get ageLabel => _vi ? 'Tuổi' : 'Age';
  String get weightLabel => _vi ? 'Cân nặng (kg)' : 'Weight (kg)';
  String get nutritionGoals => _vi ? 'Mục tiêu dinh dưỡng' : 'Nutrition Goals';
  String get setDietaryObjectives => _vi ? 'Đặt mục tiêu dinh dưỡng' : 'Set your dietary objectives';
  String get primaryGoalLabel => _vi ? 'Mục tiêu chính' : 'Primary Goal';
  String get dailyCalorieTarget => _vi ? 'Mục tiêu calo hàng ngày' : 'Daily Calorie Target';
  String get targetProtein => _vi ? 'Protein mục tiêu (g/ngày)' : 'Target Protein (g/day)';
  String get dietaryRestrictionsLabel => _vi ? 'Chế độ ăn đặc biệt' : 'Dietary Restrictions';
  String get securityLabel => _vi ? 'Bảo mật' : 'Security';
  String get changePasswordLabel => _vi ? 'Đổi mật khẩu' : 'Change password';
  String get saveChanges => _vi ? 'Lưu thay đổi' : 'Save changes';
  String get logOut => _vi ? 'Đăng xuất' : 'Log out';
  String get mustBePositiveNumber => _vi ? 'Phải là số dương' : 'Must be a positive number';
  String get unableToSaveProfile => _vi ? 'Không thể lưu hồ sơ.' : 'Unable to save profile.';

  // Change password sheet
  String get changePasswordTitle => _vi ? 'Đổi mật khẩu' : 'Change password';
  String get chooseStrongPassword =>
      _vi ? 'Chọn mật khẩu mạnh cho tài khoản của bạn' : 'Choose a strong password for your account';
  String get currentPassword => _vi ? 'Mật khẩu hiện tại' : 'Current password';
  String get newPassword => _vi ? 'Mật khẩu mới' : 'New password';
  String get confirmNewPassword => _vi ? 'Xác nhận mật khẩu mới' : 'Confirm new password';
  String get enterCurrentPassword => _vi ? 'Nhập mật khẩu hiện tại' : 'Enter your current password';
  String get mustBeAtLeast6 => _vi ? 'Phải ít nhất 6 ký tự' : 'Must be at least 6 characters';
  String get passwordsDoNotMatch => _vi ? 'Mật khẩu không khớp' : 'Passwords do not match';
  String get updateLabel => _vi ? 'Cập nhật' : 'Update';
  String get passwordUpdated => _vi ? 'Đã cập nhật mật khẩu thành công.' : 'Password updated successfully.';
  String get unableToUpdatePassword => _vi ? 'Không thể cập nhật mật khẩu.' : 'Unable to update password.';

  // Primary goals display
  String goalDisplay(String goal) {
    if (!_vi) return goal;
    const map = {
      'Balanced Nutrition': 'Dinh dưỡng cân bằng',
      'Weight Loss': 'Giảm cân',
      'Muscle Gain': 'Tăng cơ',
      'High Protein': 'Nhiều protein',
    };
    return map[goal] ?? goal;
  }

  // Label/tag display — covers kAvailableLabels + dietary restriction tags
  String dietaryTagDisplay(String tag) {
    if (!_vi) return tag;
    const map = {
      // dietary restrictions
      'Alcoholic': 'Có cồn',
      'Beverage': 'Đồ uống',
      'Dairy Free': 'Không sữa',
      'Egg Free': 'Không trứng',
      'Gluten Free': 'Không gluten',
      'Nut Free': 'Không hạt',
      'Pescetarian': 'Hải sản',
      'Vegan': 'Thuần chay',
      'Vegetarian': 'Ăn chay',
      // recipe labels
      'Healthy': 'Lành mạnh',
      'Italian': 'Ẩm thực Ý',
      'Comfort Food': 'Đồ ăn vặt',
      'High Protein': 'Nhiều protein',
      'Keto': 'Keto',
      'Quick Meal': 'Nấu nhanh',
      'Meal Prep': 'Chuẩn bị sẵn',
      'Breakfast': 'Bữa sáng',
    };
    return map[tag] ?? tag;
  }
}
