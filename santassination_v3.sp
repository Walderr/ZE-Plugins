#include <sdktools>

bool isMapSanta = false;
int iTime = 0;

public void OnMapStart()
{
	char map[128];
	GetCurrentMap(map, sizeof(map));
	
	if(StrEqual(map, "ze_santassination_v3"))
	{
		HookEntityOutput("trigger_multiple", "OnTrigger", Hook_OnTrigger);
		CreateTimer(1.0, Timer_PlayTime, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
		isMapSanta = true;
	}
}

public void OnMapEnd()
{
	if(isMapSanta)
	{
		UnhookEntityOutput("trigger_multiple", "OnTrigger", Hook_OnTrigger);
		iTime = 0;
		isMapSanta = false;
	}
}

public void Hook_OnTrigger(const char[] output, int caller, int activator, float delay)
{
	if(activator < 1 || activator > MaxClients) return;
	
	if(GetEntProp(caller, Prop_Data, "m_iHammerID") == 1000000)
		PrintToChatAll(" \x07%N разбудил монстра!", activator);
}

public Action Timer_PlayTime(Handle timer)
{
	int hours = iTime / 3600;
	int minutes = (iTime / 60) % 60;
	int seconds = iTime % 60;
	
	char text[64];
	FormatEx(text, sizeof(text), "SANTA TIME: %i:%i%i:%i%i", hours, minutes / 10, minutes % 10, seconds / 10, seconds % 10);
	
	SetHudTextParams(0.58, 0.10, 2.0, 128, 255, 255, 255, 0, 1.0, 0.0, 0.0);
	
	for(int client = 1; client <= MaxClients; client++)
		if(IsClientInGame(client)) ShowHudText(client, 5, text);
			
	iTime++;
}
