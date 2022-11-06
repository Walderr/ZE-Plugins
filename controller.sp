#include <sourcemod>
#include <sdktools>
#include <cstrike>

new checkind[MAXPLAYERS + 1];
new entityind[MAXPLAYERS + 1];
new enthealth[MAXPLAYERS + 1];
new Handle:entname = INVALID_HANDLE;
new Handle:entclass = INVALID_HANDLE;

public Plugin myinfo =
{
	name = "Entity control",
	author = "Walderr",
	description = "Позволяет получать доступ к свойствам энтити",
	version = "0.2.3",
};

public OnPluginStart()
{
	RegAdminCmd("sm_control", Command_sm_control, ADMFLAG_UNBAN);
	RegConsoleCmd("sm_findbutton", Command_FindButton);
	RegAdminCmd("entitylist", GetAllEntity, ADMFLAG_CHEATS);
	RegAdminCmd("aei", Command_AEI, ADMFLAG_CHEATS);
	entname = CreateArray(32, MAXPLAYERS);
	entclass = CreateArray(32, MAXPLAYERS);
}

public Action Command_FindButton(int client, int args)
{
	int id = GetClientAimTarget(client, false);
	
	if(id == -1)
	{
		PrintHintText(client, "Объект не найден!");
		return Plugin_Handled;
	}
	
	char class[MAX_NAME_LENGTH];
	GetEdictClassname(id, class, sizeof(class));
	
	if(!StrEqual(class, "func_button"))
	{
		PrintHintText(client, "Кнопка не найдена!");
		return Plugin_Handled;
	}
	
	char name[MAX_NAME_LENGTH];
	GetEntPropString(id, Prop_Data, "m_iName", name, sizeof(name));
	
	if(StrEqual(name, "")) FormatEx(name, sizeof(name), "Не найдено");
	
	int hid = GetEntProp(id, Prop_Data, "m_iHammerID");
	
	PrintCenterText(client, "Имя: %s\nHammer ID: %i", name, hid);
	
	return Plugin_Handled;
}

public Action Command_sm_control(int client, int args)
{
	checkind[client] = GetClientAimTarget(client, false);
	if(checkind[client] == -1)
	{
		PrintHintText(client, "Объект не найден!");
		return Plugin_Handled;
	}
	entityind[client] = checkind[client];
	enthealth[client] = GetEntProp(entityind[client], Prop_Data, "m_iHealth");
	
	new String:eclass[MAX_NAME_LENGTH + 1];
	GetEdictClassname(entityind[client], eclass, sizeof(eclass));
	if(strcmp(eclass, "weapon") == 1) SetArrayString(entclass, client, "weapon");
	else SetArrayString(entclass, client, eclass);

	new String:ename[MAX_NAME_LENGTH + 1];
	if(StrEqual(eclass, "player")) GetClientName(entityind[client], ename, sizeof(ename));
	else GetEntPropString(entityind[client], Prop_Data, "m_iName", ename, sizeof(ename));
	
	if(StrEqual(ename, "")) ename = "Not Found";
	SetArrayString(entname, client, ename);
	
	int iHid = GetEntProp(checkind[client], Prop_Data, "m_iHammerID");
	
	PrintHintText(client, "Имя: %s\nКласс: %s\nЗдоровье: %i Индекс: %i, %i", ename, eclass, enthealth[client], entityind[client], iHid);
	ShowMainMenu(client);
	return Plugin_Handled;
}

