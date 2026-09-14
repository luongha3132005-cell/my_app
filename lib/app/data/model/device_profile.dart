/// Cấu hình tiêu chuẩn phần cứng theo từng dòng máy (Device Profile)
class DeviceProfile {
  final String name;
  final bool bio; // Dòng máy này có bắt buộc phải có tính năng sinh trắc học không?

  const DeviceProfile({
    required this.name,
    this.bio = false,
  });

  factory DeviceProfile.fromJson(Map<String, dynamic> json) {
    return DeviceProfile(
      name: json['name'] as String? ?? 'default',
      bio: json['bio'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'bio': bio,
  };

  DeviceProfile copyWith({
    String? name,
    bool? bio,
  }) {
    return DeviceProfile(
      name: name ?? this.name,
      bio: bio ?? this.bio,
    );
  }
}
