import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final shellScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) => GlobalKey<ScaffoldState>());
