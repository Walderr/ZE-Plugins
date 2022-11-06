#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <ClientPrefs>
#include <ze_commander>

// Hide
bool g_bHideEnabled[MAXPLAYERS+1];
bool g_bHideAll[MAXPLAYERS+1];
bool g_bHideLeader[MAXPLAYERS+1];
int g_iDistance[MAXPLAYERS+1];

bool enableHide[MAXPLAYERS+1][MAXPLAYERS+1];
float g_fDistance[MAXPLAYERS+1];

float absClient[3];
float absTarget[3];
float fDistance;

Handle h_HideEnabledCookie = INVALID_HANDLE;
Handle h_HideAllCookie = INVALID_HANDLE;
Handle h_HideDistanceCookie = INVALID_HANDLE;
Handle h_HideLeaderCookie = INVALID_HANDLE;

// Buttons
bool spamProtect;
bool b_ButtonsLog[MAXPLAYERS+1];
bool b_ButtonsBan[MAXPLAYERS+1];

// Extend
int extendsCount;
bool extendVotedPlayers[MAXPLAYERS+1];
bool voteStarted;
bool voteTimeout;
Handle h_TimeLimit = INVALID_HANDLE;

Handle h_ButtonsInChat = INVALID_HANDLE;

public Plugin myinfo =
{
	name = "Game Stuff",
	author = "Walderr",
	description = "Расширенные возможности и функции для игры",
	version = "1.3",
	url = "http://www.jaze.ru/"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("ze_gamestuff.phrases");
	
	RegConsoleCmd("sm_hide", Command_Hide, "Выбрать дальность скрытия игроков");
	RegConsoleCmd("sm_hideall", Command_Hideall, "Скрывать всех игроков");
	
	RegConsoleCmd("sm_spec", Command_Spec, "Перейти в наблюдатели/Наблюдать за игроком");
	RegConsoleCmd("sm_afk", Command_Afk, "Перейти в наблюдатели");
	
	RegConsoleCmd("sm_extend", Command_Extend, "Проголосовать за продление карты");
	RegConsoleCmd("sm_ext", Command_Extend, "Проголосовать за продление карты");
	
	RegConsoleCmd("sm_commands", Command_Menu, "Список команд сервера");
	RegConsoleCmd("sm_help", Command_Menu, "Список команд сервера");
	RegConsoleCmd("sm_menu", Command_Menu, "Список команд сервера");
	
	RegAdminCmd("sm_bban", Command_BBan, ADMFLAG_UNBAN, "Запретить нажимать на кнопки");
	
	h_TimeLimit = FindConVar("mp_timelimit");
	
	h_HideEnabledCookie = RegClientCookie("HideEnabled", "Состояние скрытия игроков своей команды", CookieAccess_Private);
	h_HideAllCookie = RegClientCookie("HideAll", "Скрывать всех игроков", CookieAccess_Private);
	h_HideDistanceCookie = RegClientCookie("HideDistance", "Дальность скрытия", CookieAccess_Private);
	h_HideLeaderCookie = RegClientCookie("HideLeader", "Скрыть лидера", CookieAccess_Private);
	
	h_ButtonsInChat = RegClientCookie("ButtonsInChat", "Выводить в чат информацию о нажатиях кнопок", CookieAccess_Public);
	
	SetCookieMenuItem(ButtonsCookieHandler, 0, "Buttons Settings");
	
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	HookEvent("player_connect_full", Event_PlayerConnectFull);
	HookEvent("round_end", Event_RoundEnd);
	
	HookEntityOutput("func_button", "OnPressed", Hook_OnPressed);
	HookEntityOutput("func_rot_button", "OnPressed", Hook_OnPressed);
	
	AddNormalSoundHook(SoundHook_Normal);
	
	AddCommandListener(Button_F4, "rebuy");
}

