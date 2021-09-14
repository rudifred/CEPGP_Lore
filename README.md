# Classic EPGP
**Do not redistribute this addon. Post a link to this github page instead**

CEPGP Support Discord: https://discord.gg/7mG4GAr

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

## Installation

1. Download this addon 
2. Extract it to ../Interface/AddOns/ 
3. Rename the extracted folder from cepgp-retail-master to cepgp

Author: Alumian
