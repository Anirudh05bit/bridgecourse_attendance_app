class Student {
  final String id;
  final String name;

  Student({required this.id, required this.name});

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(id: map['id'] as String, name: map['name'] as String);
  }
}