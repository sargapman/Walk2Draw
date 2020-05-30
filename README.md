# Walk2Draw

An example app to track & display real time device movement on a map.

Based on Chapter 2. Drawing on Maps, of Build Location-Based Projects for iOS, by Dominik Hauser.

This makes use of the LogStore package from  https://github.com/sargapman/LogStore

### Usage: 
When launched the app will ask for permission to access the device location while the app is running.

Tap the Start button (bottom of the display) to begin tracking the device location and see the path drawn on the map.  Tap the Stop button to end location tracking.
Repeat to get multiple segments for a journey.

Tap the Share button to share the current map.

Tap the Clear button to clear the tracked locations.

### Chapter 2 Exercises
1. Add error handling to the code. For example you could present an alert to the users in case they don’t authorize the use of the device location.
2. Change the code so the user can "lift" the "pencil" and continue the drawing at another place.
2.1. Add start and stop markers on each segment.
