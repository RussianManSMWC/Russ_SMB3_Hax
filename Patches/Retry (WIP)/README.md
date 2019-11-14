This patch adds retry prompt that triggers when player dies. It presents two options: RETRY (resets level) and END (exit level like normal)

Contents included:
* IPS patch
* Source code (duh)
* this nasty readme that shouldn't have existed. ever. evil.

CHANGES:
* chr050 - additional letters and cursor
* chr085 - recolored number tiles (since UP specifically for XUP is overwritten)
* prg000 - disabled death song
* prg002 - remapped UP part from XUP (after matching three cards)
* prg008 - removes timer set after player falls in the pit/time-up/got crushed, so it's the same as regular death
* prg029 - bank where retry system is located, overwrites original death code
* prg030 - adds checks for retry

NOTES:
* This patch is currently unstable and has some bad glitches. Use at your own risk! For education purposes. Feel free to help me fixing it.
* Search for !RETRY for changes patch provides in included banks

BUGS:
* When choosing RETRY completing/ending current level sometimes marks previous completed level as incomplete (i suspect it's related with previous player's position on OW (that player's supposed to skid to) but it seems inconsistent
* Bro fights and koopa kid airships don't initialize propertly after choosing RETRY (airship doesn't appear on OW until player exits another level (?))

Special thanks:
worldpeace of Super Mario World Central - retry system for Super Mario World that inspired me to create this for SMB3.

Fun fact: This is THE first SMB3 hack i've made ever. Quite ambitious, eh?