public void OnMapStart()
{
	CreateTimer(1.0, Timer_Hide, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.0, Timer_TimeLeft, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapEnd()
{
	// Сбрасываем счётчик количества продлений карты.
	extendsCount = 0;
	
	// Сбрасываем голоса всех игроков (продление карты).
	for(int i = 1; i <= MaxClients; i++) extendVotedPlayers[i] = false;
}

public void ButtonsCookieHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if(action == CookieMenuAction_SelectOption) DisplayButtonsMenu(client);
}

void DisplayButtonsMenu(int client)
{
	SetGlobalTransTarget(client);
	Menu buttonMenu = new Menu(ButtonMenuHandler);
	
	char Yes[32], No[32];
	Format(Yes, sizeof(Yes), "%t", "Yes");
	Format(No, sizeof(No), "%t", "No");
	
	buttonMenu.SetTitle("%T", "Buttons_Menu_Title", client);
	
	if(b_ButtonsLog[client])
	{
		buttonMenu.AddItem("1", Yes, ITEMDRAW_DISABLED);
		buttonMenu.AddItem("0", No);
	}
	else
	{
		buttonMenu.AddItem("1", Yes);
		buttonMenu.AddItem("0", No, ITEMDRAW_DISABLED);
	}
	
	buttonMenu.ExitBackButton = true;
	buttonMenu.Display(client, 180);
}

public int ButtonMenuHandler(Menu buttonMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) 
	{
		if(option == 0) b_ButtonsLog[client] = true;
		else if(option == 1) b_ButtonsLog[client] = false;
		
		DisplayButtonsMenu(client);
	}
	else if(action == MenuAction_Cancel) 
	{
		if(option == MenuCancel_ExitBack) ShowCookieMenu(client);
	}
	else if(action == MenuAction_End) delete buttonMenu;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
}

public void OnClientCookiesCached(int client)
{
	if(IsFakeClient(client)) return;
	
	char tempChar[8];
	
	GetClientCookie(client, h_HideEnabledCookie, tempChar, sizeof(tempChar));
	if(StrEqual(tempChar, "1")) g_bHideEnabled[client] = true;
	else g_bHideEnabled[client] = false;
	
	GetClientCookie(client, h_HideAllCookie, tempChar, sizeof(tempChar));
	if(StrEqual(tempChar, "1")) g_bHideAll[client] = true;
	else g_bHideAll[client] = false;
	
	GetClientCookie(client, h_HideLeaderCookie, tempChar, sizeof(tempChar));
	if(StrEqual(tempChar, "1")) g_bHideLeader[client] = true;
	else g_bHideLeader[client] = false;
	
	GetClientCookie(client, h_HideDistanceCookie, tempChar, sizeof(tempChar));
	if(StrEqual(tempChar, ""))
	{
		g_iDistance[client] = 50;
		g_fDistance[client] = Pow(float(g_iDistance[client]), 2.0);
	}
	else
	{
		g_iDistance[client] = StringToInt(tempChar);
		g_fDistance[client] = Pow(float(g_iDistance[client]), 2.0);
	}
	
	GetClientCookie(client, h_ButtonsInChat, tempChar, sizeof(tempChar));
	if(StrEqual(tempChar, "1")) b_ButtonsLog[client] = true;
	else b_ButtonsLog[client] = false;
}

public void OnClientDisconnect(int client)
{
	if(AreClientCookiesCached(client))
	{
		char tempChar[8];

		Format(tempChar, sizeof(tempChar), "%i", g_bHideEnabled[client]);
		SetClientCookie(client, h_HideEnabledCookie, tempChar);
		
		Format(tempChar, sizeof(tempChar), "%i", g_bHideAll[client]);
		SetClientCookie(client, h_HideAllCookie, tempChar);
		
		Format(tempChar, sizeof(tempChar), "%i", g_bHideLeader[client]);
		SetClientCookie(client, h_HideLeaderCookie, tempChar);
		
		IntToString(g_iDistance[client], tempChar, sizeof(tempChar));
		SetClientCookie(client, h_HideDistanceCookie, tempChar);
		
		Format(tempChar, sizeof(tempChar), "%i", b_ButtonsLog[client]);
		SetClientCookie(client, h_ButtonsInChat, tempChar);
	}
	
	b_ButtonsBan[client] = false;
	
	// Удаляем голос игрока (продление карты).
	extendVotedPlayers[client] = false;
}

public Action Event_RoundFreezeEnd(Handle event, const char[] name, bool dontBroadcast)
{
	int index = -1;
	
	while((index = FindEntityByClassname(index, "func_button")) != -1) 
	{
		SDKHook(index, SDKHook_Use, Hook_Use);
	}
	
	while((index = FindEntityByClassname(index, "func_rot_button")) != -1) 
	{
		SDKHook(index, SDKHook_Use, Hook_Use);
	}
}

