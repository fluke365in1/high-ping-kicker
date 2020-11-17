#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "1.0.0"

#define CVAR_FLAGS FCVAR_NOTIFY

// Log path and player warning/grace period arrays
char Logfile[PLATFORM_MAX_PATH];
int PingWarnings[MAXPLAYERS + 1];
int PingDelay[MAXPLAYERS + 1];

// Timer handle for primary ping checking
Handle PingTimer;

// Used to disable ping checking right after map change
int TimerCheck;

// Cvar handles
ConVar cvar_MinTime;
ConVar cvar_MaxPing;
ConVar cvar_CheckRate;
ConVar cvar_MaxWarnings;
ConVar cvar_MinPlayers;
ConVar cvar_LogActions;
ConVar cvar_ShowPublicKick;
ConVar cvar_ShowWarnings;
ConVar cvar_ImmunityFlag;
ConVar cvar_IgnoreHourMin;
ConVar cvar_IgnoreHourMax;

char g_sFlag[16];
float g_fLastTime[MAXPLAYERS+1];
float g_fCvarMinTime;
int g_iCvarMaxPing;
int g_iCvarMaxWarnings;
int g_iCvarMinPlayers;
bool g_bCvarLogActions;
bool g_bCvarShowPublicKick;
bool g_bCvarShowWarnings;
int g_iCvarIgnoreHourMin;
int g_iCvarIgnoreHourMax;


public Plugin myinfo = 
{
	name = "High Ping Kicker",
	author = "Orbit One",
	description = "Automatically kick users going beyond your wished-for max ping limit, giving your players a better experience.",
	version = PLUGIN_VERSION,
	url = "https://orbitone.org/"
};

