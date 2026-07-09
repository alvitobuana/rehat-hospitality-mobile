import 'package:flutter/material.dart';
import '../services/mock_state.dart';
import '../models/models.dart';
import '../widgets/reusable_widgets.dart';
import '../theme/app_theme.dart';


class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({Key? key}) : super(key: key);

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final MockState _state = MockState();
  String _selectedStatusFilter = 'Semua';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  // Add Project Dialog
  void _showAddProjectDialog() {
    final nameCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final picCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final progressCtrl = TextEditingController(text: '0');

    String category = 'Perbaikan';
    String status = 'Akan Dikerjakan';
    String priority = 'Sedang';

    final categories = ['Perbaikan', 'Pengecatan', 'Renovasi', 'Maintenance Rutin', 'Penggantian Furnitur', 'Instalasi', 'Deep Cleaning', 'Lainnya'];
    final statuses = ['Akan Dikerjakan', 'Sedang Berlangsung', 'Selesai'];
    final priorities = ['Tinggi', 'Sedang', 'Rendah'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Buat Project Baru',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2B4A)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    CustomTextField(
                      label: 'Nama Project',
                      hintText: 'Pengecatan Koridor Lt. 2, dll.',
                      controller: nameCtrl,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Area / Lokasi',
                            hintText: 'Kamar 101, Lobby, Pool...',
                            controller: areaCtrl,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('KATEGORI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE4E8F0), width: 1.5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: category,
                                    isExpanded: true,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF1A2B4A), fontWeight: FontWeight.bold),
                                    onChanged: (val) => setModalState(() => category = val!),
                                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE4E8F0), width: 1.5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: status,
                                    isExpanded: true,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF1A2B4A), fontWeight: FontWeight.bold),
                                    onChanged: (val) => setModalState(() => status = val!),
                                    items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PRIORITAS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE4E8F0), width: 1.5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: priority,
                                    isExpanded: true,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF1A2B4A), fontWeight: FontWeight.bold),
                                    onChanged: (val) => setModalState(() => priority = val!),
                                    items: priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'PIC (Penanggung Jawab)',
                            hintText: 'Nama PIC...',
                            controller: picCtrl,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'Estimasi Biaya (Rp)',
                            hintText: '0',
                            controller: costCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Progress (%)',
                            hintText: '0',
                            controller: progressCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      label: 'Deskripsi / Detail Pekerjaan',
                      hintText: 'Tuliskan instruksi pekerjaan detail...',
                      controller: descCtrl,
                    ),
                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: 'Simpan Project',
                      onPressed: () {
                        if (nameCtrl.text.isEmpty || areaCtrl.text.isEmpty || picCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nama, Area, dan PIC wajib diisi!'), backgroundColor: Colors.orange),
                          );
                          return;
                        }
                        
                        final double cost = double.tryParse(costCtrl.text) ?? 0.0;
                        final int prog = int.tryParse(progressCtrl.text) ?? 0;

                        _state.addProject(
                          nameCtrl.text.trim(),
                          areaCtrl.text.trim(),
                          category,
                          status,
                          priority,
                          picCtrl.text.trim(),
                          '2026-07-08',
                          '2026-07-15',
                          prog,
                          cost,
                          descCtrl.text.trim(),
                        );
                        
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Project berhasil ditambahkan!'), backgroundColor: Colors.green),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Edit/Update Project Dialog
  void _showEditProjectDialog(Project project) {
    final nameCtrl = TextEditingController(text: project.name);
    final areaCtrl = TextEditingController(text: project.area);
    final picCtrl = TextEditingController(text: project.pic);
    final descCtrl = TextEditingController(text: project.description);
    final costCtrl = TextEditingController(text: project.cost.toStringAsFixed(0));
    final progressCtrl = TextEditingController(text: project.progress.toString());

    String category = project.category;
    String status = project.status;
    String priority = project.priority;

    final categories = ['Perbaikan', 'Pengecatan', 'Renovasi', 'Maintenance Rutin', 'Penggantian Furnitur', 'Instalasi', 'Deep Cleaning', 'Lainnya'];
    final statuses = ['Akan Dikerjakan', 'Sedang Berlangsung', 'Selesai'];
    final priorities = ['Tinggi', 'Sedang', 'Rendah'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Project - ${project.id}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2B4A)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    CustomTextField(
                      label: 'Nama Project',
                      hintText: 'Nama project...',
                      controller: nameCtrl,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Area / Lokasi',
                            hintText: 'Lokasi...',
                            controller: areaCtrl,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('KATEGORI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE4E8F0), width: 1.5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: category,
                                    isExpanded: true,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF1A2B4A), fontWeight: FontWeight.bold),
                                    onChanged: (val) => setModalState(() => category = val!),
                                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE4E8F0), width: 1.5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: status,
                                    isExpanded: true,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF1A2B4A), fontWeight: FontWeight.bold),
                                    onChanged: (val) => setModalState(() => status = val!),
                                    items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PRIORITAS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE4E8F0), width: 1.5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: priority,
                                    isExpanded: true,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF1A2B4A), fontWeight: FontWeight.bold),
                                    onChanged: (val) => setModalState(() => priority = val!),
                                    items: priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'PIC',
                            hintText: 'PIC...',
                            controller: picCtrl,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'Biaya (Rp)',
                            hintText: '0',
                            controller: costCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Progress (%)',
                            hintText: '0',
                            controller: progressCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      label: 'Deskripsi',
                      hintText: 'Keterangan detail...',
                      controller: descCtrl,
                    ),
                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: 'Simpan Perubahan',
                      onPressed: () {
                        if (nameCtrl.text.isEmpty || areaCtrl.text.isEmpty || picCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Field tidak boleh kosong!'), backgroundColor: Colors.orange),
                          );
                          return;
                        }

                        final double costVal = double.tryParse(costCtrl.text) ?? 0.0;
                        final int progVal = int.tryParse(progressCtrl.text) ?? 0;

                        _state.updateProject(
                          project.id,
                          name: nameCtrl.text.trim(),
                          area: areaCtrl.text.trim(),
                          category: category,
                          status: status,
                          priority: priority,
                          pic: picCtrl.text.trim(),
                          progress: progVal,
                          cost: costVal,
                          description: descCtrl.text.trim(),
                        );

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Project berhasil di-update!'), backgroundColor: Colors.green),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _state.currentUser!;

    final unitProjects = _state.projects
        .where((p) => p.hotelUnit == user.hotelUnit)
        .toList();

    final filteredProjects = unitProjects.where((p) {
      // Filter status
      if (_selectedStatusFilter != 'Semua' && p.status != _selectedStatusFilter) {
        return false;
      }
      // Filter search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return p.name.toLowerCase().contains(query) ||
            p.pic.toLowerCase().contains(query) ||
            p.area.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    // Stats
    final ongoingCount = unitProjects.where((p) => p.status == 'Sedang Berlangsung').length;
    final totalProjects = unitProjects.length;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔧 Project Maintenance',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Kelola project perbaikan & maintenance hotel',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9AA3B2)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddProjectDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Project Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E9F7E), // teal match
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mini statistics overview
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Project Aktif',
                    value: ongoingCount.toString(),
                    icon: Icons.sync_outlined,
                    iconBgColor: const Color(0xFFEEF3FB),
                    iconColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Total Project',
                    value: totalProjects.toString(),
                    icon: Icons.checklist_outlined,
                    iconBgColor: const Color(0xFFD1FAE5),
                    iconColor: const Color(0xFF0E9F7E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filter status & search
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari project...',
                      prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF9AA3B2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE4E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE4E8F0)),
                      ),
                    ),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                // Dropdown status filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE4E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatusFilter,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5A6478)),
                      onChanged: (val) {
                        setState(() {
                          _selectedStatusFilter = val!;
                        });
                      },
                      items: const [
                        DropdownMenuItem(value: 'Semua', child: Text('Semua Status')),
                        DropdownMenuItem(value: 'Akan Dikerjakan', child: Text('Akan Dikerjakan')),
                        DropdownMenuItem(value: 'Sedang Berlangsung', child: Text('Berlangsung')),
                        DropdownMenuItem(value: 'Selesai', child: Text('Selesai')),
                      ],
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),

            if (filteredProjects.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 50),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      _searchQuery.isNotEmpty ? Icons.search_off_outlined : Icons.construction_outlined,
                      size: 52,
                      color: const Color(0xFF9AA3B2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Tidak ada hasil untuk "$_searchQuery"'
                          : 'Tidak ada project maintenance.',
                      style: const TextStyle(color: Color(0xFF9AA3B2), fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredProjects.length,
                itemBuilder: (context, index) {
                  final project = filteredProjects[index];
                  final dateText = '${project.startDate} s/d ${project.endDate}';
                  return ProjectCard(
                    name: project.name,
                    area: project.area,
                    category: project.category,
                    status: project.status,
                    priority: project.priority,
                    progress: project.progress,
                    pic: project.pic,
                    cost: project.cost,
                    dateText: dateText,
                    onTap: () {
                      _showEditProjectDialog(project);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
