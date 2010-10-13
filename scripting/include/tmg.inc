#if defined _tmg_included_
	#endinput
#endif
#define _tmg_included_


enum TMGTarget {
	TMG_ALL = 0,
	TMG_PLAYING,
	TMG_NOTPLAYING
}

functag tMiniGamesActionCB Action:public(String:instructions[], size, any:opt);
functag tMiniGamesStopActionCB Action:public();

native TMG_RegisterMiniAction(Float:requiredTime, tMiniGamesActionCB:func, tMiniGamesStopActionCB:stopfunc, any:opt);
native bool:TMG_IsEnabled();
native bool:TMG_IsPlaying(client);
native TMG_SetSuccess(client, bool:success);