public Action Event_PlayerConnectFull(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	CreateTimer(10.0, Timer_ThrowToSpec, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ThrowToSpec(Handle timer, any client)
{
	if(IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_NONE)
		ChangeClientTeam(client, CS_TEAM_SPECTATOR);
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	int timeleft;
	GetMapTimeLeft(timeleft);
	
	if(timeleft <= 0) CreateTimer(2.0, Timer_ShowNextMap);
}

public Action Timer_ShowNextMap(Handle timer, any client)
{
	char map[PLATFORM_MAX_PATH];
	GetNextMap(map, sizeof(map));
	GetMapDisplayName(map, map, sizeof(map));
	
	PrintToChatAll("%t", "NextMap", map);
}

public void Hook_OnPressed(const char[] output, int caller, int activator, float delay)
{
	if(spamProtect) return;
	
	// Если кнопку нажал не игрок, выходим.
	if(activator < 1 || activator > MaxClients) return;
	
	char name[128];
	GetEntPropString(caller, Prop_Data, "m_iName", name, sizeof(name));
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == GetClientTeam(activator) && b_ButtonsLog[i]) PrintToChat(i, "%t", "Buttons_Log", activator, caller, name);
	}
	
	spamProtect = true;
	CreateTimer(2.0, AntiSpam_Timer); 
}

public Action Command_Hide(int client, int args)
{
	if(args)
	{
		char tempChar[16];
		GetCmdArg(1, tempChar, sizeof(tempChar));
		
		if(StringToInt(tempChar) < 0 || StringToInt(tempChar) > 9999999)
		{
			PrintToChat(client, "%t", "Distance_Exceeded");
			return Plugin_Handled;
		}
		
		g_iDistance[client] = StringToInt(tempChar);
		g_fDistance[client] = Pow(float(g_iDistance[client]), 2.0);

		PrintToChat(client, "%t", "CustomDistance_Chat", g_iDistance[client]);
	}
	else ShowHideMenu(client);
	
	return Plugin_Handled;
}

public Action Command_Hideall(int client, int args)
{
	g_bHideAll[client] = !g_bHideAll[client];
	
	if(g_bHideAll[client]) PrintToChat(client, "%t", "Hideall_Enabled");
	else PrintToChat(client, "%t", "Hideall_Disabled");
	
	return Plugin_Handled;
}

public Action Command_BBan(int client, int args)
{
	if(!args)
	{
		PrintToChat(client, "Введите имя игрока!");
		return Plugin_Handled;
	}
	
	char tempArg[128];
	GetCmdArg(1, tempArg, sizeof(tempArg));
	
	int target = FindTarget(client, tempArg);
	
	if(target == -1) return Plugin_Handled;
	
	b_ButtonsBan[target] = !b_ButtonsBan[target];
	
	if(b_ButtonsBan[target]) PrintToChatAll("%t", "Buttons_Ban", client, target);
	else PrintToChatAll("%t", "Buttons_Unban", client, target);
	
	return Plugin_Handled;
}

