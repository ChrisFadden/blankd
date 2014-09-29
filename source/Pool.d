
class Pool(T)
{
    Array!(T) pool;
    this() {
    }
    T newObj() {
        for (int i = 0; i < pool.length; i++) {
            if (pool[i] !is null) {
                T thing = pool[i];
                pool[i] = null;
                return thing;
            }
        }
        return new T();
    }

    void release(T obj) {
        for (int i = 0; i < pool.length; i++) {
            if (pool[i] is null) {
                pool[i] = obj;
                return;
            }
        }
        pool ~= obj;
    }
}

