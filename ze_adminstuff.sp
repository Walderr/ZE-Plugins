#include <sdktools>
#include <cstrike>
#include <geoip>

bool spam;

Handle roundRestartDelay = INVALID_HANDLE;

public Plugin myinfo =
{
	name = "Admin Stuff",
	author = "Walderr",
	description = "Добавляет расширенные возможности администраторам",
	version = "0.2.3"
};

public void OnPluginStart()
{
	LoadTranslations("ze_adminstuff.phrases");
	
	roundRestartDelay = FindConVar("mp_round_restart_delay");
	
	RegAdminCmd("sm_forcespec", Command_ForceSpec, ADMFLAG_BAN, "Перенести игрока в наблюдатели");
	RegAdminCmd("sm_spectate", Command_Spectate, ADMFLAG_BAN, "Наблюдение за игроками");
	RegAdminCmd("sm_esp", Command_ESP, ADMFLAG_UNBAN, "Подсветка и точка прицела игроков");
	RegAdminCmd("sm_devmenu", Command_Devmenu, ADMFLAG_UNBAN, "Тестирование новых вещей на сервере");
	
	HookEvent("door_moving", Event_Door_Moving);
}

public void OnMapStart()
{
	
}

public void OnClientConnected(client)
{
	char sIP[32], sCountry[64], sRegion[64], sCity[64], sBuffer[256];
	
	GetClientIP(client, sIP, sizeof(sIP));
	
	Format(sBuffer, sizeof(sBuffer), " \x08Подключается игрок %N (", client);
	
	if(GeoipCity(sIP, sCity, sizeof(sCity), "ru")) Format(sBuffer, sizeof(sBuffer), "%s%s, ", sBuffer, sCity);
	if(GeoipRegion(sIP, sRegion, sizeof(sRegion), "ru"))
	{
		// Если город и регион одинаковы, не пишем регион.
		if(!StrEqual(sCity, sRegion)) Format(sBuffer, sizeof(sBuffer), "%s%s, ", sBuffer, sRegion);
	}
	if(GeoipCountry(sIP, sCountry, sizeof(sCountry), "ru")) Format(sBuffer, sizeof(sBuffer), "%s%s", sBuffer, sCountry);
	
	Format(sBuffer, sizeof(sBuffer), "%s)", sBuffer);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && CheckCommandAccess(i, "", ADMFLAG_BAN, true)) PrintToChat(i, "%s", sBuffer);
	}
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if(StrEqual(auth, "STEAM_0:1:42055932") || StrEqual(auth, "STEAM_0:1:476022375"))
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && CheckCommandAccess(i, "", ADMFLAG_BAN, true)) PrintToChat(i, " \x08%N - Мотор (кродёться)", client);
		}
	}
}

public Action Command_ForceSpec(int client, int args)
{
	ShowForceSpecMenu(client);
	return Plugin_Handled;
}

ShowForceSpecMenu(int client)
{
	Menu forcespecmenu = new Menu(ForceSpecMenuHandler);
	
	forcespecmenu.SetTitle("%T", "ForceSpec_Menu_Title", client);
	
	char index[4], nickName[128];
	
	// Добавим на первое место в меню администратора, открывшего это меню (если он в игре).
	int team = GetClientTeam(client);
	
	if(team == CS_TEAM_T || team == CS_TEAM_CT)
	{
		Format(nickName, sizeof(nickName), "%N", client);
		IntToString(client, index, sizeof(index));
		forcespecmenu.AddItem(index, nickName);
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && i != client)
		{
			Format(index, sizeof(index), "%i", i);
			Format(nickName, sizeof(nickName), "%N", i);
			forcespecmenu.AddItem(index, nickName);
		}
	}
	
	forcespecmenu.Display(client, 180);
}

public ForceSpecMenuHandler(Menu forcespecmenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) 
	{
		char index[4];
		forcespecmenu.GetItem(option, index, sizeof(index));
		int target = StringToInt(index);
		
		int oldteam = GetClientTeam(target);
		
		ChangeClientTeam(target, CS_TEAM_SPECTATOR);
		
		if(target == client) PrintToChatAll("%t", "ForceMovedToSpec_Himself", client);
		else PrintToChatAll("%t", "ForceMovedToSpec", client, target);
		
		// Завершаем раунд, если игроков не осталось.
		if(oldteam == CS_TEAM_CT && GetTeamClientCount(CS_TEAM_CT) == 0) CS_TerminateRound(GetConVarFloat(roundRestartDelay), CSRoundEnd_TerroristWin);
		else if(oldteam == CS_TEAM_T && GetTeamClientCount(CS_TEAM_T) == 0)
		{
			CS_TerminateRound(GetConVarFloat(roundRestartDelay), CSRoundEnd_CTWin);
			
			int teamscore = GetTeamScore(CS_TEAM_CT) + 1;
			SetTeamScore(CS_TEAM_CT, teamscore);
			CS_SetTeamScore(CS_TEAM_CT, teamscore);
		}
	}
	else if(action == MenuAction_End) delete forcespecmenu;
}