// Here we go!
public void OnPluginStart()
{
	LoadTranslations("vbping.phrases");

	// Plugin version public Cvar
	CreateConVar("sm_vbping_version", PLUGIN_VERSION, "High Ping Kicker version", CVAR_FLAGS|FCVAR_DONTRECORD);

	// Debug command to see who is going to get kicked
	RegConsoleCmd("sm_ping", cmd_Debug, "Displays player ping debug information");

	// Config Cvars
	cvar_MinTime = 			CreateConVar("sm_vbping_mintime",				"30",				"Minimum playtime before ping check begins", CVAR_FLAGS);
	cvar_MaxPing = 			CreateConVar("sm_vbping_maxping",				"500",				"Maximum player ping", CVAR_FLAGS, true, 1.0);
	cvar_CheckRate = 		CreateConVar("sm_vbping_checkrate",				"20.0",				"Period in seconds when rate is checked", CVAR_FLAGS, true, 1.0);
	cvar_MaxWarnings = 		CreateConVar("sm_vbping_maxwarnings",			"3",				"Number of warnings before kick", CVAR_FLAGS, true, 1.0);
	cvar_MinPlayers = 		CreateConVar("sm_vbping_minplayers",			"3",				"Minimum number of players before kicking", CVAR_FLAGS);
	cvar_LogActions = 		CreateConVar("sm_vbping_logactions",			"1",				"Log warning and kick actions. 0 = Disabled, 1 = Enabled", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_ShowWarnings = 	CreateConVar("sm_vbping_showwarnings",			"1",				"Enable/disable warning messages. 0 = Disabled, 1 = Enabled", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_ShowPublicKick = 	CreateConVar("sm_vbping_showpublickick",		"1",				"Enable/disable public kick message. 0 = Disabled, 1 = Enabled", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_ImmunityFlag = 	CreateConVar("sm_vbping_immunityflag",			"k",				"SourceMod admin flag used to grant immunity to all ping checking/kicking", CVAR_FLAGS);
	cvar_IgnoreHourMin = 	CreateConVar("sm_vbping_ignore_hour_start",		"-1",				"Start hour where ping check should be disabled (or -1 to disable this feature)", CVAR_FLAGS, true, -1.0, true, 23.0);
	cvar_IgnoreHourMax = 	CreateConVar("sm_vbping_ignore_hour_end",		"-1",				"End hour where ping check should be disabled (or -1 to disable this feature)", CVAR_FLAGS, true, -1.0, true, 23.0);
	
	// Make that config!
	AutoExecConfig(true, "vbping");
	
	GetCvars();
	
	// Hook changing of the ping checking rate cvar
	cvar_CheckRate.AddChangeHook(action_RateChanged);
	
	cvar_ImmunityFlag.AddChangeHook(action_ConVarChanged);
	cvar_MinTime.AddChangeHook(action_ConVarChanged);
	cvar_MaxPing.AddChangeHook(action_ConVarChanged);
	cvar_MaxWarnings.AddChangeHook(action_ConVarChanged);
	cvar_MinPlayers.AddChangeHook(action_ConVarChanged);
	cvar_LogActions.AddChangeHook(action_ConVarChanged);
	cvar_ShowWarnings.AddChangeHook(action_ConVarChanged);
	cvar_ShowPublicKick.AddChangeHook(action_ConVarChanged);
	cvar_IgnoreHourMin.AddChangeHook(action_ConVarChanged);
	cvar_IgnoreHourMax.AddChangeHook(action_ConVarChanged);
	
	// Enable logging
	BuildPath(Path_SM, Logfile, sizeof(Logfile), "logs/vbping.log");

	// Initialize everyone's warnings at 0
	for (int i = 1; i <= MaxClients; i++)
	{
		PingWarnings[i] = 0;
		PingDelay[i] = true;
	}
	
	// Start the timer
	PingTimer = CreateTimer(cvar_CheckRate.FloatValue, timer_CheckPing, INVALID_HANDLE, TIMER_REPEAT);

	// Delay ping checking for 90 seconds to allow pings to normalize
	TimerCheck = true;
	CreateTimer(g_fCvarMinTime, timer_EnableCheck);
}

// Reset all players' warnings to 0, grant all players connection immunity,
// and restart ping checking timer in case one is already running.

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		PingWarnings[i] = 0;
		PingDelay[i] = true;
	}

	if (PingTimer == null) PingTimer = CreateTimer(cvar_CheckRate.FloatValue, timer_CheckPing, INVALID_HANDLE, TIMER_REPEAT);

	// Delay ping checking for 90 seconds to allow pings to normalize
	TimerCheck = true;
	CreateTimer(g_fCvarMinTime, timer_EnableCheck, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
}

// Print debug information
public Action cmd_Debug(int client, int args)
{
	static float fNowTime;
	fNowTime = GetGameTime();
	if (g_fLastTime[client] != 0.0 && FloatAbs(fNowTime - g_fLastTime[client]) < 1.0) {
		return Plugin_Handled;
	}
	g_fLastTime[client] = fNowTime;

	if (GetUserFlagBits(client) != 0)
	{
		PrintPingInfo(client, client);
	}
	else {
		for (int i = 1; i <= MaxClients; i++)
		{
			if (i != client && IsClientInGame(i) && !IsFakeClient(i))
			{
				PrintPingInfo(client, i);
			}
		}
		PrintPingInfo(client, client);
	}
	return Plugin_Handled;
}

void PrintPingInfo(int client, int target)
{
	float Ping = GetClientAvgLatency(target, NetFlow_Outgoing) * 1024;
	if ((GetUserFlagBits(target) & ReadFlagString(g_sFlag)) || (GetUserFlagBits(target) & ADMFLAG_ROOT)) ReplyToCommand(client, " %-32N %t: %-8.0f *%t*", target, "Ping", Ping, "IMMUNE");
	else if (PingDelay[target]) ReplyToCommand(client, " %-32N %t: %-8.0f *%t*", target, "Ping", Ping, "CONNECTING");
	else ReplyToCommand(client, " %-32N %t: %-8.0f %t: %i", target, "Ping", Ping, "Warnings", PingWarnings[target]);
}

// Initialize client's warnings to 0 when they connect and grant them
// connection grace period.

public void OnClientPostAdminCheck(int client)
{
	PingWarnings[client] = 0;
	PingDelay[client] = true;
	CreateTimer(g_fCvarMinTime, timer_ExpirePingDelay, GetClientUserId(client));
}

// Enable ping checking again, after the map change delay.
public Action timer_EnableCheck(Handle timer)
{
	TimerCheck = false;

	for (int i = 1; i <= MaxClients; i++)
	{
		PingWarnings[i] = 0;
		PingDelay[i] = false;
	}
}

// Enable ping checking after client has connected and their
// grace period has expired.

public Action timer_ExpirePingDelay(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	PingDelay[client] = false;
}

// Restart the timer if the rate of change is altered after the plugin has
// began running.

public int action_RateChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	delete PingTimer;
	PingTimer = CreateTimer(convar.FloatValue, timer_CheckPing, INVALID_HANDLE, TIMER_REPEAT);
}

public int action_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	cvar_ImmunityFlag.GetString(g_sFlag, sizeof(g_sFlag));
	g_fCvarMinTime = cvar_MinTime.FloatValue;
	g_iCvarMaxPing = cvar_MaxPing.IntValue;
	g_iCvarMaxWarnings = cvar_MaxWarnings.IntValue;
	g_iCvarMinPlayers = cvar_MinPlayers.IntValue;
	g_bCvarLogActions = cvar_LogActions.BoolValue;
	g_bCvarShowPublicKick = cvar_ShowPublicKick.BoolValue;
	g_bCvarShowWarnings = cvar_ShowWarnings.BoolValue;
	g_iCvarIgnoreHourMin = cvar_IgnoreHourMin.IntValue;
	g_iCvarIgnoreHourMax = cvar_IgnoreHourMax.IntValue;
}

