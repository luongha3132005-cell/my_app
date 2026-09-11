/// Đại diện cho một bước kiểm tra trong quy trình chẩn đoán thiết bị
class DiagStep {
  final String code;
  final String title;
  final Future<void> Function() run;

  const DiagStep({
    required this.code,
    required this.title,
    required this.run,
  });
}
