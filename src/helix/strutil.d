module helix.strutil;

string rep(string val, int num) {
	char[] result;
	foreach(i; 0..num) {
		result ~= val;
	}
	return result.idup;
}