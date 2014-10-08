import std.container;

import gameobject;
import Camera;
import stdlib;

class Scene {
    Array!(Pair!(Camera, Array!(GameObject))) data;
    this() {}
    void addPair(Camera camera) {
        addPair(camera, *new Array!(GameObject));
    }
    void addPair(Camera camera, Array!(GameObject) objects) {
        data ~= new Pair!(Camera, Array!(GameObject))(camera, objects);
    }

    void changePairCamera(Camera oldC, Camera newC) {
        foreach (Pair!(Camera, Array!(GameObject)) i; data) {
            if (i.first == oldC) {
                i.first = newC;
                break;
            }
        }
    }

    void addToPair(Camera camera, GameObject object) {
        foreach (Pair!(Camera, Array!(GameObject)) i; data) {
            if (i.first == camera) {
                foreach(GameObject obj; i.second)
                    if (obj == object)
                        return;
                i.second ~= object;            
                break;
            }
        }
    }

    Array!(GameObject) pair(Camera camera) {
        foreach (Pair!(Camera, Array!(GameObject)) i; data)
            if (i.first == camera)
                return i.second;
        return *new Array!(GameObject);
    }

    void clearPair(Camera camera) {
        foreach (Pair!(Camera, Array!(GameObject)) i; data)
            if (i.first == camera)
                i.second.clear();
    }

    void removeFromPair(Camera camera, GameObject object) {
        foreach (Pair!(Camera, Array!(GameObject)) i; data) {
            if (i.first == camera) {
                for (uint j = 0; j < i.second.length; j++) {
                    if (i.second[j] == object) {
                        i.second.linearRemove(i.second[j..j+1]);
                        return;
                    }
                }
            }
        }
    }
}