// Check the ping!
public Action timer_CheckPing(Handle timer)
{
	// If the map has recently changed, quit all ping checking
	if (TimerCheck) return;
	
	if( g_iCvarIgnoreHourMin != -1 )
	{
		int time = GetTime();
		int hours = (time / 3600) % 24;
		
		if (hours >= g_iCvarIgnoreHourMin && hours <= g_iCvarIgnoreHourMax)
			return;
	}
	
	static char SteamID[64];
	float Ping;

	// First, let's get a count of the players in-game.
	int Players = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i)) Players++;
	}

	// If the number of players is less than the minimum set by the plugin,
	// then quit out.

	if (Players < g_iCvarMinPlayers) return;

	// Perform the actual ping checking and warn issuing.
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			// If the client has been connected for less time than the
			// minimum set by the plugin, ignore them.

			if (PingDelay[i]) continue;

			// If the client has exceeded the number of warnings, kick them.
			// This is done before giving a warnings, so they are not warned
			// their final time, and then kicked for it.

			if (PingWarnings[i] >= g_iCvarMaxWarnings)
			{
				GetClientAuthId(i, AuthId_Steam2, SteamID, sizeof(SteamID));
				
				if (g_bCvarShowPublicKick)
				{
					CPrintToChatAll("%t", "Is_Kicked_All", i); // \x05%N \x04kicked: \x01ping is too high.
				}
				
				if (g_bCvarLogActions) LogToFileEx(Logfile, "%N [%s] has been kicked, excessive ping warnings (%i)", i, SteamID, PingWarnings[i]);

				KickClient(i, "%t", "Is_Kicked_Client"); // Your ping is too high

				PingWarnings[i] = 0;
				continue;
			}
			
			// If the client's ping exceedes the maximum set by the plugin,
			// give them a warning.
			
			Ping = GetClientAvgLatency(i, NetFlow_Outgoing) * 1024;
			if (Ping > g_iCvarMaxPing)
			{
				// If the client has the immunity or ROOT flag, ignore them
				if ((GetUserFlagBits(i) & ReadFlagString(g_sFlag)) || (GetUserFlagBits(i) & ADMFLAG_ROOT)) continue;

				// If not, then give them the warning
				PingWarnings[i] ++;

				// Tell the player they received a ping warning
				if (g_bCvarShowWarnings)
				{
					PrintHintText(i, "%t", "Warn_Msg", PingWarnings[i], g_iCvarMaxWarnings);
				}
				// Log the warning to the ping log
				if (g_bCvarLogActions) LogToFileEx(Logfile, "%N has %i ping warning (Ping: %f)", i, PingWarnings[i], Ping);
			}
		}
	}
}

stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}

stock void CPrintToChatAll(const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            ReplaceColor(buffer, sizeof(buffer));
            PrintToChat(i, "\x01%s", buffer);
        }
    }
}