public Action Command_Extend(int client, int args)
{
	if(args)
	{
		if(CheckCommandAccess(client, "", ADMFLAG_BAN, true))
		{
			char tempArg[32];
			GetCmdArg(1, tempArg, sizeof(tempArg));
			
			int addTime = StringToInt(tempArg);
			
			int time = GetConVarInt(h_TimeLimit);
			SetConVarInt(h_TimeLimit, time + addTime);
			
			int timeleft;
			GetMapTimeLeft(timeleft);
			
			char timeLeftChar[32];
			if(timeleft > 0) Format(timeLeftChar, sizeof(timeLeftChar), "%d:%02d", timeleft / 60, timeleft % 60);
			else Format(timeLeftChar, sizeof(timeLeftChar), "0:0");

			if(addTime >= 0) PrintToChatAll("%t", "Admin_Extend_Map", client, addTime, timeLeftChar);
			else PrintToChatAll("%t", "Admin_Reduce_Map", client, addTime - (addTime * 2), timeLeftChar);
		}
		else PrintToChat(client, "%t", "Dont_Have_Permission");
	
		return Plugin_Handled;
	}
	
	// Если голосование недавно было, выходим.
	if(voteTimeout)
	{
		PrintToChat(client, "%t", "Vote_Unavailable");
		return Plugin_Handled;
	}
	// Или если достигнуто максимальное количество продлений, выходим.
	else if(extendsCount == 2)
	{
		PrintToChat(client, "%t", "Max_Extends");
		return Plugin_Handled;
	}
	// Или если голосование уже началось, выходим.
	else if(voteStarted)
	{
		PrintToChat(client, "%t", "Already_Vote");
		return Plugin_Handled;
	}
	
	// Получаем количество игроков на сервере.
	int activeClients = GetClientCount();
	
	// Если игроков меньше 15, выходим.
	if(activeClients < 15)
	{
		PrintToChat(client, "%t", "Need_More_Players");
		return Plugin_Handled;
	}
	
	// Рассчитываем необходимое количество голосов (40%).
	float fNeedVotes = float(activeClients) / 10 * 4;
	
	// Переводим float в int для удобства.
	int needVotes = RoundToZero(fNeedVotes);

	// Вычисляем количество проголосовавших игроков.
	int alreadyVotedPlayersCount;
	
	for(int i = 1; i <= MaxClients; i++) if(extendVotedPlayers[i]) alreadyVotedPlayersCount++;

	// Если игрок уже проголосовал
	if(extendVotedPlayers[client])
	{
		// Уведомляем и выходим.
		PrintToChat(client, "%t", "You_Already_Voted", alreadyVotedPlayersCount, needVotes);
		return Plugin_Handled;
	}
	
	// Сохраняем голос игрока.
	extendVotedPlayers[client] = true;
	
	// Пишем в чат уведомление (+ 1 т.к. во время выполнения цикла голос игрока еще не засчитан).
	PrintToChatAll("%t", "Successfully_Voted", client, alreadyVotedPlayersCount +1, needVotes);
	
	if(alreadyVotedPlayersCount +1 == needVotes)
	{
		voteStarted = true;
		
		PrintToChatAll("%t", "Vote_Starting");
		
		CreateTimer(5.0, Timer_ExtendVote);
	}
	
	// Завершаем выполнение команды.
	return Plugin_Handled;
}

public Action Timer_ExtendVote(Handle timer)
{
	ShowExtendVoteMenu();
}

void ShowExtendVoteMenu()
{
	char title[96], yesTranslate[96], noTranslate[96];
	Format(title, sizeof(title), "%t", "Extend_VoteMenu_Title");
	Format(yesTranslate, sizeof(yesTranslate), "%t", "Yes");
	Format(noTranslate, sizeof(noTranslate), "%t", "No");

	Menu extendvotemenu = new Menu(Handle_ExtendVoteMenu);
	
	extendvotemenu.SetTitle(title);
	extendvotemenu.AddItem("Да", yesTranslate);
	extendvotemenu.AddItem("Нет", noTranslate);
	extendvotemenu.ExitButton = false;
	extendvotemenu.DisplayVoteToAll(20);
}

public int Handle_ExtendVoteMenu(Menu extendvotemenu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
	{
		delete extendvotemenu;
	}
	else if(action == MenuAction_VoteEnd)
	{
		if(param1 == 0)
		{
			int time = GetConVarInt(h_TimeLimit);
			SetConVarInt(h_TimeLimit, time + 15);

			int timeleft;
			GetMapTimeLeft(timeleft);
			
			char timeLeftChar[32];
			Format(timeLeftChar, sizeof(timeLeftChar), "%d:%02d", timeleft / 60, timeleft % 60);
			
			PrintToChatAll("%t", "Successfully_Extended", timeLeftChar);
			
			extendsCount++;
		}
		else PrintToChatAll("%t", "Vote_Failed");
		
		voteTimeout = true;
		voteStarted = false;
		
		CreateTimer(300.0, Timer_ExtendVoteTimeOut);
	}
}

public Action Timer_ExtendVoteTimeOut(Handle timer)
{
	voteTimeout = false;
	
	for(int i = 1; i <= MaxClients; i++) extendVotedPlayers[i] = false;
}

public Action Command_Spec(int client, int args)
{
	if(args)
	{
		int team = GetClientTeam(client);
		
		if(team == CS_TEAM_T || team == CS_TEAM_CT)
		{
			PrintToChat(client, "%t", "Cant_Spec");
			return Plugin_Handled;
		}
	
		char nickName[128];
		GetCmdArg(1, nickName, sizeof(nickName));
		
		int target = FindTarget(client, nickName, false, false);
		if(target == -1) return Plugin_Handled;
		
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", target);
	}
	else PrepareToSpec(client);
	
	return Plugin_Handled;
}

