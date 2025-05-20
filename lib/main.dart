import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'models/task.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);
  Hive.registerAdapter(TaskAdapter());

  await Hive.openBox<Task>('tasks');

  runApp(ToDoApp());
}

class ToDoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de agendamento',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      home: TaskListPage(),
    );
  }
}

class TaskListPage extends StatefulWidget {
  @override
  _TaskListPageState createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  late Box<Task> taskBox;

  @override
  void initState() {
    super.initState();
    taskBox = Hive.box<Task>('tasks');
  }

  final TextEditingController _textController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  void _addTask() {
    if (_textController.text.trim().isNotEmpty &&
        _selectedDate != null &&
        _selectedTime != null) {
      final fullDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final now = DateTime.now();
      if (fullDateTime.isBefore(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Escolha uma data e hora futura.')),
        );
        return;
      }

      final newTask = Task(
        title: _textController.text.trim(),
        date: fullDateTime,
      );
      taskBox.add(newTask);

      setState(() {
        _textController.clear();
        _selectedDate = null;
        _selectedTime = null;
      });
    }
  }

  void _editTaskDialog(Task task, int index) {
    final TextEditingController editingController = TextEditingController(
      text: task.title,
    );
    DateTime selectedDate = task.date;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(task.date);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar Tarefa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editingController,
                decoration: InputDecoration(labelText: 'Titulo'),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Data: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(Duration(days: 365)),
                        lastDate: DateTime.now().add(Duration(days: 365 * 5)),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                    child: Text('Alterar Data'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text('Hora: ${selectedTime.format(context)}'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedTime = pickedTime;
                        });
                      }
                    },
                    child: Text('Alterar Hora'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final updateDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                final updatedTask = Task(
                  title: editingController.text.trim(),
                  date: updateDateTime,
                );

                taskBox.putAt(index, updatedTask);
                Navigator.of(context).pop();
                setState(() {});
              },
              child: Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _removeTask(int index) {
    taskBox.deleteAt(index);
    setState(() {});
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today.subtract(Duration(days: 365)),
      lastDate: today.add(Duration(days: 365 * 5)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatDate(DateTime dateTime) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);
    final formattedTime = DateFormat('HH:mm').format(dateTime);
    return '$formattedDate às $formattedTime';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lista de agendamento',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(labelText: 'Digite uma nova tarefa'),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'Nenhuma data selecionada'
                        : 'Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                  ),
                ),
                TextButton.icon(
                  icon: Icon(Icons.calendar_today),
                  label: Text('Selecionar data'),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedTime == null
                        ? 'Nenhuma hora selecionada'
                        : 'Hora: ${_selectedTime!.format(context)}',
                  ),
                ),
                TextButton.icon(
                  icon: Icon(Icons.access_time),
                  label: Text('Selecionar hora'),
                  onPressed: () => _selectTime(context),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _addTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: Text('Adicionar Tarefa'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: taskBox.listenable(),
                builder: (context, Box<Task> box, _) {
                  if (box.isEmpty) {
                    return Center(
                      child: Text('Nenhuma tarefa adicionada ainda.'),
                    );
                  }
                  final tasks = box.values.toList();
                  tasks.sort((a, b) => a.date.compareTo(b.date));
                  return ListView.builder(
                    itemCount: box.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        child: ListTile(
                          title: Text(task.title),
                          subtitle: Text('Data: ${_formatDate(task.date)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editTaskDialog(task, index),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: Text('Confirmar exclusão'),
                                          content: Text(
                                            'Deseja remover esta tarefa?',
                                          ),
                                          actions: [
                                            TextButton(
                                              child: Text('Cancelar'),
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                            ),
                                            TextButton(
                                              child: Text('Remover'),
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (confirm == true) _removeTask(index);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


