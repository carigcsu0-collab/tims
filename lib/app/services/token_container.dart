/// A simple mutable container for the auth token.
///
/// Used to break the dependency cycle between [ApiClient] and [AuthService]
/// in the Riverpod provider graph.
class TokenContainer {
  /// The current auth token, or null if not authenticated.
  String? token;

  /// Clears the token.
  void clear() => token = null;
}
