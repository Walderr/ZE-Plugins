#include <sourcemod>
#include <sdktools>
#include <adminmenu>

int spamMutes = 4;
bool MuteStatus[MAXPLAYERS+1][MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "Self-Mute",
	author = "Otokiru, IT-KiLLER, Walderr edit",
	description = "Mute player just for you.",
	version = "Original: 1.0 JAZE: 1.1",
	url = "www.xose.net"
}

public void OnPluginStart() 
{	
	LoadTranslations("common.phrases");
	LoadTranslations("SelfMute.phrases");
	RegConsoleCmd("sm_sm", selfMute, "Mute player by typing !selfmute [playername]");
	RegConsoleCmd("sm_selfmute", selfMute, "Mute player by typing !sm [playername]");
	RegConsoleCmd("sm_su", selfUnmute, "Unmute player by typing !su [playername]");
	RegConsoleCmd("sm_selfunmute", selfUnmute, "Unmute player by typing !selfunmute [playername]");
}

public void OnPluginEnd()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		for(int target = 1; target <= MaxClients; target++)
		{
			if(IsClientInGame(client) && IsClientInGame(target))
			{
				SetListenOverride(client, target, Listen_Default);
			}
		}
	}
}

public void OnClientPutInServer(int client)
{
	for (int target = 1; target <= MaxClients; target++)
	{
		MuteStatus[target][client] = false;
		if(target != client && IsClientInGame(target))
		{
			SetListenOverride(target, client, Listen_Default);
		}
	}
}

//====================================================================================================

public Action selfMute(int client, int args)
{
	// Если команда введена из консоли, выходим.
	if(!client) return Plugin_Handled;
	
	if(!args)
	{
		DisplayMuteMenu(client);
		return Plugin_Handled;
	}
	
	char strTarget[MAX_NAME_LENGTH];
	GetCmdArg(1, strTarget, sizeof(strTarget));
	
	if(StrEqual(strTarget, "@me"))
	{
		PrintToChat(client, "%t", "Cannot_Mute_Yourself");
		return Plugin_Handled; 
	}
	
	char strTargetName[MAX_TARGET_LENGTH]; 
	int TargetList[MAXPLAYERS], TargetCount; 
	bool TargetTranslate; 
	
	if ((TargetCount = ProcessTargetString(strTarget, 0, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_BOTS , strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{
		ReplyToTargetError(client, TargetCount); 
		return Plugin_Handled; 
	}

	muteTargetedPlayers(client, TargetList, TargetCount, strTarget);
	return Plugin_Handled;
}

stock void DisplayMuteMenu(int client)
{
	SetGlobalTransTarget(client);
	
	Menu menu = CreateMenu(MenuHandler_MuteMenu);
	menu.SetTitle("%T", "SelfMute_Menu_Title", client);

	// Здесь будут игроки, добавленные в меню.
	bool clientAlreadyListed[MAXPLAYERS+1] = {false,...}; 

	// Убираем клиента из меню.
	clientAlreadyListed[client] = true; 
	
	char strClientID[12];
	char strClientName[50];

	// Добавляем в меню игроков, которые уже кем-то заблокированы.
	for(int target = 1; target <= MaxClients; target++)
	{
		if(IsClientInGame(target) && !clientAlreadyListed[target] && !MuteStatus[client][target] && targetMutes(target, true) > 0 && !IsFakeClient(target))
		{
			if(targetMutes(target, true) < spamMutes)
			{
				FormatEx(strClientName, sizeof(strClientName), "%t", "Menu_Name_Mutes", target, targetMutes(target, true));
			}
			else
			{
				FormatEx(strClientName, sizeof(strClientName), "%t", "Menu_Name_Spamer", target, targetMutes(target, true));
			}
			
			clientAlreadyListed[target] = true;
			IntToString(GetClientUserId(target), strClientID, sizeof(strClientID));
			menu.AddItem(strClientID, strClientName);
		}
	}

	// Добавляем в меню остальных игроков.
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !clientAlreadyListed[i] && !MuteStatus[client][i] && !IsFakeClient(i))
		{
			IntToString(GetClientUserId(i), strClientID, sizeof(strClientID));
			FormatEx(strClientName, sizeof(strClientName), "%N", i);
			menu.AddItem(strClientID, strClientName);
		}
	}

	// Если нет подходящих игроков
	if(menu.ItemCount == 0) 
	{
		PrintToChat(client, "%t", "Could_Not_Mute", clientMutes(client));
		delete(menu);
	}
	// Иначе показываем клиенту меню.
	else DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_MuteMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			char info[32];
			int target;
			
			GetMenuItem(menu, param2, info, sizeof(info));
			int userid = StringToInt(info);
			
			if((target = GetClientOfUserId(userid)) == 0)
			{
				PrintToChat(param1, "%t", "Player_No_Longer_Available");
			}
			else
			{
				// This will be improved in a later update
				int temp[1];
				temp[0] = target;
				muteTargetedPlayers(param1, temp, 1, "");
			}
			
			DisplayMuteMenu(param1);
		}
	}
}

