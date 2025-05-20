import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject{
  @HiveField(0)
  String title;

  @HiveField(1)
  DateTime date;

  Task({required this.title, required this.date});
}