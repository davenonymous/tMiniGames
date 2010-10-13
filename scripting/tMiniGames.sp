#pragma semicolon 1
#include <sourcemod>
#include <tsetuphelper>
#include <sdkhooks>
#include <colors>
#include <tmg>
#include <loghelper>

#define VERSION 		"0.0.1"
#define MAX_ACTIONS		64
#define TITLE_SIZE		127
#define TEAM_RED 2
#define TEAM_BLUE 3

enum MiniAction {
	Float:requiredTime,
	Handle:fwd,
	Handle:bwd,
	opt
}

new xMiniActions[MAX_ACTIONS][MiniAction];

new g_iShowScorerCount = 5;
new Float:g_fWelcomeMessageTime = 5.0;
new Float:g_fBlendTime = 0.5;
new Float:g_fSetupTime = 10.0;

new Float:g_fTimeFrame;
new Float:g_fTimeLeft;
new g_iCountDown;

new g_iMiniActionCount = 0;
new bool:g_bEnabled = true;
new bool:g_bIsPlaying[MAXPLAYERS+1];
new bool:g_bSuccess[MAXPLAYERS+1];
new g_iPoints[MAXPLAYERS+1];

new Float:g_fGameStartTime;
new Float:g_fCurrentRequiredTime;

new String:g_sCurrentGame[TITLE_SIZE];
new String:g_sScoreText[512];

new g_iWinner = 0;

new Handle:g_hHudLeft;
new Handle:g_hHudCenter;
new Handle:g_hHudRight;
new Handle:g_hHudCenterBelow;

public Plugin:myinfo =
{
	name 		= "tMiniGames",
	author 		= "Thrawn",
	description = "",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tminigames_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	HookEvent("player_changeclass", Event_RepositionPlayer);
	HookEvent("player_spawn",       Event_RepositionPlayer);

	g_hHudLeft = CreateHudSynchronizer();
	g_hHudCenter = CreateHudSynchronizer();
	g_hHudRight = CreateHudSynchronizer();
	g_hHudCenterBelow = CreateHudSynchronizer();
}

public OnMapStart() {
	for(new client=1; client <= MaxClients; client++) {
		g_bIsPlaying[client] = false;
		g_bSuccess[client] = false;
	}
}

public OnMapEnd() {
	g_iMiniActionCount = 0;
}