ShowMainMenu(client)
{
	new Handle:mainmenu = CreateMenu(MainCallBack);
	new String:eClassMain[32];
	GetArrayString(entclass, client, eClassMain, sizeof(eClassMain));
	if(StrEqual(eClassMain, "func_door") || StrEqual(eClassMain, "func_door_rotating") || StrEqual(eClassMain, "prop_door_rotating"))
	{
		SetMenuTitle(mainmenu, "Дверь:");
		AddMenuItem(mainmenu, "Open", "Открыть");
		AddMenuItem(mainmenu, "Close", "Закрыть");
		AddMenuItem(mainmenu, "Lock", "Запереть");
		AddMenuItem(mainmenu, "Unlock", "Отпереть");
		AddMenuItem(mainmenu, "SetSpeed", "Установить скорость");
	}
	else if(StrEqual(eClassMain, "func_button") || StrEqual(eClassMain, "func_rot_button"))
	{
		SetMenuTitle(mainmenu, "Кнопка:");
		AddMenuItem(mainmenu, "Press", "Нажать");
		AddMenuItem(mainmenu, "Lock", "Заблокировать");
		AddMenuItem(mainmenu, "Unlock", "Разблокировать");
	}
	else if(StrEqual(eClassMain, "player"))
	{
		SetMenuTitle(mainmenu, "Игрок:");
		AddMenuItem(mainmenu, "BecomeRagdoll", "Отправить в Вальхаллу");
	}
	else if(StrEqual(eClassMain, "func_breakable"))
	{
		SetMenuTitle(mainmenu, "Разрушаемый предмет:");
		AddMenuItem(mainmenu, "Break", "Разрушить");
		AddMenuItem(mainmenu, "Use", "Активировать");
	}
	else if(StrEqual(eClassMain, "func_movelinear"))
	{
		SetMenuTitle(mainmenu, "Линейный транспорт:");
		AddMenuItem(mainmenu, "Open", "Вперед");
		AddMenuItem(mainmenu, "Close", "Назад");
		AddMenuItem(mainmenu, "SetSpeed", "Установить скорость");
	}
	else if(StrEqual(eClassMain, "func_tanktrain") || StrEqual(eClassMain, "func_tracktrain"))
	{
		SetMenuTitle(mainmenu, "Поезд:");
		AddMenuItem(mainmenu, "Toggle", "Пауза");
		AddMenuItem(mainmenu, "StartForward", "Старт вперед");
		AddMenuItem(mainmenu, "StartBackward", "Старт назад");
		AddMenuItem(mainmenu, "Reverse", "Реверс");
		AddMenuItem(mainmenu, "SetSpeed", "Установить скорость");
	}
	else if(StrEqual(eClassMain, "func_physbox") || StrEqual(eClassMain, "func_physbox_multiplayer"))
	{
		SetMenuTitle(mainmenu, "Физ. бокс:");
		AddMenuItem(mainmenu, "Sleep", "Усыпить");
		AddMenuItem(mainmenu, "Wake", "Разбудить");
		AddMenuItem(mainmenu, "DisableMotion", "Отключить движение");
		AddMenuItem(mainmenu, "EnableMotion", "Включить движение");
		AddMenuItem(mainmenu, "Break", "Разрушить");
		AddMenuItem(mainmenu, "Disable", "Отключить");
		AddMenuItem(mainmenu, "Enable", "Включить");
	}
	else if(StrEqual(eClassMain, "func_wall_toggle"))
	{
		SetMenuTitle(mainmenu, "Стена:");
		AddMenuItem(mainmenu, "Toggle", "Переключить");
	}
	else if(StrEqual(eClassMain, "func_rotating"))
	{
		SetMenuTitle(mainmenu, "Поворотный механизм:");
		AddMenuItem(mainmenu, "Toggle", "Пауза");
		AddMenuItem(mainmenu, "StartForward", "Старт вперед");
		AddMenuItem(mainmenu, "StartBackward", "Старт назад");
		AddMenuItem(mainmenu, "Reverse", "Реверс");
		AddMenuItem(mainmenu, "SetSpeed", "Установить скорость");
		AddMenuItem(mainmenu, "StopAtStartPos", "Остановить в позиции старта");
	}
	else if(StrEqual(eClassMain, "func_brush"))
	{
		SetMenuTitle(mainmenu, "Браш:");
		AddMenuItem(mainmenu, "Enable", "Включить");
		AddMenuItem(mainmenu, "Disable", "Выключить");
		AddMenuItem(mainmenu, "Toggle", "Переключить");
	}
	else if(StrEqual(eClassMain, "prop_physics") || StrEqual(eClassMain, "prop_physics_multiplayer"))
	{
		SetMenuTitle(mainmenu, "Физ. проп:");
		AddMenuItem(mainmenu, "EnableMotion", "Включить движение");
		AddMenuItem(mainmenu, "DisableMotion", "Отключить движение");
		AddMenuItem(mainmenu, "Break", "Сломать");
	}
	else if(StrEqual(eClassMain, "prop_dynamic"))
	{
		SetMenuTitle(mainmenu, "Дин. проп:");
		AddMenuItem(mainmenu, "EnableCollision", "Включить коллизию");
		AddMenuItem(mainmenu, "DisableCollision", "Отключить коллизию");
		AddMenuItem(mainmenu, "FadeAndKill", "Испарить");
		AddMenuItem(mainmenu, "Break", "Сломать");
	}
	else if(StrEqual(eClassMain, "chicken"))
	{
		SetMenuTitle(mainmenu, "Курица:");
		AddMenuItem(mainmenu, "Break", "Убить");
	}
	else SetMenuTitle(mainmenu, "Неизвестный класс:");
	AddMenuItem(mainmenu, "SetHealth", "Установить здоровье");
	AddMenuItem(mainmenu, "AddHealth", "Добавить здоровье");
	AddMenuItem(mainmenu, "RemoveHealth", "Удалить здоровье");
	AddMenuItem(mainmenu, "Kill", "Удалить");
	AddMenuItem(mainmenu, "ClearParent", "Удалить родителя");
	AddMenuItem(mainmenu, "DisableDraw", "Выключить отрисовку");
	AddMenuItem(mainmenu, "EnableDraw", "Включить отрисовку");
	
	SetMenuExitButton(mainmenu, true);
	DisplayMenu(mainmenu, client, 150);
}
public MainCallBack(Handle:mainmenu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select) 
	{
		decl String:Item[20];
		GetMenuItem(mainmenu, option, Item, sizeof(Item));
		if(StrEqual(Item, "SetHealth") || StrEqual(Item, "AddHealth") || StrEqual(Item, "RemoveHealth")) ShowHealthMenu(client, Item);
		else if(StrEqual(Item, "SetSpeed")) ShowSpeedMenu(client);
		else
		{
			if(entityind[client] <= 0 || !IsValidEdict(entityind[client]))
			{
				PrintToChat(client, "Такой энтити больше нет в этом бренном мире!");
				return;
			}
			AcceptEntityInput(entityind[client], Item);
			ShowMainMenu(client);
		}
		ShowLog(client, Item);
	}
	if(action == MenuAction_End) 
	{
		CloseHandle(mainmenu); 
	}
}

