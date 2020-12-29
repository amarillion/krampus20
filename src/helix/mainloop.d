module helix.mainloop;

//NOTE: these pragma's work when the source of modtwist is included.
//will it also work when twist is a compiled library?
pragma(lib, "dallegro5");
pragma(lib, "allegro");
pragma(lib, "allegro_primitives");
pragma(lib, "allegro_image");
pragma(lib, "allegro_font");
pragma(lib, "allegro_ttf");
pragma(lib, "allegro_color");

import std.stdio;
import std.string;
import std.json;
import std.range;
import std.exception;

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import helix.component;
import helix.resources;
import helix.style;
import helix.util.vec;
import helix.util.rect;
import helix.util.string;

/**
	MainLoop is responsible for:

	* Initialising allegro
	* Running the main event loop
	* passing mouse & keyboard events, managing focus
	* keeping a map of components by id
	* Hooking up elements to style and resources
	* Doing layout

	TODO:
	'MainLoop' could be renamed to 'Window'.
*/

enum defaultRootStyleData = parseJSON(`{
	"font": "builtin_font", 
	"font-size": 17, 
	"color": "white", 
	"background": "transparent" 
}`);
		
class MainLoop
{
	ResourceManager resources;
	private Style defaultStyle;
	private Style[string] styleBySelector;
		
	ALLEGRO_EVENT_QUEUE* queue;
	ALLEGRO_DISPLAY* display;
	ALLEGRO_TIMER *timer;
	
	void init()
	{
		// TODO
		// ALLEGRO_CONFIG* cfg = al_load_config_file("turnover.ini");
		
		//TODO: make configurable
		al_set_new_display_flags(ALLEGRO_WINDOWED | ALLEGRO_RESIZABLE);
		
		display = al_create_display(1280, 720);
				
		queue = al_create_event_queue();

		al_install_keyboard();
		al_install_mouse();
		al_init_image_addon();
		al_init_font_addon();
		al_init_ttf_addon();
		al_init_primitives_addon();

		al_register_event_source(queue, al_get_display_event_source(display));
		al_register_event_source(queue, al_get_keyboard_event_source());
		al_register_event_source(queue, al_get_mouse_event_source());
		
		al_show_mouse_cursor(display);
		
  		timer = al_create_timer(0.02);
		al_register_event_source(queue, al_get_timer_event_source(timer));
		al_start_timer(timer);

		resources = new ResourceManager();
		auto hardcodedDefaultStyle = new Style(resources, defaultRootStyleData); 
		defaultStyle = new Style(resources, "{}", hardcodedDefaultStyle);

		rootComponent = new RootComponent(this);
	}


	void applyStyling(string resourceKey) {
		auto styleMap = resources.getJSON(resourceKey);

		if ("default" in styleMap) {
			defaultStyle.styleData = styleMap["default"];
		}

		foreach (k, v; styleMap.object) {
			if (k == "default") continue;
			styleBySelector[k] = new Style(resources, v, defaultStyle);
		}
	}

	Style getStyle(string selector) {
		if (selector in styleBySelector) {
			return styleBySelector[selector];
		}
		else {
			return defaultStyle;
		}
	}

	void run()
	{
		assert (!rootComponent.children.empty, "Must add & switch to a state");
		
		bool exit = false;
		bool need_redraw = true;
		
		while(!exit)
		{
			ALLEGRO_EVENT event;
			while(!exit)
			{
				if (need_redraw && al_is_event_queue_empty(queue))
				{
					GraphicsContext gc = new GraphicsContext();
					rootComponent.draw(gc);

					al_flip_display();
					need_redraw = false;
				}

				al_wait_for_event(queue, &event);
				switch(event.type)
				{
					case ALLEGRO_EVENT_DISPLAY_RESIZE:
					{
						al_acknowledge_resize(event.display.source);
						calculateLayout();
						break;
					}
					case ALLEGRO_EVENT_DISPLAY_CLOSE:
					{
						exit = true;
						break;
					}
					case ALLEGRO_EVENT_KEY_CHAR:
					{
						rootComponent.onKey(event.keyboard.keycode, event.keyboard.unichar, event.keyboard.modifiers);
						switch(event.keyboard.keycode)
						{
							case ALLEGRO_KEY_ESCAPE:
							{
								exit = true;
								break;
							}
							default:
						}
						break;
					}
					case ALLEGRO_EVENT_MOUSE_BUTTON_DOWN:
					case ALLEGRO_EVENT_MOUSE_BUTTON_UP:
					case ALLEGRO_EVENT_MOUSE_AXES:
						dispatchMouseEvent(event);
						break;
					case ALLEGRO_EVENT_TIMER: 
						rootComponent.update();
						need_redraw = true;
						break;
					default:
				}
			}
		
		}
		
		done();
	}

