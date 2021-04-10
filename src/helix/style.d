module helix.style;

import std.json;
import allegro5.allegro;
import allegro5.allegro_font;
import helix.color;
import std.conv;
import helix.resources;
import std.format: format;

// unittest {
// 	parseColorStr()
// }
private static ALLEGRO_FONT *builtinFont = null;

// a properties map...
class Style {

	Style parent = null;
	ResourceManager resources;
	JSONValue styleData;
	
	this(Style base, Style parent) {
		this.resources = base.resources;
		this.styleData = base.styleData;
		this.parent = parent;
	}

	this(ResourceManager resources) {
		this.resources = resources;
	}

	this(ResourceManager resources, string styleDataStr, Style parent = null) {
		this(resources, parseJSON(styleDataStr), parent);
	}

	this(ResourceManager resources, JSONValue styleData, Style parent = null) {
		this(resources);
		this.styleData = styleData;
		this.parent = parent;
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
		]);
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
		]);
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
			"font": 1
		]);
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

	ALLEGRO_FONT *getFont() {
		const fontName = getString("font");
		const fontSize = getNumber("font-size");
		return resources.fonts[fontName].get(cast(int)fontSize);
	}

	override string toString() {
		char[] result = format!"Style{%(%s: %s, %)}"(styleData.object).dup;
		if (parent) result ~= format!", parent: %s"(parent);
		return result.idup;
	}
}