ShowHealthMenu(client, String:Item[])
{
	new Handle:hpmenu = CreateMenu(HealthCallback);
	if(StrEqual(Item, "SetHealth")) SetMenuTitle(hpmenu, "Установить здоровье:");
	else if(StrEqual(Item, "AddHealth")) SetMenuTitle(hpmenu, "Добавить здоровье:");
	else SetMenuTitle(hpmenu, "Удалить здоровье:");

	AddMenuItem(hpmenu, "0", "0");
	AddMenuItem(hpmenu, "1", "1");
	AddMenuItem(hpmenu, "5", "5");
	AddMenuItem(hpmenu, "10", "10");
	AddMenuItem(hpmenu, "25", "25");
	AddMenuItem(hpmenu, "50", "50");
	AddMenuItem(hpmenu, "100", "100");
	AddMenuItem(hpmenu, "250", "250");
	AddMenuItem(hpmenu, "500", "500");
	AddMenuItem(hpmenu, "1000", "1000");
	AddMenuItem(hpmenu, "5000", "5000");
	AddMenuItem(hpmenu, "10000", "10000");
	
	SetMenuExitButton(hpmenu, true);
	DisplayMenu(hpmenu, client, 150);
}
public HealthCallback(Handle:hpmenu, MenuAction:action, client, option)
{
	if (action == MenuAction_Select) 
	{ 
		new hpent = GetEntProp(entityind[client], Prop_Data, "m_iHealth");
		
		new String:newhp[8];
		GetMenuItem(hpmenu, option, newhp, sizeof(newhp));
		new newhpint;
		newhpint = StringToInt(newhp);
		
		decl String:hpOpt[64];
		GetMenuTitle(hpmenu, hpOpt, sizeof(hpOpt));
		if(StrEqual(hpOpt, "Установить здоровье:")) SetEntProp(entityind[client], Prop_Data, "m_iHealth", newhpint);
		if(StrEqual(hpOpt, "Добавить здоровье:")) SetEntProp(entityind[client], Prop_Data, "m_iHealth", hpent + newhpint);
		if(StrEqual(hpOpt, "Удалить здоровье:")) SetEntProp(entityind[client], Prop_Data, "m_iHealth", hpent - newhpint);
		
		ShowMainMenu(client);
	}
	if (action == MenuAction_End)
	{
		CloseHandle(hpmenu); 
	}
}

