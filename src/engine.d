module engine;

import helix.color;
import helix.component;
import helix.style;
import helix.resources;
import helix.mainloop;
import helix.util.vec;
import helix.util.rect;
import helix.tilemap;
import helix.widgets;

import std.stdio;
import std.conv;
import std.math;
import std.exception;
import std.format;

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_font;
import allegro5.allegro_ttf;

import std.json;

import dialog;

class State : Component {

	this(MainLoop window) {
		super(window);
	}

	//TODO: I want to move this registry to window...
	private Component[string] componentRegistry;

	void buildDialog(JSONValue data) {
		buildDialogRecursive(this, data);
	}

	void buildDialogRecursive(Component parent, JSONValue data) {

		assert(data.type == JSONType.ARRAY);

		foreach (eltData; data.array) {
			// create child components
		
			Component div = null;
			string type = eltData["type"].str;
			switch(type) {
				case "button": {
					div = new Button(window);
					break;
				}
				case "image": {
					ImageComponent img = new ImageComponent(window);
					img.img = window.resources.getBitmap(eltData["src"].str);
					div = img;
					break;
				}
				case "pre": {
					auto pre = new PreformattedText(window);
					div = pre;
					break;
				}
				default: div = new StyledComponent(window); break;
			}

			assert("layout" in eltData);
			div.layoutData.fromJSON(eltData["layout"].object);

			if ("text" in eltData) {
				div.text = eltData["text"].str;
			}
			
			Style style = window.getStyle(type);
			Style selectedStyle = window.getStyle(type, "selected");
			if ("style" in eltData) {
				div.setStyle(new Style(window.resources, eltData["style"], style));
			}
			else {
				div.setStyle(style);
			}

			if ("id" in eltData) {
				div.id = eltData["id"].str;
				componentRegistry[div.id] = div;
			}

			parent.addChild(div);
			if ("children" in eltData) {
				buildDialogRecursive(div, eltData["children"]);
			}
		}
	}

	Component getElementById(string id) {
		enforce(id in componentRegistry, format("Component '%s' not found", id));
		return componentRegistry[id];
	}

	override void draw(GraphicsContext gc) {
		foreach (child; children) {
			child.draw(gc);
		}
	}

	override void update() {
	}
}

class TitleState : State {

	this(MainLoop window) {
		super(window);
		
		/* MENU */
		buildDialog(window.resources.getJSON("title-layout"));
		
		getElementById("btn_start_game").onAction.add({ 
			window.switchState("GameState");
		});

		getElementById("btn_credits").onAction.add({ 
			const text = 
`<h1>Exo Keeper</h1>
<p>
Exo Keeper is a game about surviving and thriving on an exo-planet.
<p>
Exo Keeper was made in just 72hours for the <a href="https://ldjam.com/events/ludum-dare/46/">Ludum Dare 46</a> Game Jam. The theme of LD46 was:
<blockquote>
<b>Keep it alive</b>
</blockquote>
<p>Authors:</p>
<dl>
<dd><a href="https://twitter.com/mpvaniersel">Amarillion</a> (Code)
<dd><a href="https://github.com/gekaremi">Gekaremi</a> (Design)
<dd><a href="https://www.instagram.com/l_p_kongroo">Tatiana Kondratieva</a> (Art)
<dd><a href="http://www.dodonoghue.com/">Dónall O'Donoghue</a> (Music)
</dl>
`;
			openDialog(window, text);
		});

	}

}