public void muteTargetedPlayers(int client, int[] list, int TargetCount, const char[] filtername)
{
	if(TargetCount == 1)
	{
		int target = list[0];
		if(client == target)
		{
			PrintToChat(client, "%t", "Cannot_Mute_Yourself");
			return;
		}
		SetListenOverride(client, target, Listen_No);
 
		PrintToChat(client, "%t", "Self_Muted", target);
		MuteStatus[client][target] = true;

	} 
	else if(TargetCount > 1)
	{
		char textNames[250];
		int textSize = 0, countTargets = 0;
		int target;
		for(int i = 0; i < TargetCount; i++) 
		{	
			target = list[i];
			if(target == client || MuteStatus[client][target]) continue;
			countTargets++;
			MuteStatus[client][target] = true;
			SetListenOverride(client, target, Listen_No);
			FormatEx(textNames, sizeof(textNames), "%s%s%N", textNames, countTargets==1 ? "" : ", ",  target);
			textSize = strlen(textNames) - textSize;
		}
		if(countTargets > 0) 
		{
			PrintToChat(client, "%t", "Self_Muted_Multi", countTargets , (textSize <= sizeof(textNames) && countTargets <= 14 ) ? textNames : getFilterName(filtername, client));
		}
		else
		{
			PrintToChat(client, "%t", "All_Already_SelfMuted");
		}
	}
}

//====================================================================================================

