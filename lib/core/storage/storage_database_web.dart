import 'package:sembast_web/sembast_web.dart';

Future<Database> openStorageDatabase() => databaseFactoryWeb.openDatabase('mindverse.db');