ShowSpeedMenu(client)
{
	new Handle:spdmenu = CreateMenu(SpeedCallback);
	SetMenuTitle(spdmenu, "Установить скорость:");
	AddMenuItem(spdmenu, "1.0", "1.0");
	AddMenuItem(spdmenu, "5.0", "5.0");
	AddMenuItem(spdmenu, "10.0", "10.0");
	AddMenuItem(spdmenu, "25.0", "25.0");
	AddMenuItem(spdmenu, "50.0", "50.0");
	AddMenuItem(spdmenu, "100.0", "100.0");
	AddMenuItem(spdmenu, "200.0", "200.0");
	AddMenuItem(spdmenu, "500.0", "500.0");
	AddMenuItem(spdmenu, "1000.0", "1000.0");
	AddMenuItem(spdmenu, "10000.0", "10000.0");
	SetMenuExitButton(spdmenu, true);
	DisplayMenu(spdmenu, client, 150);
}
public SpeedCallback(Handle:spdmenu, MenuAction:action, client, option)
{
	if (action == MenuAction_Select) 
	{ 
		new Float:spdent = GetEntPropFloat(entityind[client], Prop_Data, "m_flSpeed");
		decl String:sspd[8];
		GetMenuItem(spdmenu, option, sspd, sizeof(sspd));
		decl Float:fspd;
		fspd = StringToFloat(sspd);
		PrintToChat(client, "Предыдущая скорость: %f", spdent);
		SetEntPropFloat(entityind[client], Prop_Data, "m_flSpeed", fspd);
		ShowMainMenu(client);
	}
	if (action == MenuAction_End)
	{
		CloseHandle(spdmenu); 
	}
}

public Action:GetAllEntity(client, args)
{	
	new String:getentclass[64], String:getentname[64];
	for(new i = 1; i < GetEntityCount(); i++)
	{
		if(!IsValidEdict(i)) continue;
		GetEdictClassname(i, getentclass, sizeof(getentclass));
		GetEntPropString(i, Prop_Data, "m_iName", getentname, sizeof(getentname));
		PrintToConsole(client, "Entity id: #%i | %s | %s", i, getentclass, getentname);
	}
	return Plugin_Handled;
}

public Action:Command_AEI(client, args)
{	
	new String:getindex[4], String:getinput[32], ind=0;
	GetCmdArg(1, getindex, sizeof(getindex));
	GetCmdArg(2, getinput, sizeof(getinput));
	
	if(StringToInt(getindex) == -1) ind = client;
	else ind = StringToInt(getindex);
	
	if(ind <= 0 || !IsValidEdict(ind))
	{
		PrintToChat(client, "Такой энтити больше нет в этом бренном мире!");
		return Plugin_Handled;
	}
	AcceptEntityInput(ind, getinput);
	return Plugin_Handled;
}

ShowLog(client, String:Item[])
{
	new String:logentname[32], String:logentclass[32];
	GetArrayString(entname, client, logentname, sizeof(logentname));
	GetArrayString(entclass, client, logentclass, sizeof(logentclass));
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && CheckCommandAccess(i, "sm_ban", ADMFLAG_UNBAN, true) && !IsFakeClient(i))
		{
			PrintToConsole(i, " \x09[CONTROLLER] \x07%N \x09использовал\x07 %s\x09 на: \x07%s\x09 (%i), \x0D%s", client, Item, logentname, entityind[client], logentclass);
		}
	}
}
