class ApiException implements Exception {
  const ApiException(this.message, {this.status, this.code});

  final String message;
  final int? status;
  final String? code;

  bool get isNetwork => status == null;

  bool get isProjectLimit => status == 402 && code == 'plan.projectLimit';
}
