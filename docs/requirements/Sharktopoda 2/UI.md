# UI

## Overview  

## Start up

When started, Sharktopoda should show a default window like:

![Default](assets/Default.png)

This window should be closed when any video window is open. When all video windows are closed this window should be displayed. This is the same behavior as the [IINA video player](https://iina.io/).

Both `Open ...` and `Open URL ...` are buttons. When clicked, or the corresponding key strokes occur they should trigger their open action.

`Open ...` brings up a standard file browser.

`Open URL ...` should bring up a dialog that allows a user to enter a movie URL. This is the same behavior as `Open Location` in Apple's QuickTime player.

## Preferences

Sharktopoda will have a standard _Preferences_ menu item:

![Preferences](assets/Prefs.png)

When preferences is opened it will display a window with the tabs/sections shown below. Changes to preferences should be saved when editable field loses focus or the window is closed.

### Annotations

![Annotation Preferences](assets/Prefs_Annotations.png)

This section specifies how localizations (i.e. annotations) are drawn and represented over video. Most should be obvious but here are additional details on the non-obvious ones:

- __Show annotations check box__: When checked localizations are displayed over top of the video. When unchecked, no localizations are displayed/drawn.
- __Annotation Display > Time Window__: This defines how long a localization should be displayed. The time to display the localization is from `annotation.elapsedTimeMillis - timeWindow / 2.0` to `annotation.elapsedTimeMillis + timeWindow / 2.0`. (e.g. if `elapsedTimeMillis = 1000` and `timeWindow = 30`, the localization for the annotation should be drawn when the video is showing frames between 985 and 1015 milliseconds from the start of the video.




#### Annotation Creation

When a new annotation is created this section determines properties of the bounding box as it is being drawn.

#### Annotation Display

This section specifies the properties for an annotation _after_ it has been drawn on the video. By default an annotation is drawn using a the _Default color_ but each annotation may have it's own unique color assigned. Alternatively, all annotations can have a color assigned, when an annotation is created it get's assigned the default color.

#### Annotation Selection

This specifies the display of _selected_ annotations. Annotations can be selected, either by receivving a command via UPD or by clicking on the localization on top of the video.

![Network Preferences](assets/Prefs_Network.png)
