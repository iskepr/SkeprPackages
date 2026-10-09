/// كاش بسيط بيحفظ آخر معادلات اترسمت عشان ميعيدش حسابها تاني (بيوفر وقت كبير جداً)
class LruCache<K, V> {
  LruCache({required this.maxSize}) : assert(maxSize > 0);

  final int maxSize;
  final _map = <K, V>{};

  V? get(K key) {
    final v = _map.remove(key);
    if (v != null) _map[key] = v; // بنجدد الـ Key عشان ميتحذفش
    return v;
  }

  V getOrPut(K key, V Function() create) {
    final existing = get(key);
    if (existing != null) return existing;

    final v = create();
    _map.remove(key);
    _map[key] = v;

    while (_map.length > maxSize) {
      _map.remove(_map.keys.first); // بنحذف أقدم حاجة لو الكاش اتملى
    }

    return v;
  }

  void clear() => _map.clear();
}
