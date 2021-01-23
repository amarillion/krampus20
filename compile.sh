#!/bin/bash

# -L/SUBSYSTEM:WINDOWS:4.0 prevents console window
dmd src/*.d src/helix/*.d src/helix/util/*.d src/allegro5/*.d src/helix/allegro/*.d -Isrc -L/SUBSYSTEM:WINDOWS:4.0
