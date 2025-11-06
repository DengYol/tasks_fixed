import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AssignTasksScreen extends StatefulWidget {
  const AssignTasksScreen({super.key});

  @override
  State<AssignTasksScreen> createState() => _AssignTasksScreenState();
}

class _AssignTasksScreenState extends State<AssignTasksScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _showForm = false;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  List<String> _selectedMembers = [];

  /// 🧾 Assign a new task
  Future<void> _assignTask() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty || _dueDate == null || _dueTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please fill all fields and set a due date/time.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dueDateTime = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        _dueTime!.hour,
        _dueTime!.minute,
      );

      await _firestore.collection('tasks').add({
        'title': title,
        'description': description,
        'assignedTo': _selectedMembers,
        'createdAt': FieldValue.serverTimestamp(),
        'dueDate': dueDateTime,
        'status': 'Pending',
      });

      // Reset form
      _titleController.clear();
      _descriptionController.clear();
      _dueDate = null;
      _dueTime = null;
      _selectedMembers = [];

      setState(() => _showForm = false); // Hide form

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Task assigned successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error assigning task: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🗑️ Delete a task
  Future<void> _deleteTask(String taskId, String taskTitle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "$taskTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('tasks').doc(taskId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🗑️ "$taskTitle" deleted successfully.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to delete task: $e')),
        );
      }
    }
  }

  /// ✅ Mark as complete
  Future<void> _markComplete(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({'status': 'Completed'});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎯 Task marked as completed!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to mark complete: $e')),
      );
    }
  }

  /// 📅 Pick Due Date
  Future<void> _pickDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() => _dueDate = pickedDate);
    }
  }

  /// ⏰ Pick Due Time
  Future<void> _pickDueTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() => _dueTime = pickedTime);
    }
  }

  /// 👥 Member Selector
  Widget _buildMemberSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No members found.');
        }

        final members = snapshot.data!.docs;

        return Wrap(
          spacing: 6,
          children: members.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['fullName'] ?? 'Unnamed';
            final isSelected = _selectedMembers.contains(name);

            return FilterChip(
              label: Text(name),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedMembers.add(name);
                  } else {
                    _selectedMembers.remove(name);
                  }
                });
              },
            );
          }).toList(),
        );
      },
    );
  }

  /// ✏️ Edit Task
  Future<void> _editTask(String taskId, Map<String, dynamic> taskData) async {
    final TextEditingController editTitleController =
    TextEditingController(text: taskData['title']);
    final TextEditingController editDescController =
    TextEditingController(text: taskData['description']);
    DateTime? editDueDate = (taskData['dueDate'] as Timestamp?)?.toDate();
    List<String> editMembers =
        (taskData['assignedTo'] as List<dynamic>?)?.cast<String>() ?? [];

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✏️ Edit Task',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: editTitleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: editDescController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('users').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final members = snapshot.data!.docs;
                      return Wrap(
                        spacing: 6,
                        children: members.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['fullName'] ?? 'Unnamed';
                          final selected = editMembers.contains(name);
                          return FilterChip(
                            label: Text(name),
                            selected: selected,
                            onSelected: (isSelected) {
                              setModalState(() {
                                if (isSelected) {
                                  editMembers.add(name);
                                } else {
                                  editMembers.remove(name);
                                }
                              });
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: editDueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setModalState(() => editDueDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(editDueDate == null
                        ? 'Pick Due Date'
                        : DateFormat('EEE, MMM d, yyyy').format(editDueDate!)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                    onPressed: () async {
                      await _firestore.collection('tasks').doc(taskId).update({
                        'title': editTitleController.text.trim(),
                        'description': editDescController.text.trim(),
                        'assignedTo': editMembers,
                        'dueDate': editDueDate,
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('✅ Task updated successfully!')),
                      );
                    },
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 📋 Task Details Sheet
  void _showTaskDetails(String taskId, Map<String, dynamic> taskData) {
    final assignedTo =
        (taskData['assignedTo'] as List<dynamic>?)?.cast<String>() ?? [];
    final dueDate = (taskData['dueDate'] as Timestamp?)?.toDate();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(taskData['title'] ?? 'Untitled Task',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(taskData['description'] ?? 'No description.'),
            const SizedBox(height: 10),
            if (assignedTo.isNotEmpty)
              Text('👥 Assigned to: ${assignedTo.join(', ')}'),
            if (dueDate != null)
              Text(
                '📅 Due: ${DateFormat('EEE, MMM d, yyyy • hh:mm a').format(dueDate)}',
              ),
            const SizedBox(height: 10),
            Text(
              'Status: ${taskData['status'] ?? 'Pending'}',
              style: TextStyle(
                color: (taskData['status'] == 'Completed')
                    ? Colors.green
                    : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: () {
                      Navigator.pop(context);
                      _editTask(taskId, taskData);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Complete'),
                    style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      Navigator.pop(context);
                      _markComplete(taskId);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteTask(taskId, taskData['title'] ?? '');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🏗️ Main Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Tasks'),
        actions: [
          IconButton(
            icon: Icon(_showForm ? Icons.close : Icons.add),
            onPressed: () {
              setState(() => _showForm = !_showForm);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_showForm)
              _buildAssignForm(),

            /// 📋 Task List
            Expanded(child: _buildTaskList()),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration:
              const InputDecoration(labelText: 'Task Title', prefixIcon: Icon(Icons.title)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Task Description', prefixIcon: Icon(Icons.description)),
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Assign to Members:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            _buildMemberSelector(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_dueDate == null
                        ? 'Pick Due Date'
                        : DateFormat('EEE, MMM d, yyyy').format(_dueDate!)),
                    onPressed: _pickDueDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(_dueTime == null
                        ? 'Pick Due Time'
                        : _dueTime!.format(context)),
                    onPressed: _pickDueTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: Text(_isLoading ? 'Assigning...' : 'Assign Task'),
                onPressed: _isLoading ? null : _assignTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('tasks')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No tasks assigned yet.'));
        }

        final tasks = snapshot.data!.docs;

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final data = task.data() as Map<String, dynamic>;
            final assignedTo =
                (data['assignedTo'] as List<dynamic>?)?.cast<String>() ?? [];
            final dueDate = (data['dueDate'] as Timestamp?)?.toDate();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.assignment, color: Colors.white),
                ),
                title: Text(data['title'] ?? 'Untitled Task'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['description'] ?? 'No description provided.'),
                    if (assignedTo.isNotEmpty)
                      Text('👥 Assigned to: ${assignedTo.join(', ')}'),
                    if (dueDate != null)
                      Text(
                        '📅 Due: ${DateFormat('EEE, MMM d, yyyy • hh:mm a').format(dueDate)}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                  ],
                ),
                onTap: () => _showTaskDetails(task.id, data),
              ),
            );
          },
        );
      },
    );
  }
}
