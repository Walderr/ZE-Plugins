public Plugin:myinfo =
{
	name = "Admins List",
	author = "Walderr",
	description = "Admins List",
	version = "1.1",
};

public OnPluginStart()
{
	RegConsoleCmd("sm_admins", Command_Admins, "Показать список администраторов");
}

public Action Command_Admins(int client, int args)
{
	ShowAdminsList(client);
}

ShowAdminsList(client)
{
	new Handle:listmenu = CreateMenu(ListCallBack);

	SetMenuTitle(listmenu, "Список Администраторов:");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && CheckCommandAccess(i, "", ADMFLAG_GENERIC, true))
		{
			char Name[64] = "";
			
			if(CheckCommandAccess(i, "", ADMFLAG_ROOT, true)) Format(Name, 64, "%N [Технический администратор]", i);
			else if(CheckCommandAccess(i, "", ADMFLAG_CHEATS, true)) Format(Name, 64, "%N [Старший администратор]", i);
			else if(CheckCommandAccess(i, "", ADMFLAG_UNBAN, true)) Format(Name, 64, "%N [Администратор]", i);
			else if(CheckCommandAccess(i, "", ADMFLAG_BAN, true)) Format(Name, 64, "%N [Младший администратор]", i);
			else if(CheckCommandAccess(i, "", ADMFLAG_GENERIC, true)) Format(Name, 64, "%N [Модератор]", i);
			
			char index[64] = "";
			Format(index, 64, "%i", i);
			
			AddMenuItem(listmenu, index, Name);
		}
	}
	
	SetMenuExitButton(listmenu, true);
	DisplayMenu(listmenu, client, 90);
}

public ListCallBack(Handle:listmenu, MenuAction:action, client, option) {
	if(action == MenuAction_Select) 
	{
		char item[8];
		GetMenuItem(listmenu, option, item, sizeof(item));
		
		int index = StringToInt(item);
		
		ShowAdminInfo(client, index);
	}
	if(action == MenuAction_End) 
	{
		CloseHandle(listmenu); 
	}
}

ShowAdminInfo(client, index) {
	new Handle:infomenu = CreateMenu(InfoCallBack);

	if(!IsClientInGame(index))
	{
		PrintToChat(client, "Администратор вышел с сервера.");
		return;
	}
	
	char Name[64] = "";
	Format(Name, 64, "Ник: %N", index);
	
	char Lvl[64] = "";
			
	if(CheckCommandAccess(index, "", ADMFLAG_ROOT, true)) Format(Lvl, 64, "Уровень: [Technical Administrator]");
	else if(CheckCommandAccess(index, "", ADMFLAG_CHEATS, true)) Format(Lvl, 64, "Уровень: [Senior Administrator]");
	else if(CheckCommandAccess(index, "", ADMFLAG_UNBAN, true)) Format(Lvl, 64, "Уровень: [Administrator]");
	else if(CheckCommandAccess(index, "", ADMFLAG_BAN, true)) Format(Lvl, 64, "Уровень: [Junior Administrator]");
	else if(CheckCommandAccess(index, "", ADMFLAG_GENERIC, true)) Format(Lvl, 64, "Уровень: [Moderator]");
	

	SetMenuTitle(infomenu, "Информация об администраторе:");
	
	AddMenuItem(infomenu, "Ник", Name, ITEMDRAW_DISABLED);
	AddMenuItem(infomenu, "Срок", "Срок администрирования: -- месяцев", ITEMDRAW_DISABLED);
	AddMenuItem(infomenu, "Уровень", Lvl, ITEMDRAW_DISABLED);
	AddMenuItem(infomenu, "Онлайн", "Среднее время онлайна: --ч/день", ITEMDRAW_DISABLED);
	AddMenuItem(infomenu, "Репутация", "Репутация: 0");
	AddMenuItem(infomenu, "Сообщение", "Написать сообщение");
	
	SetMenuExitBackButton(infomenu, true);
	SetMenuExitButton(infomenu, true);
	DisplayMenu(infomenu, client, 180);
}

public InfoCallBack(Handle:infomenu, MenuAction:action, client, option) {
	if(action == MenuAction_Select)
	{
		PrintToChat(client, "Work in progress..");
	}
	if(option == MenuCancel_ExitBack)
	{
		ShowAdminsList(client);
	}
	if(action == MenuAction_End) 
	{
		CloseHandle(infomenu); 
	}
}
