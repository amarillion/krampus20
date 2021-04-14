module helix.style;

import std.json;
import allegro5.allegro;
import allegro5.allegro_font;
import helix.color;
import std.conv;
import helix.resources;
import std.format: format;
import helix.allegro.font;

// unittest {
// 	parseColorStr()
// }
private static Font builtinFont = null;

enum StyleRank {
	HARDCODED = 0,
	THEME = 1,
	ANCESTOR = 2, // set on a parent element or root element
	TYPED = 3, // for a specific tag such as "a" or "h1"
	STATE = 4, // for "hover" or "disabled"
	LOCAL = 5, // override for a specific element
}
	
// a properties map...
class Style {

	Style parent = null;
	ResourceManager resources;
	JSONValue styleData;
	string name;
	StyleRank rank;

	this(Style base, Style parent) {
		this.resources = base.resources;
		this.styleData = base.styleData;
		this.name = base.name;
		this.rank = base.rank;
		this.parent = parent;
	}

	this(ResourceManager resources) {
		this.resources = resources;
		this.name = "uninitialized";
	}

	this(ResourceManager resources, StyleRank rank, string name, string styleDataStr, Style parent = null) {
		this(resources, rank, name, parseJSON(styleDataStr), parent);
	}

	this(ResourceManager resources, StyleRank rank, string name, JSONValue styleData, Style parent = null) {
		this(resources);
		this.styleData = styleData;
		this.name = name;
		this.parent = parent;
		this.rank = rank;
	}

	ALLEGRO_COLOR getColor(string key, string fallbackKey = "") {
		assert(key in [
			"color": 1, // foreground color / text color
			"background":1, 
			"border":1,
			"border-top":1,
			"border-left":1, 
			"border-right":1,
			"border-bottom":1
		], format("key '%s' not allowed for color property", key));
		if (key in styleData) {
			string val = styleData[key].str;
			return parseColor(val);
		}
		else if (fallbackKey != "" && fallbackKey in styleData) {
			string val = styleData[fallbackKey].str;
			return parseColor(val);
		}
		else {
			if (parent) {
				return parent.getColor(key, fallbackKey);
			}
		}
		return Color.BLACK;
	}

	double getNumber(string key) {
		assert(key in [
			"border-width": 1,
			"font-size": 1,
			"min-size": 1,
			"size": 1
		], format("key '%s' not allowed for number property", key));
		if (key in styleData) {
			JSONValue val = styleData[key];
			if (val.type == JSONType.FLOAT) {
				return styleData[key].floating;
			}
			else {
				return styleData[key].integer;
			}
		}
		else {
			if (parent) {
				return parent.getNumber(key);
			}
		}
		return double.nan;
	}

	string getString(string key) {
		assert(key in [
			"font": 1,
			"text-decoration": 1
		], format("key '%s' not allowed for string property", key));
		if (key in styleData) {
			return styleData[key].str;
		}
		else {
			if (parent) {
				return parent.getString(key);
			}
		}
		return "";
	}

	Font getFont() {
		const fontName = getString("font");
		const fontSize = getNumber("font-size");
		return resources.fonts[fontName].get(cast(int)fontSize);
	}

	override string toString() {
		char[] result = format!"Style %s {%(%s: %s, %)}"(name, styleData.object).dup;
		if (parent) result ~= format!", parent: %s"(parent);
		return result.idup;
	}
}
