#OpenHLDS

##Summary

An open-source dedicated server for Half-Life 1 and mods, including Counter-Strike.
Compatible with 47p, 48p and legit Steam clients. Existing server-side addons are expected to work too.
Started as a reversal of some memory-related structs in original HLDS by Valve, for 4 months of development this project has elevated to a working and playable server.


##Deployment

Grab the compiled binaries from ./bin or compile the server by yourself.
Any ObjectPascal-aware compiler should do the job just fine. The code is designed to compile using either Delphi (since version 6) or FPC (since 2.x).

The compiled binary (hlds.exe) runs like a regular HLDS server.
Example: hlds -game cstrike -port 27017 -maxplayers 11


##Status
The code is 64-bit aware, but this capability wasn't tested due to absence of 64-bit game libraries.
Linux binaries are absent as for now.

Some features are either unavaliable or not yet developed.
This includes:
 - kick/ban functionality
 - IP filters
 - remote console
 - varargs parser: the varargs functions will only parse the first argument (called a format string, or "fmt"). This format string will be sent to the engine as it is. The parser is not a big issue, just need some time to think of an efficient and simple parsing algorithm.
 - user interface (currently it's just a non-blocking stdin/stdout wrapper).
 - file search (FindFirst, FindNext): "maps *" command doesn't work.


##Known bugs
(This list contains bugs that are known about, but not yet fixed).
- mapcycle (varargs parser required)
- entity list discrepancy with triggers and moveents: this causes stuttering movement while on ladders and in water. Haven't tracked it yet.
- crashing @ g_pSoundent->*
           @ gamedll OnFrame handler
- mp_autokick ("kick" command required)
- a single crash on roundend while using the latest Counter-Strike gamedll, cause is unknown


##License
No license as for now.

Third party components include:
 - BZip2 library, BSD
 - Libc header unit from Kylix, GPL version 2
 - Some low-level assembly routines from FastCode project


##Contact info & credits
No credits as for now.