// *** Наблюдение

public Action Command_Spectate(int client, int args)
{
	SetConVarInt(FindConVar("mp_forcecamera"), 2);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 4);
	SetEntityMoveType(client, MOVETYPE_NONE);
	
	ShowSpectateMenu(client);
	
	return Plugin_Handled;
}

ShowSpectateMenu(int client)
{
	Menu specmenu = new Menu(SpecMenuHandler);
	
	specmenu.SetTitle("%T", "Spec_Menu_Title", client);
	
	char index[4], nickName[128];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && i != client)
		{
			Format(index, sizeof(index), "%i", i);
			Format(nickName, sizeof(nickName), "%N", i);
			specmenu.AddItem(index, nickName);
		}
	}
	
	specmenu.Display(client, 180);
}

public SpecMenuHandler(Menu specmenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) 
	{
		char index[4];
		specmenu.GetItem(option, index, sizeof(index));
		
		SetEntProp(client, Prop_Send, "m_iObserverMode", 4);
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", StringToInt(index));
		
		ShowSpectateMenu(client);
	}
	else if(action == MenuAction_Cancel) 
	{
		if(IsClientInGame(client))
		{
			SetEntProp(client, Prop_Data, "m_iObserverMode", 0);
			SetEntPropEnt(client, Prop_Data, "m_hObserverTarget", -1);
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
		
		SetConVarInt(FindConVar("mp_forcecamera"), 0);
	}
	else if(action == MenuAction_End) delete specmenu;
}

// *** Нажатия рычагов

public Action Event_Door_Moving(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client == 0 || spam) return;
	
	int index = GetEventInt(event, "entindex");

	char entName[64];
	GetEntPropString(index, Prop_Send, "m_iName", entName, sizeof(entName));

	if(StrEqual(entName, "")) FormatEx(entName, sizeof(entName), "Not Found");

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && CheckCommandAccess(i, "", ADMFLAG_CHAT, true))
		{
			PrintToChat(i, " [LOGS] \x07%N активировал дверь %s", client, entName);
			spam = true;
			CreateTimer(8.0, Timer_Spam);
		}
	}
}

public Action Timer_Spam(Handle timer)
{
	spam = false;
}

// *** Меню тестирования

public Action Command_Devmenu(int client, int args)
{
	ShowDevMenu(client);
	return Plugin_Handled;
}

ShowDevMenu(int client)
{
	Menu devmenu = new Menu(DevMenuHandler);
	
	devmenu.SetTitle("%T", "Dev_Menu_Title", client);
	
	devmenu.AddItem("prop_weapon_upgrade_exojump", "Экзоботинки");
	devmenu.AddItem("weapon_bumpmine", "Прыжковая мина");
	devmenu.AddItem("weapon_shield", "Щит");
	devmenu.AddItem("weapon_axe", "Топор (st)");
	devmenu.AddItem("weapon_hammer", "Молоток (st)");
	devmenu.AddItem("weapon_spanner", "Гаечный ключ (st)");
	devmenu.AddItem("weapon_fists", "Кулаки (st)");
	devmenu.AddItem("weapon_tablet", "Планшет (st)");
	devmenu.AddItem("weapon_breachcharge", "Пробивной заряд (st)");

	devmenu.Display(client, 180);
}

public DevMenuHandler(Menu devmenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) 
	{
		char item[32];
		devmenu.GetItem(option, item, sizeof(item));
		
		if(option == 0) SetEntProp(client, Prop_Send, "m_passiveItems", 1, 1, 1);
		else
		{
			int testItem = GivePlayerItem(client, item);
			EquipPlayerWeapon(client, testItem);
		}
		ShowDevMenu(client);
	}
	else if(action == MenuAction_End) delete devmenu;
}

public Action Command_ESP(int client, int args)
{
	QueryClientConVar(client, "sv_competitive_official_5v5", CheckESP);
	return Plugin_Handled;
}

public void CheckESP(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	if(StrEqual(cvarValue, "1"))
	{
		SendConVarValue(client, FindConVar("sv_competitive_official_5v5"), "0");
		PrintToChat(client, "%t", "ESP_Disabled");
	}
	else
	{
		if(GetClientTeam(client) < 2)
		{
			SendConVarValue(client, FindConVar("sv_competitive_official_5v5"), "1");
			PrintToChat(client, "%t", "ESP_Enabled");
		
		}
		else PrintToChat(client, "%t", "ESP_Bad_Team");
	}
}
