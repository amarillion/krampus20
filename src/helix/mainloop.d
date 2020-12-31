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
import allegro5.allegro_acodec;

import helix.component;
import helix.resources;
import helix.style;
import helix.util.vec;
import helix.util.rect;
import helix.util.string;
import helix.audio;

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
	AudioManager audio;

	private Style defaultStyle;
	private Style[string] styleBySelector;
		
	ALLEGRO_DISPLAY* display;
	ALLEGRO_CONFIG *config;
	private ALLEGRO_PATH *localAppData;
	private ALLEGRO_PATH *configPath;
	private ALLEGRO_EVENT_QUEUE* queue;
	private ALLEGRO_TIMER *timer;

/*

	// set_volume_per_voice (1); //TODO
	if (isSoundInstalled())
	{
		if (!al_install_audio())
		{
			// could not get sound to work
			setSoundInstalled(false);
//			allegro_message ("Could not initialize sound. Sound is turned off.\n%s\n", allegro_error); //TODO
			allegro_message ("Could not initialize sound. Sound is turned off.");
		}
		else
		{
			bool success = al_reserve_samples(16);
			if (!success)
			{
				allegro_message ("Could not reserve samples");
			}
		}
		initSound();
	}

*/
	
	string appname;
	this(string appname = "anonymous_twist_app") {
		this.appname = appname;
	}

	void init()
	{
		al_set_app_name(toStringz(appname));
		al_set_org_name(toStringz("helixsoft.nl"));

		localAppData = al_get_standard_path(ALLEGRO_USER_SETTINGS_PATH);

		bool result = al_make_directory(al_path_cstr(localAppData, ALLEGRO_NATIVE_PATH_SEP));
		if (!result) {
			writeln("WARNING: Failed to create application data directory ", al_get_errno());
		}

		configPath = al_clone_path(localAppData);
		al_set_path_filename(configPath, toStringz("twist.ini"));

		config = al_load_config_file (al_path_cstr(configPath, ALLEGRO_NATIVE_PATH_SEP));

		if (config == null) {
			config = al_create_config();
		}

		// getFromConfig(config);
		// getFromArgs (argc, argv);

		// parseOpts(options);

		enforce (al_install_keyboard(), "install keyboard failed");
		enforce (al_install_mouse(), "install mouse failed");
		enforce (al_init_image_addon(), "init image addon failed");
		enforce (al_init_acodec_addon(), "Could not initialze acoded addon");
		al_init_font_addon(); // never fails, no return value
		enforce (al_init_ttf_addon(), "Could not initialze ttf addon");
		enforce (al_init_primitives_addon(), "Could not initialize primitives addon");
		
		audio = new AudioManager();
		audio.initSound();
		audio.getSoundFromConfig(config);

		//TODO: make configurable
		al_set_new_display_flags(ALLEGRO_WINDOWED | ALLEGRO_RESIZABLE);
		display = al_create_display(1280, 720);
		queue = al_create_event_queue();

		al_register_event_source(queue, al_get_display_event_source(display));
		al_register_event_source(queue, al_get_keyboard_event_source());
		al_register_event_source(queue, al_get_mouse_event_source());
		
		al_show_mouse_cursor(display);
		
  		timer = al_create_timer(0.1);
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

		// link up modifier styles to type styles...
		foreach (k, v; styleBySelector) {
			string[] parts = k.split('[');
			if (parts.length > 1 && parts[0] in styleBySelector) {
				v.parent = styleBySelector[parts[0]];
			}
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

	Style getStyle(string selector, string modifier) {
		string modifiedSelector = format("%s[%s]", selector, modifier); 
		if (modifiedSelector in styleBySelector) {
			return styleBySelector[modifiedSelector];
		}
		else return getStyle(selector);
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

	
		// cleanup
		if (configPath != null)
		{
			al_save_config_file(al_path_cstr(configPath, ALLEGRO_NATIVE_PATH_SEP), config);
		}

		// stop sound - important that this is done before the ALLEGRO_AUDIO_STREAM resources are destroyed
		audio.doneSound();

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

	void calculateLayout(Component c = null) {

		void calculateRecursive(Component comp, Rectangle parentRect, int depth = 0) {
			comp.shape = comp.layoutData.calculate(parentRect);
			// writeln(" ".rep(depth), comp.classinfo, " ", comp.shape, " from ", comp.layoutData);
			foreach(child; comp.children) {
				calculateRecursive(child, comp.shape, depth + 1);
			}
		}

		if (c is null) {
			Rectangle displayRect = Rectangle(0, 0, display.al_get_display_width, display.al_get_display_height);
			calculateRecursive (rootComponent, displayRect);
		}
		else {
			foreach(child; c.children) {
				calculateRecursive(child, c.shape, 0);
			}
		}
	}

	private void done()
	{
		audio.doneSound();
		if (queue) al_destroy_event_queue(queue); queue = null;
		if (timer) al_destroy_timer(timer); timer = null;
		if (display) al_destroy_display(display); display = null;
	}

	~this() {
		// invoke engine destructor, destroy remaining components
		destroy(rootComponent); rootComponent = null;
		destroy(resources); resources = null;
		
		if (localAppData)
			al_destroy_path(localAppData);

		if (configPath)
			al_destroy_path(configPath);

		if (config) al_destroy_config(config);
		
		destroy(audio); audio = null;
		al_uninstall_system();
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

		override void draw(GraphicsContext gc) {
			foreach (child; children) {
				child.draw(gc);
			}
		}

		void removeLastChild() {
			children = children[0..$-1];
		}
	}
	
}
