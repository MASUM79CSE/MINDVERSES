import 'package:sembast/sembast.dart';

import 'storage_database_stub.dart'
    if (dart.library.io) 'storage_database_io.dart'
    if (dart.library.js_interop) 'storage_database_web.dart' as platform;

Future<Database> openStorageDatabase() => platform.openStorageDatabase();
