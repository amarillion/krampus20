module dialog;

import std.stdio;
import helix.mainloop;
import helix.widgets;
import engine;
import helix.component;

class Dialog : State {

	this(MainLoop window, Component slotted = null) {
		super(window);
		
		buildDialog(window.resources.getJSON("dialog-layout"));

		if (slotted) {
			getElementById("div_slot").addChild(slotted);
		}

		getElementById("btn_ok").onAction.add({ 
			window.popScene(); 
		});
	}

}

void openDialog(MainLoop window, string msg) {
	PreformattedText slotted = new PreformattedText(window);
	slotted.text = msg;
	slotted.setStyle(window.getStyle("pre"));
	Dialog dlg = new Dialog(window, slotted);
	window.pushScene(dlg);
}