module helix.signal;

struct Signal {

	void delegate()[] listeners;

	void add(void delegate() f) {
		listeners ~= f;
	}

	void dispatch() {
		foreach (f; listeners) {
			f();
		}
	}

	// TODO - removing listeners
}