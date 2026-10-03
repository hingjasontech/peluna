import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:peluna/models/diary_model.dart';

// ValueNotifier
var selectedDateTimeNotifier = ValueNotifier<DateTime>(DateTime.now());
var currentDiaryNotifier = ValueNotifier<Diary?>(null);
var currentPageIndexNotifier = ValueNotifier<int>(0);

// Boxes
late Box<Diary> diariesBox;
late Box settingsBox;
