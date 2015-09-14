#OpenHLDS

##Summary

An open-source dedicated server for Half-Life 1 and mods, including Counter-Strike.
Compatible with 47p, 48p and legit Steam clients. Third-party server-side addons, like Metamod, are expected to work too.
Started as a reversal of some memory-related structs in original HLDS binary by Valve, this project has now elevated to a working and playable server.


##Deployment

Grab the compiled binaries from ./bin or compile the server by yourself.
Any ObjectPascal-aware compiler should do the job just fine. The code is designed to compile using either Delphi (since version 6) or FPC (since 2.x).

The compiled binary (hlds.exe) runs like a regular HLDS server.
Example: hlds -game cstrike -port 27017 -maxplayers 11

Recently, an optional FakeSWDS addon was added. If you are planning to use Metamod game libraries or plugins, this addon is kinda necessary. Basically, it tricks Metamod so that it clearly identifies OpenHLDS as a latest Half-Life server build. This "emulated" behavior is necessary for some engine api functions to work, like GetPlayerAuthID and others.
Installation is simple - just put "fake" swds.dll next to the server executable. The interface will be automatically created and engine functions will be then redirected to swds.dll.


##Status
The project is abandoned as for now. People just don't want no open-sourced servers :c
However, the code is right here. Go ahead - do anything your dirty mind desires to do with it. Fake players, server exploits, hell, even the reversed game client - you name it, you do it.

The latest update broke linux compatibility though, so no cross-platform support here.

The code is 64-bit aware, but this capability wasn't tested due to absence of 64-bit game libraries.

Some features are either unavaliable or not yet developed.


##Known bugs
(This list contains bugs that are known about, but not yet fixed).
As for 14.09.15:
- Just look in HLDS.dpr, all my silly notes are there. No major bugs though. Even AMX Mod works fine.


If you manage to find a bug, you can make an issue report. Go to "[Issues](https://github.com/unnamed10/openhlds/issues/new)", press "New Issue" and enter the information about the bug: some background information, steps to reproduce, server console output. Every piece of information will be greatly appreciated. Or not. Nobody cares tbh.


##License
Who needs all this legal stuff anyway? I mean, we live in a world of stolen software and reversed hlds servers (me being so original). But here ya go.

This project is licensed under the terms of WTFPL v2. See http://www.wtfpl.net for more details.

Third party components include:
 - BZip2 library, BSD
 - Libc header unit from Kylix, GPL version 2
 - Some low-level assembly routines from FastCode project
 - FastMM memory manager, MPL


##Contact info
How about [no](http://www.youtube.com/watch?v=eSCcIv_dLlg).

 
##Credits
Cashin' it in.
But whateva.
I did the entire thing, and the Doctor just kinda sat there and looked very sad. "Doctor", I said, " - y u lookin' so helpless?" And then he stood up, gently pushed his white shining coat aside and replied to me in a moment of desperation: "Escape. NOW. The broken ass game will just suck you in EVEN MORE."
And so i did. Shoutouts to Doctor btw. People say he is still wandering the empty servers looking for vengeance. Or not. I don't even know.