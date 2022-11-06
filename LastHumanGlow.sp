#include <sdktools>
#include <cstrike>

bool glow;
bool glowEnabled[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "Last Human Glow",
	author = "Walderr",
	description = "Выделяет последнего выжившего",
	version = "0.2",
};

public OnPluginStart()
{
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_start", Event_RoundStart);
	
	CreateTimer(1.0, Timer_CheckGlow, _, TIMER_REPEAT);
}

public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	if(GetEventInt(event, "oldteam") == CS_TEAM_CT) CreateTimer(0.0, Timer_CheckHumans);
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++) glowEnabled[i] = false;
	
	glow = false;
}

public Action Timer_CheckHumans(Handle timer)
{
	if(GetTeamClientCount(CS_TEAM_CT) > 1) return;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
		{
			glow = true;
			glowEnabled[i] = true;
			break;
		}
	}
}

public Action Timer_CheckGlow(Handle timer)
{
	if(!glow) return;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(glowEnabled[i])
		{
			if(!IsClientConnected(i) || !IsClientInGame(i) || GetClientTeam(i) != CS_TEAM_CT)
			{
				glowEnabled[i] = false;
				break;
			}
			
			SetEntPropFloat(i, Prop_Send, "m_flDetectedByEnemySensorTime", GetGameTime() + 2.0);
			break;
		}
	}
}
