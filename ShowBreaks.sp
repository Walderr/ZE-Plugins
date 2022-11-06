#include <ClientPrefs>

bool spam;
bool b_BreaksLog[MAXPLAYERS+1];

Handle h_BreaksInChat = INVALID_HANDLE;

public Plugin myinfo =
{
    name = "Show Breaks",
    author = "Walderr",
    description = "Показывает кто что сломал",
    version = "1.1",
};

public OnPluginStart()
{
	HookEvent("break_breakable", Event_Break_Breakable);
	
	h_BreaksInChat = RegClientCookie("BreaksInChat", "Выводить в чат информацию о разрушении предметов", CookieAccess_Public);
	SetCookieMenuItem(BreaksCookieHandler, 0, "Admin Logs");
}

public void BreaksCookieHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if(action == CookieMenuAction_SelectOption)
	{
		if(GetUserFlagBits(client) & ADMFLAG_GENERIC)
			DisplayBreaksMenu(client);
		else
			PrintToChat(client, "У вас нет доступа к этому меню!");
	}
}

void DisplayBreaksMenu(int client)
{
	Menu breakMenu = new Menu(BreakMenuHandler);
	
	breakMenu.SetTitle("Выводить информацию о разрушении предметов?");
	
	if(b_BreaksLog[client])
	{
		breakMenu.AddItem("1", "Да", ITEMDRAW_DISABLED);
		breakMenu.AddItem("0", "Нет");
	}
	else
	{
		breakMenu.AddItem("1", "Да");
		breakMenu.AddItem("0", "Нет", ITEMDRAW_DISABLED);
	}
	
	breakMenu.ExitBackButton = true;
	breakMenu.Display(client, 180);
}

public int BreakMenuHandler(Menu breakMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) 
	{
		if(option == 0) b_BreaksLog[client] = true;
		else if(option == 1) b_BreaksLog[client] = false;
		
		DisplayBreaksMenu(client);
	}
	else if(action == MenuAction_Cancel) 
	{
		if(option == MenuCancel_ExitBack) ShowCookieMenu(client);
	}
	else if(action == MenuAction_End) delete breakMenu;
}

public void OnClientCookiesCached(int client)
{
	if(IsFakeClient(client)) return;
	
	char tempChar[8];
	GetClientCookie(client, h_BreaksInChat, tempChar, sizeof(tempChar));
	
	if(StrEqual(tempChar, "0")) b_BreaksLog[client] = false;
	else b_BreaksLog[client] = true;
}

public void OnClientDisconnect(int client)
{
	if(AreClientCookiesCached(client))
	{
		char tempChar[8];
		Format(tempChar, sizeof(tempChar), "%i", b_BreaksLog[client]);
		SetClientCookie(client, h_BreaksInChat, tempChar);
	}
}

public Action Event_Break_Breakable(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client < 1 || client > MaxClients) return;
	
	if(spam) return;

	int index = GetEventInt(event, "entindex");
	
	char entname[64];
	GetEntPropString(index, Prop_Data, "m_iName", entname, sizeof(entname));
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && CheckCommandAccess(i, "", ADMFLAG_CHAT, true) && b_BreaksLog[i])
		{
			PrintToChat(i, " \x03[SB] \x07%N \x01разрушил предмет \x07%i %s", client, index, entname);
			spam = true;
			CreateTimer(3.0, Timer_Spam);
		}
	}
	return;
}

public Action:Timer_Spam(Handle timer) 
{ 
	spam = false;
}