public Action Command_Afk(int client, int args)
{
	PrepareToSpec(client);
	
	return Plugin_Handled;
}

void PrepareToSpec(int client)
{
	int team = GetClientTeam(client);
	
	// Если игрок уже находится в наблюдателях:
	if(team == CS_TEAM_NONE || team == CS_TEAM_SPECTATOR)
	{
		PrintToChat(client, "%t", "Already_Spec");
		return;
	}
	// Или если в команде зомби мало игроков:
	else if(team == CS_TEAM_T && GetTeamClientCount(2) <= 6)
	{
		PrintToChat(client, "%t", "Few_Zombies");
		return;
	}
	// Или если игрок - человек, и зомби уже есть:
	else if(team == CS_TEAM_CT && GetTeamClientCount(2) > 0)
	{
		PrintToChat(client, "%t", "Infect_Or_Wait");
		return;
	}
	// Иначе, если зомби еще нет, или игрок - зомби:
	else
	{
		CreateTimer(15.0, Timer_MoveToSpec, client, TIMER_FLAG_NO_MAPCHANGE);
		PrintToChat(client, "%t", "Wait_MoveToSpec");
	}
}

void ShowHideMenu(int client)
{
	SetGlobalTransTarget(client);

	char hideTranslate[128], CustomDistanceTranslate[128], DistanceTranslate[128], hideAllTranslate[128], hideLeaderTranslate[128], hideValue[64];
	
	if(g_bHideEnabled[client]) Format(hideTranslate, sizeof(hideTranslate), "%t %t", "Enable_Hide", "On");
	else Format(hideTranslate, sizeof(hideTranslate), "%t %t", "Enable_Hide", "Off");
	
	Format(CustomDistanceTranslate, sizeof(CustomDistanceTranslate), "%t", "Custom_Distance");
	
	if(g_iDistance[client] == 50) Format(DistanceTranslate, sizeof(DistanceTranslate), "%t %t (%i)", "Distance", "Distance_Very_Close", g_iDistance[client]);
	else if(g_iDistance[client] == 200) Format(DistanceTranslate, sizeof(DistanceTranslate), "%t %t (%i)", "Distance", "Distance_Close", g_iDistance[client]);
	else if(g_iDistance[client] == 400) Format(DistanceTranslate, sizeof(DistanceTranslate), "%t %t (%i)", "Distance", "Distance_Normal", g_iDistance[client]);
	else if(g_iDistance[client] == 800) Format(DistanceTranslate, sizeof(DistanceTranslate), "%t %t (%i)", "Distance", "Distance_Far", g_iDistance[client]);
	else if(g_iDistance[client] == 1600) Format(DistanceTranslate, sizeof(DistanceTranslate), "%t %t (%i)", "Distance", "Distance_Very_Far", g_iDistance[client]);
	else Format(DistanceTranslate, sizeof(DistanceTranslate), "%t %t (%i)", "Distance", "Distance_Custom", g_iDistance[client]);
	
	if(g_bHideAll[client]) Format(hideAllTranslate, sizeof(hideAllTranslate), "%t %t", "Hide_All", "On");
	else Format(hideAllTranslate, sizeof(hideAllTranslate), "%t %t", "Hide_All", "Off");
	
	if(g_bHideLeader[client]) Format(hideLeaderTranslate, sizeof(hideLeaderTranslate), "%t %t", "Hide_Leader", "On");
	else Format(hideLeaderTranslate, sizeof(hideLeaderTranslate), "%t %t", "Hide_Leader", "Off");
	
	Format(hideValue, sizeof(hideValue), "%i", g_iDistance[client]);
	
	Menu hide = new Menu(HideHandler);
	
	hide.SetTitle("%T", "Hide_Menu_Title", client);
	hide.AddItem("Change", hideTranslate);
	hide.AddItem("", CustomDistanceTranslate, ITEMDRAW_DISABLED);
	hide.AddItem(hideValue, DistanceTranslate);
	hide.AddItem("HideAll", hideAllTranslate);
	hide.AddItem("HideLeader", hideLeaderTranslate);

	hide.Display(client, 180);
}