public TF2_OnSetupStart() {
	if(g_iMiniActionCount > 0 && g_bEnabled) {
		g_fTimeFrame = TF2_GetSetupTime() * 1.0;
		LogMessage("Timeframe is: %f", g_fTimeFrame);
		g_fTimeLeft = g_fTimeFrame - g_fSetupTime;

		g_fTimeLeft -= 0.3;
		g_iWinner = 0;
		CreateTimer(0.3, Delayed_StartInstructor, 0, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Event_RepositionPlayer(Handle:event, const String:name[], bool:dontBroadcast) {
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bIsPlaying[iClient]) {
		//TMG_LookAtInstructor(iClient);
		new Float:duration = g_fCurrentRequiredTime - (GetEngineTime() - g_fGameStartTime);

		//Update Game Name
		SetHudTextParams(0.4, 0.1, duration, 100, 200, 255, 150, 0, 0.0, 0.0, g_fBlendTime);
		ShowSyncHudText(iClient, g_hHudCenter, g_sCurrentGame);

		//Update Scores
		SetHudTextParams(0.8, 0.5, duration, 100, 200, 255, 150, 0, 0.0, 0.0, g_fBlendTime);
		ShowSyncHudText(iClient, g_hHudRight, g_sScoreText);
	}
}

public Action:Delayed_StartInstructor(Handle:Timer, any:data) {
	//TMG_ShowInstructor("We are playing Simon Says!\nTaunt if you're in!", g_fWelcomeMessageTime, true, TMG_ALL);
	for(new client=1; client <= MaxClients; client++) {
		g_bIsPlaying[client] = false;
		g_bSuccess[client] = false;
	}

	ShowCenter("We are playing Simon Says!\nTaunt if you're in!", g_fWelcomeMessageTime, TMG_ALL);
	AddCommandListener(OnTaunt, "taunt");

	g_fTimeLeft -= g_fBlendTime + g_fWelcomeMessageTime;
	ShowCountDown(g_fWelcomeMessageTime, true);
	CreateTimer(g_fWelcomeMessageTime, Decide_Players, 0, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(g_fWelcomeMessageTime + g_fBlendTime, Play_Game, 0, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:OnTaunt(client, const String:command[], argc) {
	if(!g_bIsPlaying[client]) {
		g_bIsPlaying[client] = true;
		g_iPoints[client] = 0;

		SetHudTextParams(0.1, 0.5, 1.5, 100, 200, 255, 150, 0, 0.0, 0.0, g_fBlendTime);
		ShowSyncHudText(client, g_hHudLeft, "You are in!");

		PrintToChat(client, "You've decided to enter the mini action!");
	}
}

public Action:Decide_Players(Handle:Timer, any:data) {
	RemoveCommandListener(OnTaunt, "taunt");
}

public ShowLeft(const String:sMsg[], Float:duration, TMGTarget:xTargets) {
	SetHudTextParams(0.1, 0.5, duration, 100, 200, 255, 150, 0, 0.0, 0.0, g_fBlendTime);

	for(new client=1; client <= MaxClients; client++) {
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_BLUE) {
			if(xTargets == TMG_ALL || (xTargets == TMG_PLAYING && g_bIsPlaying[client]) || (xTargets == TMG_NOTPLAYING && !g_bIsPlaying[client])) {
				ShowSyncHudText(client, g_hHudLeft, sMsg);
			}
		}
	}
}

public ShowCenter(const String:sMsg[], Float:duration, TMGTarget:xTargets) {
	SetHudTextParams(0.4, 0.1, duration, 100, 200, 255, 150, 0, 0.0, 0.0, g_fBlendTime);
	for(new client=1; client <= MaxClients; client++) {
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_BLUE) {
			if(xTargets == TMG_ALL || (xTargets == TMG_PLAYING && g_bIsPlaying[client]) || (xTargets == TMG_NOTPLAYING && !g_bIsPlaying[client])) {
				ShowSyncHudText(client, g_hHudCenter, sMsg);
			}
		}
	}
}

public ShowScores(Float:duration) {
	ShowRight(g_sScoreText, duration, TMG_PLAYING);
}

public ShowWinner() {
	new iScorers = 0;
	new xSortScores[MAXPLAYERS+1][2];

	for(new client=1; client <= MaxClients; client++) {
		if(g_bIsPlaying[client]) {
			xSortScores[iScorers][1] = g_iPoints[client];
			xSortScores[iScorers][0] = client;
			iScorers++;
		}
	}

	SortCustom2D(xSortScores, iScorers, SortScoreDesc);

	new iWinnerPoints = xSortScores[0][1];

	new String:sText[255];
	new iWinners = 0;
	for(new i = 0; i < iScorers; i++) {
		if(xSortScores[i][1] < iWinnerPoints)
			break;
		iWinners++;

		LogPlayerEvent(xSortScores[i][0], "triggered", "tmg_roundwin");
		Format(sText, sizeof(sText), "\n%N", xSortScores[i][0]);
	}

	if(iWinners > 0) {
		if(iWinners > 1) {
			Format(sText, sizeof(sText), "Winners are:%s", sText);
		} else {
			Format(sText, sizeof(sText), "Winner:%s", sText);
		}
	} else {
		Format(sText, sizeof(sText), "No winners!");
	}

	LogMessage(sText);

	SetHudTextParams(0.45, 0.15, 3.0, 100, 255, 0, 0, 0, 0.0, 0.0, g_fBlendTime);

	for(new client=1; client <= MaxClients; client++) {
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_BLUE) {
			if(g_bIsPlaying[client]) {
				ShowSyncHudText(client, g_hHudCenterBelow, sText);
			}
		}
	}
}

public ShowCountDown(Float:duration, bool:toAll) {
	g_iCountDown = RoundToFloor(duration);
	CreateTimer(1.0, Timer_CountDown, toAll);
}

public Action:Timer_CountDown(Handle:timer, any:toAll) {
	g_iCountDown -= 1;
	if(g_iCountDown > 0) {
		SetHudTextParams(0.5, 0.20, 0.8, 100, 255, 0, 0, 0, 0.0, 0.0, g_fBlendTime);

		for(new client=1; client <= MaxClients; client++) {
			if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_BLUE) {
				if(g_bIsPlaying[client] || toAll) {
					ShowSyncHudText(client, g_hHudCenterBelow, "%i", g_iCountDown);
				}
			}
		}

		CreateTimer(1.0, Timer_CountDown, toAll);
	}

}

public ShowRight(const String:sMsg[], Float:duration, TMGTarget:xTargets) {
	SetHudTextParams(0.8, 0.5, duration, 100, 200, 255, 150, 0, 0.0, 0.0, g_fBlendTime);
	for(new client=1; client <= MaxClients; client++) {
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_BLUE) {
			if(xTargets == TMG_ALL || (xTargets == TMG_PLAYING && g_bIsPlaying[client]) || (xTargets == TMG_NOTPLAYING && !g_bIsPlaying[client])) {
				ShowSyncHudText(client, g_hHudRight, sMsg);
			}
		}
	}
}

