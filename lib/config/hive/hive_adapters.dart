import 'package:hive_ce/hive_ce.dart';
import 'package:peluna/models/diary_model.dart';

@GenerateAdapters([AdapterSpec<Diary>()])
part 'hive_adapters.g.dart';
