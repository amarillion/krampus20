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
import helix.util.math;
import helix.audio;
import helix.allegro.config;

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

	StyleManager styles;

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

	/** use config, monitor size and defaults */
	private Rectangle determineWindowPosition(int defaultW, int defaultH) {
		Rectangle result;

		// obtain monitor size
		ALLEGRO_MONITOR_INFO info;
		al_get_monitor_info(0, &info);
		const monitorW = info.x2 - info.x1;
		const monitorH = info.y2 - info.y1;
		
		//NOTE: int.max means: automatic positioning
		//Trying to persist x,y was too buggy, see: https://www.allegro.cc/forums/thread/618393
		result.x = int.max;
		result.y = int.max;

		// leave some room around window for window border, start bar etc.
		result.w = bound(256, monitorW - 128, get_config!int(config, "window", "width", defaultW));
		result.h = bound(128, monitorH - 128, get_config!int(config, "window", "height", defaultH));
		
		return result;
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

		// getFromArgs (argc, argv);

		// parseOpts(options);

		enforce (al_install_keyboard(), "install keyboard failed");
		enforce (al_install_mouse(), "install mouse failed");
		enforce (al_init_image_addon(), "Could not initialize image addon");
		enforce (al_init_acodec_addon(), "Could not initialze acoded addon");
		enforce (al_init_font_addon(), "Could not intialize font addon");
		enforce (al_init_ttf_addon(), "Could not initialze ttf addon");
		enforce (al_init_primitives_addon(), "Could not initialize primitives addon");
		
		audio = new AudioManager();
		audio.initSound();
		audio.getSoundFromConfig(config);

		const DEFAULT_WINDOW_WIDTH = 1200;
		const DEFAULT_WINDOW_HEIGHT = 675;

		Rectangle windowPos = determineWindowPosition(DEFAULT_WINDOW_WIDTH, DEFAULT_WINDOW_HEIGHT);
		al_set_new_display_flags(ALLEGRO_WINDOWED | ALLEGRO_RESIZABLE);
		al_set_new_window_position(windowPos.x, windowPos.y);
		display = al_create_display(windowPos.w, windowPos.h);
		queue = al_create_event_queue();

		al_register_event_source(queue, al_get_display_event_source(display));
		al_register_event_source(queue, al_get_keyboard_event_source());
		al_register_event_source(queue, al_get_mouse_event_source());
		
		al_show_mouse_cursor(display);
		
  		timer = al_create_timer(0.1);
		al_register_event_source(queue, al_get_timer_event_source(timer));
		al_start_timer(timer);

		resources = new ResourceManager();
		styles = new StyleManager(resources);
		rootComponent = new RootComponent(this);
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
					case ALLEGRO_EVENT_DISPLAY_RESIZE: {
						al_acknowledge_resize(event.display.source);
						calculateLayout();
						break;
					}
					case ALLEGRO_EVENT_DISPLAY_CLOSE: {
						// TODO: ask for close...
						exit = true;
						break;
					}
					case ALLEGRO_EVENT_KEY_CHAR: {
						if (focusComponent) {
							focusComponent.onKey(event.keyboard.keycode, event.keyboard.unichar, event.keyboard.modifiers);
						}
						// TODO: bubble up?
						// TODO: global keyboard accelerators?
						switch(event.keyboard.keycode)
						{
							case ALLEGRO_KEY_TAB: {
								advanceFocus();
								break;
							}
							case ALLEGRO_KEY_ESCAPE: {
								// TODO: ask for close...
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
			set_config!int(config, "window", "width", display.al_get_display_width);
			set_config!int(config, "window", "height", display.al_get_display_height);
			al_save_config_file(al_path_cstr(configPath, ALLEGRO_NATIVE_PATH_SEP), config);
		}

		// stop sound - important that this is done before the ALLEGRO_AUDIO_STREAM resources are destroyed
		audio.doneSound();

		done();
	}

	private Component[] entered = [];
	private bool capture = false;

	Component findComponentAt(in Point cursor) {
		
		Component comp = rootComponent;
		bool goDeeper = true;
		while (goDeeper) {
			bool match = false;
			foreach (child; retro(comp.children)) {
				if (child.killed || child.hidden) continue;

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
		return comp;
	}

	private void advanceFocus() {
		writeln("Advancing focus not yet implemented");
	}

	Component capturedComponent;
	Component focusComponent;

	void dispatchMouseEvent(ALLEGRO_EVENT event) {
		
		Point cursor = Point(event.mouse.x, event.mouse.y);
		Component targetComponent;
		
		if (capturedComponent) {
			targetComponent = capturedComponent;
		}
		else {
			targetComponent = findComponentAt(cursor);
			
			// update stack of entered components, and send leave events as appropriate.
			while (!entered.empty) {
				if (entered[$-1] == targetComponent) {
					break;
				}
				else {
					auto left = entered[$-1];
					entered.popBack();
					left.onMouseLeave();
				}
			}

			// send enter events as appropriate
			if (entered.empty || entered[$-1] != targetComponent) {
				targetComponent.onMouseEnter();
				entered ~= targetComponent;
			}
		}

		switch (event.type) {
			case ALLEGRO_EVENT_MOUSE_BUTTON_DOWN:
			{
				// offer focus to target component when clicking
				if (!targetComponent.focused && targetComponent.canFocus) {
					focus(targetComponent);
				}
				targetComponent.onMouseDown(cursor);
				break;
			}
			case ALLEGRO_EVENT_MOUSE_BUTTON_UP:
			{
				targetComponent.onMouseUp(cursor);
				if (capturedComponent !is null) {
					capturedComponent = null; // capture always ends on button release
				}
				break;
			}
			case ALLEGRO_EVENT_MOUSE_AXES:
			{
				targetComponent.onMouseMove(cursor);
				break;
			}
			default: assert(false);
		}
	}

	void focus(Component c) {
		if (focusComponent !is null) {
			focusComponent.focused = false;
			focusComponent.loseFocus();
		}
		focusComponent = c;
		if (focusComponent !is null) {
			focusComponent.focused = true;
			focusComponent.gainFocus(); 
		}
	}

	void calculateLayout(Component c = null) {

		void calculateRecursive(Component comp, Rectangle parentRect, int depth = 0) {
			comp.applyLayout(parentRect);
			// writeln(" ".rep(depth), comp.type, " ", comp.classinfo, " ", comp.shape, " from ", comp.layoutData);
			foreach(child; comp.children) {
				calculateRecursive(child, comp.shape, depth + 1);
			}
		}

		if (c is null) {
			Rectangle displayRect = Rectangle(0, 0, display.al_get_display_width, display.al_get_display_height);
			calculateRecursive(rootComponent, displayRect);
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

		al_destroy_display(display);
		
		al_shutdown_ttf_addon();
		al_shutdown_font_addon();
		al_shutdown_image_addon();
		al_shutdown_primitives_addon();

		al_uninstall_system();
	}

	void captureMouse(Component c, Point p) {
		capturedComponent = c;
	}

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
			super(window, "body");
		}

		override void draw(GraphicsContext gc) {
			drawBackground(getStyle());
			foreach (child; children) {
				child.draw(gc);
			}
		}

		void removeLastChild() {
			children = children[0..$-1];
		}
	}
	
}
