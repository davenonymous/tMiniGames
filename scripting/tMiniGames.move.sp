#pragma semicolon 1
#include <sourcemod>
#include <tmg>
#include <sdkhooks>

#define VERSION 		"0.0.1"


new Handle:g_hCvarEnabled = INVALID_HANDLE;
new bool:g_bEnabled;

new g_bShouldMove;
new bool:g_bFailed[MAXPLAYERS+1];

new Float:g_fMoveTime = 6.0;

public Plugin:myinfo =
{
	name 		= "tMiniGames - Move",
	author 		= "Thrawn",
	description = "",
	version 	= VERSION,
};

public OnPluginStart() {
		CreateConVar("sm_tmg_move_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

		g_hCvarEnabled = CreateConVar("sm_tmg_taunts_enable", "1", "Enable tMG Taunts", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		HookConVarChange(g_hCvarEnabled, Cvar_ChangedEnable);
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
}

public Cvar_ChangedEnable(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
}


public OnAllPluginsLoaded() {
	if(LibraryExists("tmg")) {
		TMG_RegisterMiniAction(g_fMoveTime, ForceMove, StopForceMove, true);					//Dont stop moving
		TMG_RegisterMiniAction(g_fMoveTime, ForceMove, StopForceMove, false);					//Dont move!
	}
}

public Action:ForceMove(String:sTitle[], size, any:bShouldMove) {
	if(bShouldMove) {
		Format(sTitle, size, "Dont stop moving!");
	} else {
		Format(sTitle, size, "Dont move!");
	}

	g_bShouldMove = bShouldMove;

	CreateTimer(0.5, HookPlayers);
	CreateTimer(g_fMoveTime - 0.5, UnhookPlayers);
}

public Action:HookPlayers(Handle:timer, any:data) {
	for(new client = 1; client <= MaxClients; client++) {
		if(IsClientInGame(client) && TMG_IsPlaying(client)) {
			g_bFailed[client] = false;
			SDKHook(client, SDKHook_PreThink, OnPreThink);
		}
	}
}

public Action:UnhookPlayers(Handle:timer, any:data) {
	for(new client = 1; client <= MaxClients; client++) {
		if(IsClientInGame(client) && TMG_IsPlaying(client)) {
			SDKUnhook(client, SDKHook_PreThink, OnPreThink);

			if(!g_bFailed[client]) {
				TMG_SetSuccess(client, true);
			}
		}
	}
}

public OnPreThink(client) {
    new iButtons = GetClientButtons(client);
    new bool:bIsMoving = false;
    if(iButtons & IN_FORWARD || iButtons & IN_BACK || iButtons & IN_MOVELEFT || iButtons & IN_MOVERIGHT) {
    	bIsMoving = true;
    }

    if((g_bShouldMove && !bIsMoving) || (!g_bShouldMove && bIsMoving)) {
    	g_bFailed[client] = true;
    }
}

public Action:StopForceMove() {
}