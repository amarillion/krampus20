module engine;

import helix.color;
import helix.component;
import helix.style;
import helix.resources;
import helix.mainloop;
import helix.util.vec;
import helix.util.rect;
import helix.tilemap;
import helix.tilemapview;

import std.stdio;
import std.conv;
import std.math;
import std.exception;

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_font;
import allegro5.allegro_ttf;

import std.json;

class StyledComponent : Component {

	this(MainLoop window) {
		super(window);
	}

	override void update() {}
}

class ImageComponent : StyledComponent {

	ALLEGRO_BITMAP *img = null;

	this(MainLoop window) {
		super(window);
	}

	override void draw(GraphicsContext gc) {
		assert(img);
		// stretch mode...
		int iw = img.al_get_bitmap_width;
		int ih = img.al_get_bitmap_height;
		// TODO: why doesn't it stretch the right way?
		al_draw_scaled_bitmap(img, 0, 0, iw, ih, x, y, w, h, 0);
	}

	override void update() {}
}

class Button : StyledComponent {

	this(MainLoop window) {
		super(window);
	}

	override void onMouseDown(Point p) {
		onAction.dispatch();
	}
}

class State : Component {

	this(MainLoop window) {
		super(window);
	}

	//TODO: I want to move this registry to window...
	private Component[string] componentRegistry;

	void buildDialog(JSONValue data) {
		auto styleData = `{ "background": "#888888", "border": "#444444", "border-left": "#BBBBBB", "border-top": "#BBBBBB", "border-width": 2.0, "color": "#FFFFFF" }`;
		Style style = window.createStyle(styleData);
		buildDialogRecursive(this, style, data);
	}

	void buildDialogRecursive(Component parent, Style style, JSONValue data) {

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
				case "tilemap": {
					auto tmv = new TileMapView(window);
					div = tmv;
					break;
				}
				default: div = new StyledComponent(window); break;
			}

			assert("layout" in eltData);
			div.layoutData.fromJSON(eltData["layout"].object);

			if ("text" in eltData) {
				div.text = eltData["text"].str;
			}
			div.style = style;
			if ("id" in eltData) {
				div.id = eltData["id"].str;
				componentRegistry[div.id] = div;
			}

			parent.addChild(div);
			if ("children" in eltData) {
				buildDialogRecursive(div, style, eltData["children"]);
			}
		}
	}

	Component getElementById(string id) {
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

class GameState : State {

	this(MainLoop window) {
		super(window);

		/* GAME SCREEN */
		buildDialog(window.resources.getJSON("game-layout"));
		
		{
			auto tilemapElt = cast(TileMapView)getElementById("tmap_planet_layer");
			JSONValue val = window.resources.getJSON("planetscape");
			tilemapElt.tilemap.fromTiledJSON(val);
			tilemapElt.tilemap.tilelist.bmp = window.resources.getBitmap("biotope");
		}
		{
			auto tilemapElt = cast(TileMapView)getElementById("tmap_organism_layer");
			JSONValue val = window.resources.getJSON("speciesmap");
			tilemapElt.tilemap.fromTiledJSON(val);
			tilemapElt.tilemap.tilelist.bmp = window.resources.getBitmap("species");
		}

	}

}

class Dialog : State {

	this(MainLoop window) {
		super(window);
		buildDialog(window.resources.getJSON("dialog-layout"));

		getElementById("btn_ok").onAction.add({ 
			window.popScene(); 
		});
	}

}

class MenuState : State {

	this(MainLoop window) {
		super(window);
		
		/* MENU */
		buildDialog(window.resources.getJSON("menu-layout"));
		
		getElementById("btn_start_game").onAction.add({ 
			window.switchState("GameState");
		});

		getElementById("btn_credits").onAction.add({ 
			Dialog dlg = new Dialog(window);
			window.pushScene(dlg); 
		});

	}

}