public Action selfUnmute(int client, int args)
{
	// Если команда введена из консоли, выходим.
	if(!client) return Plugin_Handled;
	
	if(!args)
	{
		DisplayUnMuteMenu(client);
		return Plugin_Handled;
	}
	
	char strTarget[MAX_NAME_LENGTH];
	GetCmdArg(1, strTarget, sizeof(strTarget)); 
	
	if(StrEqual(strTarget, "@me"))
	{
		PrintToChat(client, "%t", "Cannot_UnMute_Yourself");
		return Plugin_Handled; 
	}
	
	char strTargetName[MAX_TARGET_LENGTH]; 
	int TargetList[MAXPLAYERS], TargetCount; 
	bool TargetTranslate; 

	if((TargetCount = ProcessTargetString(strTarget, 0, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_BOTS, strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{
		ReplyToTargetError(client, TargetCount); 
		return Plugin_Handled; 
	}

	unMuteTargetedPlayers(client, TargetList, TargetCount, strTarget);
	return Plugin_Handled;
}

stock void DisplayUnMuteMenu(int client)
{
	SetGlobalTransTarget(client);
	
	Menu menu = CreateMenu(MenuHandler_UnMuteMenu);
	menu.SetTitle("%T", "SelfUnMute_Menu_Title", client);
	
	char strClientID[12];
	char strClientName[50];
	
	for(int target = 1; target <= MaxClients; target++)
	{
		if(client != target && IsClientInGame(target) && MuteStatus[client][target]  && !IsFakeClient(target)) 
		{
			IntToString(GetClientUserId(target), strClientID, sizeof(strClientID));
			FormatEx(strClientName, sizeof(strClientName), "%N (M)", target);
			menu.AddItem(strClientID, strClientName);
		}
	}
	
	if(menu.ItemCount == 0) 
	{
		PrintToChat(client, "%t", "No_Muted_Players");
		delete(menu);
	}
	else
	{
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public int MenuHandler_UnMuteMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete(menu);
		}
		case MenuAction_Select:
		{
			char info[32];
			int target;
			
			GetMenuItem(menu, param2, info, sizeof(info));
			int userid = StringToInt(info);

			if((target = GetClientOfUserId(userid)) == 0)
			{
				PrintToChat(param1, "%t", "Player_No_Longer_Available");
			}
			else
			{
				// This will be improved in a later update
				int temp[1];
				temp[0] = target;
				unMuteTargetedPlayers(param1, temp, 1, "");
			}
			
			DisplayUnMuteMenu(param1);
		}
	}
}

public void unMuteTargetedPlayers(int client, int[] list, int TargetCount, const char[] filtername)
{
	if(TargetCount == 1)
	{
		int target = list[0];
		if(client == target)
		{
			PrintToChat(client, "%t", "Cannot_UnMute_Yourself");
			return;
		}
		SetListenOverride(client, target, Listen_Default);
		PrintToChat(client, "%t", "Self_UnMuted", target);
		MuteStatus[client][target] = false;
	} 
	else if(TargetCount > 1)
	{
		char textNames[250];
		int textSize = 0, countTargets = 0;
		int target;
		for(int i = 0; i < TargetCount; i++) 
		{
			target = list[i];
			if (target == client || !MuteStatus[client][target]) continue;
			countTargets++;
			SetListenOverride(client, target, Listen_Default);
			MuteStatus[client][target] = false;
			FormatEx(textNames, sizeof(textNames), "%s%s%N", textNames, countTargets==1 ? "" : ", ", target);
			textSize = strlen(textNames) - textSize;
		}
		if(countTargets > 0) 
		{
			PrintToChat(client, "%t", "Self_UnMuted_Multi", countTargets , (textSize <= sizeof(textNames) && countTargets <= 14 ) ? textNames : getFilterName(filtername, client));
		}
		else
		{
			PrintToChat(client, "%t", "All_Already_SelfUnMuted");
		}
	}
}

//====================================================================================================

// Checking if a client is admin
stock bool IsPlayerAdmin(int client)
{
	if(CheckCommandAccess(client, "Kick_admin", ADMFLAG_KICK, false))
	{
		return true;
	}
	return false;
}

// Counting how many mutes a client has done.
stock int clientMutes(int client)
{
	int count=0;
	for(int target = 1; target <= MaxClients ; target++)
	{
		if(MuteStatus[client][target]) count++;
	}
	return count;
}

// Counting how many mutes a target has received.
stock int targetMutes(int target, bool massivemute = false)
{
	int count = 0, mutes = 0;
	
	for(int client = 1; client <= MaxClients ; client++)
	{
		if(MuteStatus[client][target] && (massivemute && (mutes=clientMutes(client)) > 0 && mutes <= (MaxClients/2))) count++;
	}
	return count;
}

stock char getFilterName(const char[] filter, int client)
{
	SetGlobalTransTarget(client);
	
	// This will be improved in a later update
	char temp[32];
	if (StrEqual(filter, "@all"))
	{
		FormatEx(temp, sizeof(temp), "%t", "Everyone");
	} 
	else if (StrEqual(filter, "@spec"))
	{
		FormatEx(temp, sizeof(temp), "%t", "Spectators");
	} 
	else if (StrEqual(filter, "@ct"))
	{
		FormatEx(temp, sizeof(temp), "%t", "Counter-Terrorists");
	} 
	else if (StrEqual(filter, "@t"))
	{
		FormatEx(temp, sizeof(temp), "%t", "Terrorists");
	}
	else if (StrEqual(filter, "@dead"))
	{
		FormatEx(temp, sizeof(temp), "%t", "Dead players");
	}
	else if (StrEqual(filter, "@alive"))
	{
		FormatEx(temp, sizeof(temp), "%t", "Alive players");
	}
	else if (StrEqual(filter, "@!me"))
	{
		FormatEx(temp, sizeof(temp), "%t", "Everyone except me");
	}
	else if (StrEqual(filter, "@admins"))
	{
		FormatEx(temp, sizeof(temp), "%t", "Admins");
	}
	else
	{
		FormatEx(temp, sizeof(temp), "%s", filter);
	}
	return temp;
}