public int HideHandler(Menu hide, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) 
	{
		char item[16];
		hide.GetItem(option, item, sizeof(item));
		
		if(StrEqual(item, "Change")) g_bHideEnabled[client] = !g_bHideEnabled[client];
		else if(StrEqual(item, "HideAll")) g_bHideAll[client] = !g_bHideAll[client];
		else if(StrEqual(item, "HideLeader")) g_bHideLeader[client] = !g_bHideLeader[client];
		else
		{
			int distance = StringToInt(item);
			
			if(distance == 50) g_iDistance[client] = 200;
			else if(distance == 200) g_iDistance[client] = 400;
			else if(distance == 400) g_iDistance[client] = 800;
			else if(distance == 800) g_iDistance[client] = 1600;
			else if(distance == 1600) g_iDistance[client] = 50;
			else g_iDistance[client] = 50;
			
			g_fDistance[client] = Pow(float(g_iDistance[client]), 2.0);
		}

		ShowHideMenu(client);
	}
	else if(action == MenuAction_End) delete hide;
}

public Action Timer_Hide(Handle timer)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(g_bHideAll[client]) continue;
		
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			for(int target = 1; target <= MaxClients; target++)
			{
				if(IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(client) == GetClientTeam(target) && client != target && g_bHideEnabled[client])
				{
					GetClientAbsOrigin(client, absClient);
					GetClientAbsOrigin(target, absTarget);
				
					fDistance = GetVectorDistance(absClient, absTarget, true);
					
					if(fDistance < g_fDistance[client]) enableHide[client][target] = true;
					else enableHide[client][target] = false;
				}
				else enableHide[client][target] = false;
			}
		}
	}
}

public Action AntiSpam_Timer(Handle timer)
{
	spamProtect = false;
}

public Action Timer_MoveToSpec(Handle timer, any client)
{
	if(!IsClientInGame(client)) return;
	
	else if(GetClientTeam(client) == CS_TEAM_T && GetTeamClientCount(2) <= 6)
	{
		PrintToChat(client, "%t", "Few_Zombies");
		return;
	}
	
	ChangeClientTeam(client, CS_TEAM_SPECTATOR);
	PrintToChat(client, "%t", "Successfully_MovedToSpec");
}

