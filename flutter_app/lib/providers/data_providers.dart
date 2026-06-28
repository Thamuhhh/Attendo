import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student.dart';
import '../models/fee_record.dart';
import '../services/api_service.dart';

final dataRefreshProvider = StateProvider<int>((ref) => 0);

void refreshData(WidgetRef ref) {
  ref.read(dataRefreshProvider.notifier).state++;
}

final studentListProvider = FutureProvider<List<Student>>((ref) async {
  ref.watch(dataRefreshProvider);
  return ApiService.getStudents();
});

final feeSummaryProvider = FutureProvider.family<FeeSummary?, int>((ref, year) async {
  ref.watch(dataRefreshProvider);
  return ApiService.getFeeSummary(year);
});
