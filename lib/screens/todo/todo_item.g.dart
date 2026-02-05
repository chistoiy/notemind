// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_screen.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TodoItemAdapter extends TypeAdapter<TodoItem> {
  @override
  final int typeId = 3;

  @override
  TodoItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TodoItem(
      fields[0] as String,
      fields[1] as bool,
    )
      ..createdAt = fields[2] as DateTime
      ..dueDate = fields[3] as DateTime?
      ..isExpired = fields[4] as bool;
  }

  @override
  void write(BinaryWriter writer, TodoItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.isCompleted)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.dueDate)
      ..writeByte(4)
      ..write(obj.isExpired);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DeletedTodoItemAdapter extends TypeAdapter<DeletedTodoItem> {
  @override
  final int typeId = 4;

  @override
  DeletedTodoItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeletedTodoItem(
      fields[0] as TodoItem,
    )
      ..deletedAt = fields[1] as DateTime;
  }

  @override
  void write(BinaryWriter writer, DeletedTodoItem obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.todo)
      ..writeByte(1)
      ..write(obj.deletedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeletedTodoItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
