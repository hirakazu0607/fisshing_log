import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '釣果管理アプリ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: const Color(0xFF2196F3),
          secondary: const Color(0xFF21CBF3),
        ),
        useMaterial3: true,
        fontFamily: 'Hiragino Sans',
      ),
      home: const FishingLogApp(),
    );
  }
}

// 釣果データモデル
class Catch {
  final int id;
  final String fishName;
  final String location;
  final DateTime date;
  final String? notes;
  final File? photoFile;

  Catch({
    required this.id,
    required this.fishName,
    required this.location,
    required this.date,
    this.notes,
    this.photoFile,
  });
}

class FishingLogApp extends StatefulWidget {
  const FishingLogApp({super.key});

  @override
  State<FishingLogApp> createState() => _FishingLogAppState();
}

class _FishingLogAppState extends State<FishingLogApp> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Catch> _catches = [];
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  String _selectedPrefecture = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // サンプルデータを追加
    _catches.add(
      Catch(
        id: 1,
        fishName: 'マダイ',
        location: '東京湾',
        date: DateTime.now(),
        notes: '朝一番で釣れました！',
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 釣果を追加
  void _addCatch(Catch newCatch) {
    setState(() {
      _catches.add(newCatch);
    });
  }

  // 釣果を削除
  void _deleteCatch(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('釣果データを削除'),
        content: const Text('この釣果データを削除しますか？\n\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _catches.removeWhere((c) => c.id == id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('釣果データを削除しました')),
              );
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 釣果登録モーダルを表示
  void _showAddCatchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddCatchForm(onAdd: _addCatch),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.catching_pokemon, size: 24),
            const SizedBox(width: 8),
            const Text('釣果管理アプリ'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '釣果', icon: Icon(Icons.list)),
            Tab(text: 'カレンダー', icon: Icon(Icons.calendar_month)),
            Tab(text: '潮汐', icon: Icon(Icons.water)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 釣果タブ
          CatchesTab(catches: _catches, onDelete: _deleteCatch),
          
          // カレンダータブ
          CalendarTab(
            catches: _catches,
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
          ),
          
          // 潮汐タブ
          TideTab(
            selectedPrefecture: _selectedPrefecture,
            onPrefectureChanged: (value) {
              setState(() {
                _selectedPrefecture = value;
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCatchModal,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// 釣果タブ
class CatchesTab extends StatelessWidget {
  final List<Catch> catches;
  final Function(int) onDelete;

  const CatchesTab({
    super.key,
    required this.catches,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (catches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.catching_pokemon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'まだ釣果が登録されていません',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              '右下の「+」ボタンから登録してみましょう！',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // 日付の降順でソート
    final sortedCatches = List<Catch>.from(catches)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedCatches.length,
      itemBuilder: (context, index) {
        final catch_ = sortedCatches[index];
        return CatchCard(catch_: catch_, onDelete: onDelete);
      },
    );
  }
}

// 釣果カード
class CatchCard extends StatelessWidget {
  final Catch catch_;
  final Function(int) onDelete;

  const CatchCard({
    super.key,
    required this.catch_,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ja_JP');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (catch_.photoFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      catch_.photoFile!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  '🐟 ${catch_.fishName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('📍 場所: ${catch_.location}'),
                const SizedBox(height: 4),
                Text('🕒 日時: ${dateFormat.format(catch_.date)}'),
                if (catch_.notes != null && catch_.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('📝 メモ: ${catch_.notes}'),
                ],
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(catch_.id),
            ),
          ),
        ],
      ),
    );
  }
}

// カレンダータブ
class CalendarTab extends StatelessWidget {
  final List<Catch> catches;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Function(DateTime, DateTime) onDaySelected;

  const CalendarTab({
    super.key,
    required this.catches,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    // 釣果のある日を取得
    final catchDays = catches.map((c) => DateTime(
      c.date.year,
      c.date.month,
      c.date.day,
    )).toSet();

    // 選択された日の釣果を取得
    final selectedDayCatches = catches.where((c) =>
      c.date.year == selectedDay.year &&
      c.date.month == selectedDay.month &&
      c.date.day == selectedDay.day
    ).toList();

    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          onDaySelected: onDaySelected,
          eventLoader: (day) {
            final normalizedDay = DateTime(day.year, day.month, day.day);
            return catchDays.contains(normalizedDay) ? ['catch'] : [];
          },
          calendarStyle: CalendarStyle(
            markersMaxCount: 1,
            markerDecoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
        const Divider(),
        Expanded(
          child: selectedDayCatches.isEmpty
            ? const Center(
                child: Text(
                  'この日の釣果はありません',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: selectedDayCatches.length,
                itemBuilder: (context, index) {
                  return CatchCard(
                    catch_: selectedDayCatches[index],
                    onDelete: (id) {},
                  );
                },
              ),
        ),
      ],
    );
  }
}

// 潮汐タブ
class TideTab extends StatelessWidget {
  final String selectedPrefecture;
  final Function(String) onPrefectureChanged;

  const TideTab({
    super.key,
    required this.selectedPrefecture,
    required this.onPrefectureChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '潮汐情報',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: '都道府県を選択',
              border: OutlineInputBorder(),
            ),
            value: selectedPrefecture.isEmpty ? null : selectedPrefecture,
            items: const [
              DropdownMenuItem(value: 'tokyo', child: Text('東京都')),
              DropdownMenuItem(value: 'kanagawa', child: Text('神奈川県')),
              DropdownMenuItem(value: 'chiba', child: Text('千葉県')),
              DropdownMenuItem(value: 'shizuoka', child: Text('静岡県')),
              DropdownMenuItem(value: 'osaka', child: Text('大阪府')),
              DropdownMenuItem(value: 'fukuoka', child: Text('福岡県')),
            ],
            onChanged: (value) {
              if (value != null) {
                onPrefectureChanged(value);
              }
            },
          ),
          const SizedBox(height: 24),
          if (selectedPrefecture.isNotEmpty)
            _buildTideInfo(selectedPrefecture)
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 32),
                child: Text(
                  '都道府県を選択すると潮汐情報が表示されます',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTideInfo(String prefecture) {
    // 模擬的な潮汐データ
    final Map<String, Map<String, dynamic>> mockTideData = {
      'tokyo': {
        'location': '東京湾',
        'tides': [
          {'time': '06:15', 'type': '満潮', 'height': '1.8m'},
          {'time': '12:30', 'type': '干潮', 'height': '0.3m'},
          {'time': '18:45', 'type': '満潮', 'height': '1.9m'},
          {'time': '00:20', 'type': '干潮', 'height': '0.2m'},
        ],
      },
      'kanagawa': {
        'location': '相模湾',
        'tides': [
          {'time': '05:45', 'type': '満潮', 'height': '1.4m'},
          {'time': '11:50', 'type': '干潮', 'height': '0.1m'},
          {'time': '18:20', 'type': '満潮', 'height': '1.5m'},
          {'time': '23:55', 'type': '干潮', 'height': '0.0m'},
        ],
      },
      'chiba': {
        'location': '千葉港',
        'tides': [
          {'time': '06:30', 'type': '満潮', 'height': '1.6m'},
          {'time': '12:45', 'type': '干潮', 'height': '0.2m'},
          {'time': '19:00', 'type': '満潮', 'height': '1.7m'},
          {'time': '00:35', 'type': '干潮', 'height': '0.1m'},
        ],
      },
    };

    final data = mockTideData[prefecture] ?? mockTideData['tokyo']!;
    final location = data['location'] as String;
    final tides = data['tides'] as List;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.blue.shade800,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '今日の潮汐情報',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            ...tides.map<Widget>((tide) {
              final time = tide['time'] as String;
              final type = tide['type'] as String;
              final height = tide['height'] as String;
              final icon = type == '満潮' ? Icons.waves : Icons.beach_access;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$type ($height)',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            const Text(
              '※ 実際の潮汐情報は海上保安庁のAPIから取得してください',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 釣果登録フォーム
class AddCatchForm extends StatefulWidget {
  final Function(Catch) onAdd;

  const AddCatchForm({super.key, required this.onAdd});

  @override
  State<AddCatchForm> createState() => _AddCatchFormState();
}

class _AddCatchFormState extends State<AddCatchForm> {
  final _formKey = GlobalKey<FormState>();
  final _fishNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  File? _photoFile;
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _fishNameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _photoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newCatch = Catch(
        id: DateTime.now().millisecondsSinceEpoch,
        fishName: _fishNameController.text,
        location: _locationController.text,
        date: _selectedDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        photoFile: _photoFile,
      );
      
      widget.onAdd(newCatch);
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('釣果を登録しました！')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ja_JP');
    
    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '新規釣果登録',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fishNameController,
                decoration: const InputDecoration(
                  labelText: '魚種名',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.catching_pokemon),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '魚種名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: '釣れた場所',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '場所を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '釣れた日時',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateFormat.format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'メモ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                  hintText: '釣り方、エサ、天候など',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickImage,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '魚の写真',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.photo_camera),
                  ),
                  child: _photoFile == null
                      ? const Text('タップして写真を選択')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('選択済み:'),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _photoFile!,
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('登録', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
