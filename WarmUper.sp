#include <sdktools>

public OnPluginStart()
{
    HookEvent("player_spawn", OnPlayerSpawned);
}

public OnPlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameRules_GetProp("m_bWarmupPeriod") == 1)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		SetEntProp(client, Prop_Data, "m_takedamage", 0);
	}
}