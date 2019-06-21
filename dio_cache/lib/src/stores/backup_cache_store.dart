import 'package:dio_cache/src/cache_response.dart';
import 'package:dio_cache/src/stores/memory_cache_store.dart';
import 'package:meta/meta.dart';

import 'cache_store.dart';

/// A store that reads from a [primaryStore] first, and then
/// from a [backupStore].
/// 
/// The resulting futures form all operations are the ones from
/// the [primaryStore]. The [backupStore] operation are launched
/// but not awaited (except for [get]).
/// 
/// When getting a value with [get], if a cache value exists in 
/// [backupStore], but not in [primaryStore], it is saved
/// to the [primaryStore] before returning the loaded value.
class BackupCacheStore extends CacheStore {
  final CacheStore primaryStore;
  final CacheStore backupStore;

  BackupCacheStore({@required this.backupStore, CacheStore activeStore})
      : assert(backupStore != null),
        this.primaryStore = activeStore ?? MemoryCacheStore();

  @override
  Future<void> clean(CachePriority priorityOrBelow) {
    this.backupStore.clean(priorityOrBelow);
    return this.primaryStore.clean(priorityOrBelow);
  }

  @override
  Future<void> delete(String method, String url) {
    this.backupStore.delete(method, url);
    return this.primaryStore.delete(method, url);
  }

  @override
  Future<CacheResponse> get(String method, String url) async {
    final existing = await this.primaryStore.get(method, url);
    if (existing != null) {
      return existing;
    }

    final backup = await this.backupStore.get(method, url);
    if (backup != null) {
      await primaryStore.set(backup);
      return backup;
    }
    return null;
  }

  @override
  Future<void> set(CacheResponse response) {
    this.backupStore.set(response);
    return this.primaryStore.set(response);
  }

  @override
  Future<void> updateExpiry(String method, String url, DateTime newExpiry) {
    this.backupStore.updateExpiry(method, url, newExpiry);
    return this.primaryStore.updateExpiry(method, url, newExpiry);
  }
}
