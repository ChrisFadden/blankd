import std.container;

class Pool(T)
{
    Array!(T) pool;
    Array!(T) items;

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
        T t = new T();
        items ~= t;
        return t;
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

    Array!(T) getItems(){
        return items;
    }
}

