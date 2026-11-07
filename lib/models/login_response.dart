class LoginResponse {
  final bool valid;
  final String? token;

  LoginResponse({
    required this.valid,
    required this.token,
  });
}