# Classic EPGP <LORE>

Merger of CEPGP, CEPGP-TBC, and CEPGP_DistributionFromBags, many thanks to Alumium, Tragalix , Apollo@Taiwan for their hard work on these addons!


These addons are no longer being maintained for TBC-Classic, but their original links are below:

https://www.curseforge.com/wow/addons/tbc-classic-epgp-distributionfrombags

https://www.curseforge.com/wow/addons/cepgp

https://www.curseforge.com/wow/addons/cepgp-tbc


The addon continues to be modified and updated as Classic progresses.

Original README text:

An addon designed to handle your guild's EPGP standings by storing the respective values in your Officer Notes. Another primary function of the addon is to handle loot moderation which you must be the master looter to utilise.

For this addon to work, anyone using the addon must be able to at the very least view Officer Notes. To adjust EP and GP values you must be able to edit Officer Notes.

The addon is entirely GUI based and the frame is designed to only appear automatically on raid bosses.

## Functionality

|	Command					|	Action														|
|---------------------------|---------------------------------------------------------------|
|	/cep show				|	Shows the main CEPGP window									|
|	/cep version			|	Queries all guild and raid members for their addon version	|
|	/cep config				|	Opens the CEPGP options window								|
|	/cep traffic			|	Opens the CEPGP traffic window								|
|	/cep changelog			|	Shows the latest CEPGP changelog							|

**Note: cepgp is a context sensitive addon and elements will be visible when they are relevent**

Any function that involves modifying EPGP standings requires you to be able to edit officer notes to have it available to you.

The following commands can be used to get EPGP reports.

**The player you whisper must be able to at least view officer notes**

| Command                    | Result                                                                        |
|----------------------------|-------------------------------------------------------------------------------|
| ```/w player !info```      | Gets your current EPGP standings                                              |
| ```/w player !infoguild``` | Gets your current EPGP standings and PR rank within your guild                |
| ```/w player !inforaid```  | Gets your current EPGP standings and PR rank within the raid                  |
| ```/w player !infoclass``` | Gets your current EPGP standings and PR rank among your class within the raid |

## Definitions

| Label              | Definition                                                                                                   |
|--------------------|--------------------------------------------------------------------------------------------------------------|
| EP                 | Effort points. Points gained from what ever criteria.                                                        |
| GP                 | Gear points. Points gained from being awarded gear.                                                          |
| PR                 | Priority. Calculated by EP / GP.                                                                             |
| Decay              | Reduces the EP and GP of every guild member by a given percent.                                              |
| Initial/Minimum GP | The GP that all new guild members start at. This is also the minimum amount of GP any guild member can have. |
| Standby EP         | EP awarded to guild members that are not in the raid.                                                        |
| Standby EP Percent | The percent of standard EP allocation should awarded to standby members.                                     |


# CEPGP Distribution From Bags

CEPGP DistributionFromBags is a plugin of CEPGP addon.\
The Loot Master can start loot distribution process from the inventory.\
This would allow the Loot Master to grab all items on all bosses, and make distribution at the end of the raid.\
When the "bid" part is finished, the Loot Master need to give items manually.

# How to use

1. Type /dfb to show up the window
2. When the window is on screen, Shift+Click an item in inventory to start the distribution process.
3. Click on the winner
4. Manually trade with the winner (put the equipment in the first slot of the trading window)
5. Choose the reason and record the GP points