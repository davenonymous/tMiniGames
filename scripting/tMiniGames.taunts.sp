#pragma semicolon 1
#include <sourcemod>
#include <tmg>
#include <tf2_stocks>

#define VERSION 		"0.0.1"


new Handle:g_hCvarEnabled = INVALID_HANDLE;
new bool:g_bEnabled;

new TFClassType:g_xNextTaunt;

public Plugin:myinfo =
{
	name 		= "tMiniGames - Taunts",
	author 		= "Thrawn",
	description = "",
	version 	= VERSION,
};

public OnPluginStart() {
		CreateConVar("sm_tmg_taunts_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

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
		TMG_RegisterMiniAction(6.0, TauntAs, StopTauntAs, TFClass_Pyro);					//Taunt as Pyro
		TMG_RegisterMiniAction(6.0, TauntAs, StopTauntAs, TFClass_Scout);				//Taunt as Scout
		TMG_RegisterMiniAction(6.0, TauntAs, StopTauntAs, TFClass_Soldier);					//Taunt as Pyro
		TMG_RegisterMiniAction(6.0, TauntAs, StopTauntAs, TFClass_DemoMan);				//Taunt as Scout
		TMG_RegisterMiniAction(6.0, TauntAs, StopTauntAs, TFClass_Heavy);					//Taunt as Pyro
		TMG_RegisterMiniAction(6.0, TauntAs, StopTauntAs, TFClass_Engineer);				//Taunt as Scout
		TMG_RegisterMiniAction(6.0, TauntAs, StopTauntAs, TFClass_Medic);					//Taunt as Pyro
		TMG_RegisterMiniAction(6.0, TauntAs, StopTauntAs, TFClass_Sniper);				//Taunt as Scout
		TMG_RegisterMiniAction(6.0, TauntAs, StopTauntAs, TFClass_Spy);					//Taunt as Pyro
	}
}

public Action:TauntAs(String:sTitle[], size, any:iOpt) {
	if(iOpt == TFClass_Pyro) {
		Format(sTitle, size, "Taunt as Pyro!");
	}

	if(iOpt == TFClass_Scout) {
		Format(sTitle, size, "Taunt as Scout!");
	}

	if(iOpt == TFClass_Soldier) {
		Format(sTitle, size, "Taunt as Soldier!");
	}

	if(iOpt == TFClass_DemoMan) {
		Format(sTitle, size, "Taunt as Demoman!");
	}

	if(iOpt == TFClass_Heavy) {
		Format(sTitle, size, "Taunt as Heavy!");
	}

	if(iOpt == TFClass_Engineer) {
		Format(sTitle, size, "Taunt as Engineer!");
	}

	if(iOpt == TFClass_Medic) {
		Format(sTitle, size, "Taunt as Medic!");
	}

	if(iOpt == TFClass_Sniper) {
		Format(sTitle, size, "Taunt as Sniper!");
	}

	if(iOpt == TFClass_Spy) {
		Format(sTitle, size, "Taunt as Spy!");
	}

	g_xNextTaunt = iOpt;
	AddCommandListener(OnTaunt, "taunt");
}

public Action:OnTaunt(client, const String:command[], argc) {
	if(TMG_IsPlaying(client)) {
		if(TF2_GetPlayerClass(client) == g_xNextTaunt) {
			TMG_SetSuccess(client, true);
		}
	}
}

public Action:StopTauntAs() {
	RemoveCommandListener(OnTaunt, "taunt");
}