import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../state/app_state.dart';

class TaskEditorSheet extends StatefulWidget {
  final AppState appState;
  final TaskItem? existingTask;

  const TaskEditorSheet({
    super.key,
    required this.appState,
    this.existingTask,
  });

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  final TextEditingController _subTaskController = TextEditingController();

  late String _categoryId;
  late TaskPriority _priority;
  DateTime? _dueDate;
  late bool _hasReminder;
  late RecurrenceType _recurrence;
  late List<SubTask> _subTasks;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _notesController = TextEditingController(text: task?.notes ?? '');
    _categoryId = task?.categoryId ??
        (widget.appState.selectedCategoryId ??
            widget.appState.categories.first.id);
    _priority = task?.priority ?? TaskPriority.medium;
    _dueDate = task?.dueDate;
    _hasReminder = task?.hasReminder ?? false;
    _recurrence = task?.recurrence ?? RecurrenceType.none;
    _subTasks = List<SubTask>.from(task?.subTasks ?? const []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDateTime() async {
    final now = DateTime.now();
    final initialDate = _dueDate ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate == null || !mounted) return;

    final initialTime = _dueDate != null
        ? TimeOfDay(hour: _dueDate!.hour, minute: _dueDate!.minute)
        : TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (!mounted) return;

    final time = pickedTime ?? const TimeOfDay(hour: 9, minute: 0);
    setState(() {
      _dueDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _addSubTask() {
    final text = _subTaskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subTasks.add(
        SubTask(
          id: 'sub_${DateTime.now().microsecondsSinceEpoch}',
          title: text,
        ),
      );
      _subTaskController.clear();
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title.')),
      );
      return;
    }

    final existing = widget.existingTask;
    final task = TaskItem(
      id: existing?.id ?? 'task_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      notes: _notesController.text.trim(),
      categoryId: _categoryId,
      priority: _priority,
      dueDate: _dueDate,
      hasReminder: _hasReminder && _dueDate != null,
      recurrence: _recurrence,
      isCompleted: existing?.isCompleted ?? false,
      completedAt: existing?.completedAt,
      createdAt: existing?.createdAt ?? DateTime.now(),
      subTasks: _subTasks,
    );

    if (_isEditing) {
      await widget.appState.updateTask(task);
    } else {
      await widget.appState.addTask(task);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                  child: Row(
                    children: [
                      Text(
                        _isEditing ? 'Edit Task' : 'New Task',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_isEditing)
                        IconButton(
                          tooltip: 'Delete task',
                          icon: Icon(
                            Icons.delete_outline,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: () async {
                            await widget.appState
                                .deleteTask(widget.existingTask!.id);
                            if (context.mounted) Navigator.of(context).pop();
                          },
                        ),
                      FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Save'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    children: [
                      TextField(
                        controller: _titleController,
                        autofocus: !_isEditing,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Task title',
                          hintText: 'What do you want to get done?',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          hintText: 'Add details, links, or reminders...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Priority',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: TaskPriority.values.map((p) {
                          final selected = _priority == p;
                          return ChoiceChip(
                            label: Text(p.label),
                            selected: selected,
                            selectedColor: p.color.withAlpha(45),
                            avatar: Icon(
                              Icons.flag_rounded,
                              size: 16,
                              color: p.color,
                            ),
                            onSelected: (_) => setState(() => _priority = p),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Category',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: widget.appState.categories.map((cat) {
                          final selected = _categoryId == cat.id;
                          return ChoiceChip(
                            label: Text(cat.name),
                            selected: selected,
                            selectedColor: cat.color.withAlpha(45),
                            avatar: CircleAvatar(
                              radius: 6,
                              backgroundColor: cat.color,
                            ),
                            onSelected: (_) =>
                                setState(() => _categoryId = cat.id),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: theme.colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.event_outlined),
                              title: Text(
                                _dueDate == null
                                    ? 'Set due date & time'
                                    : DateFormat('EEE, MMM d • h:mm a')
                                        .format(_dueDate!),
                              ),
                              trailing: _dueDate != null
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () => setState(() {
                                        _dueDate = null;
                                        _hasReminder = false;
                                      }),
                                    )
                                  : const Icon(Icons.chevron_right),
                              onTap: _pickDueDateTime,
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              secondary:
                                  const Icon(Icons.notifications_outlined),
                              title: const Text('Remind me'),
                              subtitle: Text(
                                _dueDate == null
                                    ? 'Pick a due date first'
                                    : 'Local notification at due time',
                              ),
                              value: _hasReminder,
                              onChanged: (val) async {
                                if (val && _dueDate == null) {
                                  await _pickDueDateTime();
                                }
                                if (_dueDate != null) {
                                  setState(() => _hasReminder = val);
                                }
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.repeat_rounded),
                              title: const Text('Repeat'),
                              trailing: DropdownButton<RecurrenceType>(
                                value: _recurrence,
                                underline: const SizedBox.shrink(),
                                items: RecurrenceType.values
                                    .map(
                                      (r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(r.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _recurrence = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Sub-tasks (${_subTasks.where((s) => s.isCompleted).length}/${_subTasks.length})',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ..._subTasks.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final sub = entry.value;
                        return Row(
                          children: [
                            Checkbox(
                              value: sub.isCompleted,
                              onChanged: (val) {
                                setState(() {
                                  _subTasks[idx] =
                                      sub.copyWith(isCompleted: val ?? false);
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                sub.title,
                                style: TextStyle(
                                  decoration: sub.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() => _subTasks.removeAt(idx));
                              },
                            ),
                          ],
                        );
                      }),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _subTaskController,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText: 'Add a step...',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => _addSubTask(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            onPressed: _addSubTask,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
