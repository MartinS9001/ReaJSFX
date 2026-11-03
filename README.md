# ReaJSFX
Marcin's audio effects written in JSFX for Reaper DAW.

# Installation
There are 2 ways of installing the plugins - using ReaPack repository or by downloading the files and copying them to Reaper effects folder manualy.

# Installation using ReaPack
If you have ReaPack installed (https://reapack.com/), under "Extensions" menu go to ReaPack -> Import repositories.


![reapack1](https://user-images.githubusercontent.com/12054038/59975228-0ad79d80-95b6-11e9-971d-da0d4c29bda8.png)



In the window you will need to provide link to my github repo: https://github.com/MartinS9001/ReaJSFX/raw/master/index.xml



![reapack2](https://user-images.githubusercontent.com/12054038/59975243-60ac4580-95b6-11e9-991d-58b6418239fb.png)



# Manual installation
To install plugins you need to go to your Reaper resource path. The easiest way to do it is using options menu in Reaper and choosing "Show Reaper resource path in explorer/finder":

![readme1](https://user-images.githubusercontent.com/12054038/59020078-8bbe3780-8849-11e9-8417-504d0dce0d9f.png)

In the Reaper resource folder go to effects and copy downloaded effects into the effects folder.

![readme2](https://user-images.githubusercontent.com/12054038/59020331-0e46f700-884a-11e9-8d34-7d2fdf4e98a3.png)

# Onset Round-Robin Sampler

`OnsetRRSampler/OnsetRRSampler.jsfx` is a MIDI sampler that cuts a recording into one-shots for you and cycles through them as round robins.

* **Load from the Media Explorer:** drag one or more files from the Media Explorer (or from Explorer/Finder) onto the plugin window. Hold **Shift** while dropping, or turn on *Append on drop*, to add files to the ones already loaded.
* **Automatic onset detection:** a long file with many hits (e.g. 20 footstep variations) is split into separate slices. Adjust *Onset sensitivity*, *Gate threshold*, *Min. time between hits*, *Pre-roll* and *Trim silent tails* until the markers fit. The analysis runs again when you change any of these.
* **Round robin:** every incoming note plays the next slice. Modes: *Sequential*, *Random*, *Random (no repeat)* (a shuffle that never plays the same hit twice in a row) and *Key-mapped* (lowest note = slice 1, the next note = slice 2, …).
* **Envelope and rate:** *Attack* sets the fade-in at the start of each hit (0 ms = instant). *Playback rate* transposes all hits by ±24 semitones, including notes that are already playing, and MIDI pitch bend bends the rate within *Pitch bend range*.
* **Humanising:** random pitch (cents), random gain (dB), velocity sensitivity, optional pitch tracking around a root note.
* **Playback:** one-shot or release on note-off, polyphony limit with voice stealing, MIDI channel filter and note range.
* **Editing on the waveform:** click to audition a slice, Shift+click to add a split, Alt+click to remove the nearest split, right-click to delete a slice.
* The loaded file paths and the slices, including your manual edits, are saved with the project. The audio is read from disk again when the project opens, so keep the files where they are.

### Media Explorer actions

`OnsetRR - Load Media Explorer selection.lua` and `OnsetRR - Append Media Explorer selection.lua` send the files selected in the Media Explorer to the sampler on the selected track. If the track has no sampler, one is inserted. ReaPack registers both actions in the *Main* and *Media Explorer* sections, so you can give them a shortcut that works while you browse sounds.

* Reading the Media Explorer selection requires the **js_ReaScriptAPI** extension (available through ReaPack). Without it, the scripts use the selected media items' source files, or show a file dialog.
* Supported formats are whatever JSFX `file_open` can decode in your REAPER version. WAV and OGG always work, and recent versions also read FLAC and MP3.
* Memory limit: about 6 minutes of 44.1 kHz audio across all loaded files, and up to 1024 slices.
* Loading and analysing a file happens on the audio thread, so a very long file can cause a short dropout while it loads.
