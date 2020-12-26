module helix.grid;

import common.vec;
import std.conv;

// TODO: generalize for N dimensions...
class Grid(T) {
	T[] data;
	Point size;
	
	@property int width() const { return size.x; }
	@property int height() const { return size.y; }

	this(ulong width, ulong height, T initialValue = T.init) {
		this(Point(cast(int)width, cast(int)height), initialValue);
	}

	this(Point size, T initialValue = T.init) {
		this.size = size;
		data = [];
		data.length = size.x * size.y;
		if (initialValue != T.init) {
			foreach(ref cell; data) {
				cell = initialValue;
			}
		}
	}

	bool inRange(Point p) const {
		return (p.x >= 0 && p.x < size.x && p.y >= 0 && p.y < size.y);
	}

	ulong toIndex(Point p) const {
		return p.x + (size.x * p.y);
	}

	void set(Point p, T val) {
		assert(inRange(p));
		data[toIndex(p)] = val;
	}

	T get(Point p) const {
		assert(inRange(p));
		return data[toIndex(p)];
	}

	string format(string cellSep = ", ", string lineSep = "\n") {
		char[] result;
		int i = 0;
		
		const int lineSize = size.x;
		bool firstLine = true;
		bool firstCell = true;
		foreach (base; PointRange(size)) {
			if (i % lineSize == 0 && !firstLine) {
				result ~= lineSep;
				firstCell = true;
			}
			if (!firstCell) result ~= cellSep;
			result ~= to!string(get(base));
			i++;
			
			firstLine = false;
			firstCell = false;
		}
		return result.idup;
	}

	override string toString() {
		return format();
	}

}
