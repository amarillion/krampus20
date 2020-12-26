module helix.style;

import std.json;
import allegro5.allegro;
import allegro5.allegro_font;
import helix.color;
import std.conv;
import helix.resources;

// unittest {
// 	parseColorStr()
// }
private static ALLEGRO_FONT *builtinFont = null;

// a properties map...
class Style {

	Style parent = null;
	ResourceManager resources;
	JSONValue styleData;
	
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

	ALLEGRO_COLOR getColor(string key, ALLEGRO_COLOR fallback = Color.BLACK) {
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
		else {
			return fallback;
		}
	}

	double getNumber(string key, double fallback = 0.0) {
		assert(key in [
			"border-width": 1
		]);
		if (key in styleData) {
			return styleData[key].floating;
		}
		else {
			return fallback;
		}
	}

	ALLEGRO_FONT *getFont() {
		if ("font" in styleData) {
			string fontName = styleData["font"].str;
			return resources.getFont(fontName);
		}
		if (parent) {
			return parent.getFont();
		}
		return null;
	}
}
