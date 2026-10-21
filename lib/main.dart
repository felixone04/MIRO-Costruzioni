import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'app.dart';
import 'data/repository.dart';
import 'state/app_state.dart';
import 'widgets/common.dart';

Future<void> main() async {
  appStartedAt = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT');
  VisibilityDetectorController.instance.updateInterval = const Duration(
    milliseconds: 100,
  );

  final state = AppState(await LocalRepository.open());
  await state.load();
  // Il sito usa il routing con "#": i parametri stanno dopo il cancelletto
  // (es. /#/?prova=1 o /#/?tema=progetto).
  state.applyLinkParams({
    ...Uri.base.queryParameters,
    ...Uri.parse(Uri.base.fragment).queryParameters,
  });

  runApp(ChangeNotifierProvider.value(value: state, child: const MiroApp()));
}
