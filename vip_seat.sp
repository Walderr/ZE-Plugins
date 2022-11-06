#include <sdktools>
#include <cstrike>

int bSeated[MAXPLAYERS+1];

Handle tSeatCheck[MAXPLAYERS+1] = INVALID_HANDLE;

public Plugin myinfo =
{
	name = "VIP - Seat",
	author = "Walderr",
	description = "Позволяет садиться на других игроков",
	version = "1.1",
	url = "http://www.jaze.ru/"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_seat", Command_Seat, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_unseat", Command_Unseat, ADMFLAG_CUSTOM1);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_team", Event_PlayerTeam);
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(bSeated[i]) bSeated[i] = false;
		
		if(IsClientInGame(i) && GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity") != -1) SetEntPropEnt(i, Prop_Data, "m_hOwnerEntity", -1);
	}
}

public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	int team = GetEventInt(event, "team");
	
	if(bSeated[client])
	{
		if(team == CS_TEAM_T) FakeClientCommand(client, "sm_unseat");
	}
	
	if(team < 2)
	{
		if(bSeated[client]) FakeClientCommand(client, "sm_unseat");
		
		int owner = GetEntPropEnt(client, Prop_Data, "m_hOwnerEntity");
		
		if(owner != -1)
		{
			FakeClientCommand(owner, "sm_unseat");
			
			bSeated[owner] = false;
			
			PrintToChat(owner, " \x09[Seat] Игрок %N больше не доступен!", client);
		}
	}
}

public Action Command_Seat(int client, int args)
{
	char arg[64];
	GetCmdArgString(arg, sizeof(arg));
	
	new target = FindTarget(client, arg);
	if(target == -1) return Plugin_Handled;
	
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, " \x09[Seat] Вы должны быть живы!");
		return Plugin_Handled;
	}
	else if(bSeated[client])
	{
		PrintToChat(client, " \x09[Seat] Вы уже сидите на игроке %N!", GetEntPropEnt(client, Prop_Data, "m_pParent"));
		return Plugin_Handled;
	}
	else if(target == client)
	{
		PrintToChat(client, " \x09[Seat] На себя садиться нельзя!");
		return Plugin_Handled;
	}
	else if(GetClientTeam(client) != GetClientTeam(target))
	{
		PrintToChat(client, " \x09[Seat] Можно садиться только на игроков своей команды!");
		return Plugin_Handled;
	}
	else if(GetEntPropEnt(target, Prop_Data, "m_pParent") != -1)
	{
		PrintToChat(client, " \x09[Seat] Этот игрок уже сидит на ком-то!");
		return Plugin_Handled;
	}
	else if(GetEntPropEnt(target, Prop_Data, "m_hOwnerEntity") != -1)
	{
		PrintToChat(client, " \x09[Seat] На этом игроке уже сидит %N!", GetEntPropEnt(target, Prop_Data, "m_hOwnerEntity"));
		return Plugin_Handled;
	}
	
	float m_flTargetOrigin[3];
	GetClientAbsOrigin(target, m_flTargetOrigin);
	
	m_flTargetOrigin[2] = m_flTargetOrigin[2] + 30.0;
	
	SetEntityMoveType(client, MOVETYPE_NONE);

	TeleportEntity(client, m_flTargetOrigin, NULL_VECTOR, NULL_VECTOR);
	
	SetVariantString("!activator");
	AcceptEntityInput(client, "SetParent", target, client);

	SetEntPropEnt(target, Prop_Data, "m_hOwnerEntity", client);

	bSeated[client] = true;
	
	PrintToChatAll(" \x09[Seat] %N сел на игрока %N.", client, target);
	
	tSeatCheck[client] = CreateTimer(5.0, Timer_SeatCheck, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;
}

public Action Command_Unseat(int client, int args)
{
	AcceptEntityInput(client, "ClearParent");
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	bSeated[client] = false;
	
	int parent = GetEntPropEnt(client, Prop_Data, "m_pParent");
	
	if(parent != -1)
	{
		SetEntPropEnt(parent, Prop_Data, "m_hOwnerEntity", -1);
		
		PrintToChatAll(" \x09[Seat] %N слез с игрока %N.", client, parent);
	}
	
	if(tSeatCheck[client] != INVALID_HANDLE)
	{
		KillTimer(tSeatCheck[client]);
		tSeatCheck[client] = INVALID_HANDLE;
	}
	
	return Plugin_Handled;
}

public Action Timer_SeatCheck(Handle timer, any client)
{
	int parent = GetEntPropEnt(client, Prop_Data, "m_pParent");

	if(parent == -1)
	{
		KillTimer(tSeatCheck[client]);
		tSeatCheck[client] = INVALID_HANDLE;
		
		return;
	}
	
	float clientCoordinates[3];
	GetClientAbsOrigin(client, clientCoordinates);
	
	float parentCoordinates[3];
	GetClientAbsOrigin(parent, parentCoordinates);
	
	
	float distance = GetVectorDistance(clientCoordinates, parentCoordinates);

	if(distance > 30.0)
	{
		SetEntPropEnt(parent, Prop_Data, "m_hOwnerEntity", -1);
	
		AcceptEntityInput(client, "ClearParent");
	
		float m_flTargetOrigin[3];
		GetClientAbsOrigin(parent, m_flTargetOrigin);
		
		m_flTargetOrigin[2] = m_flTargetOrigin[2] + 30.0;
		
		SetEntityMoveType(client, MOVETYPE_NONE);
		TeleportEntity(client, m_flTargetOrigin, NULL_VECTOR, NULL_VECTOR);
		
		SetVariantString("!activator");
		AcceptEntityInput(client, "SetParent", parent, client);

		SetEntPropEnt(parent, Prop_Data, "m_hOwnerEntity", client);
	}
}