public Action Hook_SetTransmit(int target, int client)
{
	if(g_bHideAll[client])
	{
		if(GetClientTeam(client) == GetClientTeam(target) && client != target)
		{
			if(target != GetClientCommander())
				return Plugin_Handled;
			else if(target == GetClientCommander() && g_bHideLeader[client])
				return Plugin_Handled;
		}		
	}
	
	else if(enableHide[client][target])
	{
		if(target != GetClientCommander())
			return Plugin_Handled;
		else if(target == GetClientCommander() && g_bHideLeader[client])
			return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Hook_Use(int entity, int client)
{
	if(b_ButtonsBan[client])
	{
		PrintHintText(client, "%t", "Cant_Press_Buttons");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action SoundHook_Normal(int clients[64], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags)
{
	if(StrContains(sample, "player/headshot") != -1)
	{
		volume = 0.1;
		return Plugin_Changed;
	}
	else if(StrContains(sample, "flesh_impact_bullet") != -1)
	{
		volume = 0.3;
		return Plugin_Changed;
	}
	else if(StrContains(sample, "footsteps") != -1 || StrContains(sample, "land") != -1)
	{
		int target;
		
		for (int i = 0; i < numClients; i++) 
		{ 
			target = clients[i]; 
			
			if(entity && entity <= MaxClients)
			{
				if(enableHide[target][entity]) return Plugin_Handled;
				
				else if(g_bHideAll[target] && target != entity && GetClientTeam(target) == GetClientTeam(entity)) return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action Timer_TimeLeft(Handle timer)
{
	int timeleft;
	GetMapTimeLeft(timeleft);
	
	char msg[32];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientButtons(i) & IN_SCORE)
		{
			SetGlobalTransTarget(i);
			
			if(timeleft > 0) Format(msg, sizeof(msg), "%t", "Timeleft", timeleft / 60, timeleft % 60);
			else Format(msg, sizeof(msg), "%t", "Timeleft_LastRound");
			
			SetHudTextParamsEx(0.01, 0.37, 1.0, {255, 255, 255, 255}, {0, 0, 0, 255}, 0, 0.0, 0.0, 0.0);
			ShowHudText(i, 2, msg);
		}
	}
}

public Action Button_F4(int client, const char[] command, int args)
{
   ShowMenu(client);
   return Plugin_Continue;
}

public Action Command_Menu(int client, int args)
{
	ShowMenu(client);
	return Plugin_Handled;
}

ShowMenu(client)
{
	SetGlobalTransTarget(client);

	char rtv[128], nominate[128], nextmap[128], zbuy[128], music[128], stopsound[128], ztele[128], zvolume[128], hide[128], extend[128], nomlist[128], exlist[128], noshake[128], timeleft[128],
	selfmute[128], selfunmute[128], spec[128], guns[128], admins[128], hud[128], settings[128], votecommander[128], tp[128], zclass[128], zstats[128], top[128], vip[128];
	
	Format(rtv, sizeof(rtv), "%t", "rtv");
	Format(nominate, sizeof(nominate), "%t", "nominate");
	Format(nextmap, sizeof(nextmap), "%t", "nextmap");
	Format(zbuy, sizeof(zbuy), "%t", "zbuy");
	Format(music, sizeof(music), "%t", "music");
	Format(stopsound, sizeof(stopsound), "%t", "stopsound");
	Format(ztele, sizeof(ztele), "%t", "ztele");
	Format(zvolume, sizeof(zvolume), "%t", "zvolume");
	Format(hide, sizeof(hide), "%t", "hide");
	Format(extend, sizeof(extend), "%t", "extend");
	Format(nomlist, sizeof(nomlist), "%t", "nomlist");
	Format(exlist, sizeof(exlist), "%t", "exlist");
	Format(noshake, sizeof(noshake), "%t", "noshake");
	Format(timeleft, sizeof(timeleft), "%t", "timeleft");
	Format(selfmute, sizeof(selfmute), "%t", "selfmute");
	Format(selfunmute, sizeof(selfunmute), "%t", "selfunmute");
	Format(spec, sizeof(spec), "%t", "spec");
	Format(guns, sizeof(guns), "%t", "guns");
	Format(admins, sizeof(admins), "%t", "admins");
	Format(hud, sizeof(hud), "%t", "hud");
	Format(settings, sizeof(settings), "%t", "settings");
	Format(votecommander, sizeof(votecommander), "%t", "votecommander");
	Format(tp, sizeof(tp), "%t", "tp");
	Format(zclass, sizeof(zclass), "%t", "zclass");
	Format(zstats, sizeof(zstats), "%t", "zstats");
	Format(top, sizeof(top), "%t", "top");
	Format(vip, sizeof(vip), "%t", "vip");
	
	Menu menu = new Menu(MenuHandler);
	menu.SetTitle("%T", "Commands_Menu_Title", client);
	menu.AddItem("rtv", rtv);
	menu.AddItem("nominate", nominate);
	menu.AddItem("nextmap", nextmap);
	menu.AddItem("!zbuy", zbuy);
	menu.AddItem("!music", music);
	menu.AddItem("!stopsound", stopsound);
	menu.AddItem("!ztele", ztele);
	menu.AddItem("!zvolume", zvolume);
	menu.AddItem("!hide", hide);
	menu.AddItem("!extend", extend);
	menu.AddItem("!nomlist", nomlist);
	menu.AddItem("!exlist", exlist);
	menu.AddItem("!noshake", noshake);
	menu.AddItem("!timeleft", timeleft);
	menu.AddItem("!sm", selfmute);
	menu.AddItem("!su", selfunmute);
	menu.AddItem("!spec", spec);
	menu.AddItem("!guns", guns);
	menu.AddItem("!admins", admins);
	menu.AddItem("!hud", hud);
	menu.AddItem("!settings", settings);
	menu.AddItem("!votecommander", votecommander);
	menu.AddItem("!tp", tp);
	menu.AddItem("!zclass", zclass);
	menu.AddItem("!zstats", zstats);
	menu.AddItem("!top", top);
	menu.AddItem("!vip", vip);

	menu.Display(client, 180);
}

public MenuHandler(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) 
	{
		char item[64];
		GetMenuItem(menu, option, item, sizeof(item));

		FakeClientCommand(client, "say %s", item);
	}
	else if(action == MenuAction_End) delete menu;
}
