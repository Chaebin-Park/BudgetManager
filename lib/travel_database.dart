import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'travel_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE travels (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        currency TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE travellers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        travel_id INTEGER,
        name TEXT,
        contribution INTEGER DEFAULT 0,
        FOREIGN KEY (travel_id) REFERENCES travels (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        travel_id INTEGER,
        name TEXT,
        amount INTEGER,
        FOREIGN KEY (travel_id) REFERENCES travels (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_travellers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expense_id INTEGER,
        traveller_id INTEGER,
        FOREIGN KEY (expense_id) REFERENCES expenses (id),
        FOREIGN KEY (traveller_id) REFERENCES travellers (id)
      )
    ''');
  }

  Future<int> insertTravel(Map<String, dynamic> travel) async {
    Database db = await database;
    return await db.insert('travels', travel);
  }

  Future<int> insertTraveller(Map<String, dynamic> traveller) async {
    Database db = await database;
    return await db.insert('travellers', traveller);
  }

  Future<List<Map<String, dynamic>>> getTravels() async {
    Database db = await database;
    return await db.query('travels');
  }

  Future<List<Map<String, dynamic>>> getTravellers(int travelId) async {
    Database db = await database;
    return await db.query('travellers', where: 'travel_id = ?', whereArgs: [travelId]);
  }

  Future<int> deleteTravel(int travelId) async {
    Database db = await database;

    // Delete expense_travellers related to this travel
    await db.delete(
      'expense_travellers',
      where: 'expense_id IN (SELECT id FROM expenses WHERE travel_id = ?)',
      whereArgs: [travelId],
    );

    // Delete travellers related to this travel
    await db.delete(
      'travellers',
      where: 'travel_id = ?',
      whereArgs: [travelId],
    );

    // Delete expenses related to this travel
    await db.delete(
      'expenses',
      where: 'travel_id = ?',
      whereArgs: [travelId],
    );

    // Delete the travel
    return await db.delete(
      'travels',
      where: 'id = ?',
      whereArgs: [travelId],
    );
  }

  Future<int> deleteTraveller(int travellerId) async {
    Database db = await database;
    await db.delete('expense_travellers', where: 'traveller_id = ?', whereArgs: [travellerId]);
    return await db.delete('travellers', where: 'id = ?', whereArgs: [travellerId]);
  }

  Future<int> updateTraveller(Map<String, dynamic> traveller) async {
    Database db = await database;
    return await db.update(
      'travellers',
      traveller,
      where: 'id = ?',
      whereArgs: [traveller['id']],
    );
  }

  Future<int> insertExpense(Map<String, dynamic> expense) async {
    Database db = await database;
    return await db.insert('expenses', expense);
  }

  Future<int> insertExpenseTraveller(Map<String, dynamic> expenseTraveller) async {
    Database db = await database;
    return await db.insert('expense_travellers', expenseTraveller);
  }

  Future<List<Map<String, dynamic>>> getExpenses(int travelId) async {
    Database db = await database;
    return await db.query('expenses', where: 'travel_id = ?', whereArgs: [travelId]);
  }

  Future<List<Map<String, dynamic>>> getAllExpenses() async {
    Database db = await database;
    return await db.query('expenses');
  }

  Future<List<Map<String, dynamic>>> getAllTravellers() async {
    Database db = await database;
    return await db.query('travellers');
  }

  Future<List<Map<String, dynamic>>> getExpenseTravellers(int expenseId) async {
    Database db = await database;
    return await db.query('expense_travellers', where: 'expense_id = ?', whereArgs: [expenseId]);
  }

  Future<int> deleteExpense(int expenseId) async {
    Database db = await database;
    await db.delete('expense_travellers', where: 'expense_id = ?', whereArgs: [expenseId]);
    return await db.delete('expenses', where: 'id = ?', whereArgs: [expenseId]);
  }

  Future<int> updateExpenseWithTravellers(Map<String, dynamic> expense, List<bool> selectedTravellers, List<Map<String, dynamic>> travellerList) async {
    Database db = await database;

    // Update the expense
    await db.update(
      'expenses',
      expense,
      where: 'id = ?',
      whereArgs: [expense['id']],
    );

    // Delete old expense_travellers entries
    await db.delete(
      'expense_travellers',
      where: 'expense_id = ?',
      whereArgs: [expense['id']],
    );

    // Insert new expense_travellers entries
    for (int i = 0; i < selectedTravellers.length; i++) {
      if (selectedTravellers[i]) {
        await db.insert('expense_travellers', {
          'expense_id': expense['id'],
          'traveller_id': travellerList[i]['id'],
        });
      }
    }

    return 1;
  }
}
