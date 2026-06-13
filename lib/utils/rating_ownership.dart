import '../models/auth_session.dart';

/// يتحقق أن التقييم يخص الزبون المسجّل حالياً.
/// السيرver يُرجع `user.id` كمعرّف [customer_profile] وليس معرّف المستخدم.
bool ratingBelongsToCurrentUser({
  required String authorName,
  int? authorId,
}) {
  final user = AuthSession.instance.user;
  if (user == null) return false;

  if (authorId != null && authorId > 0) {
    final profileId = user.customerProfileId;
    if (profileId != null && profileId > 0 && authorId == profileId) return true;
    final userId = user.id;
    if (userId != null && userId > 0 && authorId == userId) return true;
  }

  final me = user.name.trim().toLowerCase();
  if (me.isEmpty) return false;
  final author = authorName.trim().toLowerCase();
  if (author.isEmpty || author == '—' || author == '-') return false;
  return author == me;
}