public Action:End_Game(Handle:Timer, any:iAction) {
	Call_StartForward(xMiniActions[iAction][fwd]);
	Call_Finish();

	new iWinners = 0;

	new iScorers = 0;
	new xSortScores[MAXPLAYERS+1][2];
	new String:sMsg[255];
	Format(sMsg, sizeof(sMsg), "");
	for(new client=1; client <= MaxClients; client++) {
		if(g_bIsPlaying[client]) {
			xSortScores[iScorers][1] = g_iPoints[client];
			xSortScores[iScorers][0] = client;
			iScorers++;

			if(g_bSuccess[client]) {
				Format(sMsg, sizeof(sMsg), "%s%N, ", sMsg, client);

				iWinners++;
			} else {
				SetHudTextParams(0.1, 0.5, 1.5, 255, 0, 0, 150, 0, 0.0, 0.0, g_fBlendTime);
				ShowSyncHudText(client, g_hHudLeft, "Fail!");
			}
		}
	}

	SortCustom2D(xSortScores, iScorers, SortScoreDesc);

	g_iWinner = xSortScores[0][0];

	Format(g_sScoreText, sizeof(g_sScoreText), "");
	new iShowScorerCount = iScorers > g_iShowScorerCount ? g_iShowScorerCount : iScorers;
	for(new i = 0; i < iShowScorerCount; i++) {
		Format(g_sScoreText, sizeof(g_sScoreText), "\n%N: %i", xSortScores[i][0], xSortScores[i][1]);
	}

	strcopy(sMsg, strlen(sMsg)-1, sMsg);

	for(new client=1; client <= MaxClients; client++) {
		if(g_bIsPlaying[client]) {
			if(iWinners > 0) {
				PrintHintText(client, "%s winners:\n%s", g_sCurrentGame, sMsg);
			} else {
				PrintHintText(client, "%s\nEverybody failed.", g_sCurrentGame);
			}
		}
	}
}

public SortScoreDesc(x[], y[], array[][], Handle:data) {
    if (x[1] > y[1])
        return -1;
    else if (x[1] < y[1])
        return 1;
    return 0;
}

