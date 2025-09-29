import 'package:bharatconnect/models/status_model.dart';
import 'package:bharatconnect/models/user_profile_model.dart';

class UserStatusGroup {
  final UserProfile user;
  final List<DisplayStatus> statuses;

  UserStatusGroup({
    required this.user,
    required this.statuses,
  });

  // Helper to check if any status in the group is unviewed
  bool get hasUnviewedStatus => statuses.any((s) => !s.viewedByCurrentUser);
}
