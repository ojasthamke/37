import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repositories.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) => SupabaseCategoryRepository());
final productRepositoryProvider = Provider<ProductRepository>((ref) => SupabaseProductRepository());
final customerRepositoryProvider = Provider<CustomerRepository>((ref) => SupabaseCustomerRepository());
final orderRepositoryProvider = Provider<OrderRepository>((ref) => SupabaseOrderRepository());
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => SupabaseSettingsRepository());