	void dispatchMouseEvent(ALLEGRO_EVENT event) {
		
		Point cursor = Point(event.mouse.x, event.mouse.y);
		
		Component comp = rootComponent;
		bool goDeeper = true;
		while (goDeeper) {
			bool match = false;
			foreach (child; retro(comp.children)) {
				// TODO also take into account scrollbars, viewports & offsets
				if (child.contains(cursor)) {
					match = true;
					comp = child;
					break;
				}
			}
			if (!match) {
				goDeeper = false;
			}
		}

		// TODO: enter & leave events...
		// TODO: capturing mouse events for scrollbars and sliders

		// go down the component tree...
		switch (event.type) {
			case ALLEGRO_EVENT_MOUSE_BUTTON_DOWN:
			{
				comp.onMouseDown(cursor);
				break;
			}
			case ALLEGRO_EVENT_MOUSE_BUTTON_UP:
			{
				comp.onMouseUp(cursor);
				break;
			}
			case ALLEGRO_EVENT_MOUSE_AXES:
			{
				comp.onMouseMove(cursor);
				break;
			}
			default: assert(false);
		}
	}

	void calculateLayout() {

		void calculateRecursive(Component comp, Rectangle parentRect, int depth = 0) {
			comp.shape = comp.layoutData.calculate(parentRect);
			writeln(" ".rep(depth), comp.classinfo, " ", comp.shape);
			foreach(child; comp.children) {
				calculateRecursive(child, comp.shape, depth + 1);
			}
		}

		Rectangle displayRect = Rectangle(0, 0, display.al_get_display_width, display.al_get_display_height);
		calculateRecursive (rootComponent, displayRect);
	}

	private void done()
	{
		 al_destroy_timer(timer);
		 al_destroy_display(display);
		 al_destroy_event_queue(queue);
	}

	/*
	void setRootComponent(Component value)
	{
		assert(display, "Programming error: display must be initialized before calling setRootComponent()");
		this.engine = value;
		engine.w = al_get_display_width(display);
		engine.h = al_get_display_height(display);
		engine.x = 0;
		engine.y = 0;
		engine.window = this;

		calculateLayout();
	}
	*/

	/**
		Switches the complete scene to a new Scene
	*/
	void switchState(string name) {
		enforce(name in states);
		rootComponent.clearChildren();
		rootComponent.addChild(states[name]);
		calculateLayout();
	}

	void addState(string name, Component state) {
		states[name] = state;
	}

	/** add a scene at the root level. 
		Useful for dialogs (modal and non-modal)  */
	void pushScene(Component scene, bool modal = true) {
		rootComponent.addChild(scene);
		calculateLayout();
	}

	void popScene() {
		rootComponent.removeLastChild();
		calculateLayout();
	}

	Component[string] states;
	RootComponent rootComponent;

	class RootComponent : Component {

		this(MainLoop window) {
			super(window);
		}

		override void update() {
			foreach (child; children) {
				child.update();
			}
		}

		override void draw(GraphicsContext gc) {
			foreach (child; children) {
				child.draw(gc);
			}
		}

		void clearChildren() {
			children = [];
		}

		void removeLastChild() {
			children = children[0..$-1];
		}
	}
	
}