public Action:Play_Game(Handle:Timer, any:data) {
	LogMessage("Timeleft for actions: %.2f", g_fTimeLeft);
	new iAction = FindMiniGame();
	//LogMessage("We are playing (%i) %s (%.2fs)", iAction, xMiniActions[iAction][title], xMiniActions[iAction][requiredTime]);

	if(iAction != -1) {
		new String:sDynamic[TITLE_SIZE] = "";

		for(new client=1; client <= MaxClients; client++) {
			g_bSuccess[client] = false;
		}

		Call_StartForward(xMiniActions[iAction][fwd]);
		Call_PushStringEx(sDynamic,TITLE_SIZE,SM_PARAM_STRING_COPY,SM_PARAM_COPYBACK);
		Call_PushCell(TITLE_SIZE);
		Call_PushCell(xMiniActions[iAction][opt]);
		Call_Finish();

		g_sCurrentGame = sDynamic;
		g_fCurrentRequiredTime = xMiniActions[iAction][requiredTime];
		g_fGameStartTime = GetEngineTime();

		//TMG_ShowInstructor(sDynamic, xMiniActions[iAction][requiredTime], false, TMG_PLAYING);
		ShowCenter(sDynamic, xMiniActions[iAction][requiredTime], TMG_PLAYING);
		ShowCountDown(xMiniActions[iAction][requiredTime], false);
		ShowScores(xMiniActions[iAction][requiredTime] + g_fBlendTime);

		g_fTimeLeft -= g_fBlendTime + xMiniActions[iAction][requiredTime];
		CreateTimer(xMiniActions[iAction][requiredTime], End_Game, iAction, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(xMiniActions[iAction][requiredTime] + g_fBlendTime, Play_Game, 0, TIMER_FLAG_NO_MAPCHANGE);
	} else {
		//TMG_ShowInstructor("Game Over", 2.0, false, TMG_PLAYING);
		if(g_iWinner > 0 && g_iWinner <= MaxClients) {
			ShowWinner();
		}

		ShowCenter("Game Over", 2.0, TMG_PLAYING);
	}
}

public FindMiniGame() {
	new xOptions[g_iMiniActionCount+1];
	new iPossibilities = 0;

	for(new i = 0; i < g_iMiniActionCount; i++) {
		if(xMiniActions[i][requiredTime] > g_fTimeLeft)
			continue;
		else {
			xOptions[iPossibilities] = i;
			iPossibilities++;
		}
	}

	if(iPossibilities > 0) {
		new i = GetRandomInt(0, iPossibilities);
		return xOptions[i];
	}

	return -1;
}

public TF2_OnSetupEnd() {
	for(new client=1; client <= MaxClients; client++) {
		g_bIsPlaying[client] = false;
	}

	//Charge Medics, refill ammo
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	RegPluginLibrary("tmg");

	//CreateNative("TMG_IsEnabled", Native_IsEnabled);
	CreateNative("TMG_RegisterMiniAction", Native_RegisterMiniAction);
	CreateNative("TMG_IsPlaying", Native_IsPlaying);
	CreateNative("TMG_SetSuccess", Native_SetSuccess);
}

public Native_IsPlaying(Handle:hPlugin, iNumParams) {
	new iClient = GetNativeCell(1);

	return g_bIsPlaying[iClient];
}

public Native_SetSuccess(Handle:hPlugin, iNumParams) {
	new iClient = GetNativeCell(1);
	new bool:bSuccess = GetNativeCell(2);

	if(!g_bSuccess[iClient] && bSuccess) {
		SetHudTextParams(0.1, 0.5, 2.0, 0, 255, 0, 150, 0, 0.0, 0.0, 0.0);
		ShowSyncHudText(iClient, g_hHudLeft, "WIN! WIN! WIN!");
		g_iPoints[iClient]++;
		LogPlayerEvent(iClient, "triggered", "tmg_miniwin");
	}

	g_bSuccess[iClient] = bSuccess;
}

public Native_RegisterMiniAction(Handle:hPlugin, iNumParams) {
	// TMG_RegisterMiniAction(float:requiredTime, tMiniGamesActionCallback:func)
	new Float:fRequiredTime = GetNativeCell(1);
	new iOpt = GetNativeCell(4);

	new Handle:hFwd = CreateForward(ET_Hook, Param_String, Param_Cell, Param_Cell);
	if (!AddToForward(hFwd, hPlugin, GetNativeCell(2)))
	{
		decl String:szCallerName[PLATFORM_MAX_PATH];
		GetPluginFilename(hPlugin, szCallerName, sizeof(szCallerName));
		ThrowError("Failed to add forward from %s", szCallerName);
	}

	new Handle:hBwd = CreateForward(ET_Hook);
	if (!AddToForward(hBwd, hPlugin, GetNativeCell(3)))
	{
		decl String:szCallerName[PLATFORM_MAX_PATH];
		GetPluginFilename(hPlugin, szCallerName, sizeof(szCallerName));
		ThrowError("Failed to add forward from %s", szCallerName);
	}

	LogMessage("Registered minigame: %i", g_iMiniActionCount);
	xMiniActions[g_iMiniActionCount][requiredTime] = fRequiredTime;
	xMiniActions[g_iMiniActionCount][fwd] = hFwd;
	xMiniActions[g_iMiniActionCount][bwd] = hBwd;
	xMiniActions[g_iMiniActionCount][opt] = iOpt;
	g_iMiniActionCount++;

	return;
}


