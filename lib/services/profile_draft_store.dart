import 'package:flutter/foundation.dart';

/// In-memory draft of profile suggestions from a previous chat (propose-only).
class ProfileDraftStore {
  ProfileDraftStore._();

  static Map<String, dynamic>? proposedProfile;
  static List<String> changedFields = const [];

  /// Bumped when draft is saved or cleared so kept-alive ProfileScreen can react.
  static final ValueNotifier<int> revision = ValueNotifier(0);

  static bool get hasDraft =>
      proposedProfile != null && changedFields.isNotEmpty;

  static void save({
    required Map<String, dynamic> proposedProfile,
    required List<String> changedFields,
  }) {
    if (changedFields.isEmpty) {
      clear();
      return;
    }
    ProfileDraftStore.proposedProfile =
        Map<String, dynamic>.from(proposedProfile);
    ProfileDraftStore.changedFields = List<String>.from(changedFields);
    revision.value++;
  }

  static void clear() {
    proposedProfile = null;
    changedFields = const [];
    revision.value++;
  }
}
