import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models.dart';
import 'screens/clients_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KarnetApp());
}

// ==================== APP ====================
class KarnetApp extends StatelessWidget {
  const KarnetApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Karnet Credit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B8A6B)),
        useMaterial3: true,
        fontFamily: 'Cairo',
      ),
      home: ClientsScreen(), // Remove const here
    );
  }
}

// ================== HOME SCREEN ==================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Client> _clients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshClients();
  }

  Future<void> _refreshClients() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllClients();
    
    for (var client in data) {
      client.solde = await DatabaseHelper.instance.getSoldeClient(client.id!);
    }
    
    setState(() {
      _clients = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Karnet Credit', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshClients,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _clients.isEmpty
              ? const Center(child: Text('مازال ما كاين حتى كليان'))
              : ListView.builder(
                  itemCount: _clients.length,
                  itemBuilder: (context, index) {
                    final client = _clients[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(client.initiales)),
                        title: Text(client.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(client.telephone ?? 'بدون هاتف'),
                        trailing: Text(
                          '${client.solde.toStringAsFixed(2)} DH',
                          style: TextStyle(
                            color: client.solde > 0 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddClientSheet(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _showAddClientSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AddClientSheet(onAdded: _refreshClients),
      ),
    );
  }
}

// ================== ADD CLIENT SHEET ==================
class AddClientSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const AddClientSheet({required this.onAdded, super.key});

  @override
  State<AddClientSheet> createState() => _AddClientSheetState();
}

class _AddClientSheetState extends State<AddClientSheet> {
  final _nomController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('إضافة زبون جديد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          TextField(controller: _nomController, decoration: const InputDecoration(labelText: 'الإسم الكامل')),
          TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف'), keyboardType: TextInputType.phone),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (_nomController.text.isNotEmpty) {
                await DatabaseHelper.instance.createClient(Client(
                  nom: _nomController.text,
                  telephone: _phoneController.text,
                  dateCreation: DateTime.now(),
                ));
                widget.onAdded();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          )
        ],
      ),
    );
  }
}