# READ:
2838 was kind enough to overhaul the L4D2 autosplitter to use sigscanning instead of hard coded offsets for each version. From now on, there should never be any reason to come to this repo anymore, and latest release on this repo is outdated as a result. I implore you to just activate the autosplitter via edit splits, or you can download it from [here](https://raw.githubusercontent.com/SirWillian/Autosplitters/master/L4D2/L4D2.asl).

## Now, for the original readme:

This is an updated/extended version of bill_play3's autosplitter for Left 4 Dead 2. (Additionally, this is where the autosplitter for L4D: Survivors lives 👀)

Whenever I push an update here, it should be available within a few days directly in LiveSplit, through the Edit Splits screen (for the L4D2 autosplitter, that is. Any changes to the L4D: Survivors autosplitter should be reflected instantly in Livesplit).

## Fixes/Additions
1. Support for The Last Stand update (and continued support for the forseeable future)
2. Support for an extra old version so people are more inclined to try out the original Cold Stream Beta 😎
3. A fix for the autosplitter double splitting on certain finales (primarily the Parish)
4. Some extra QoL fixes (such as the ability to split on the Cold Stream finale while playing RocketDude)
5. Automatically forcing splits to Game Time on run start (with an option to disable this in the settings)

## How to use this if the latest version isn't integrated in LiveSplit yet
Download the latest version from Releases on the right, then:

1. Right click, hit edit splits
2. Disable the integrated autosplitter if you have it active, and click OK
3. Right click, hit edit layout
4. Click on the giant plus and go to Control > Scriptable Auto Splitter
5. Double click on the newly added Scriptable Auto Splitter component
6. Click "Browse" and select the downloaded ASL file
7. If done correctly, the autosplitter's settings will show and everything should function
