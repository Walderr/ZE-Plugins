#include <cstrike>
#include <ClientPrefs>
#include <sourcecomms>

// Настройки
int hintsCount = 13;			// Количество строк-подсказок.
float hintsInterval = 90.0;	// Время между сообщениями
//==========

int seconds;
Handle countdownTimer = INVALID_HANDLE;

int currentHint = 1;

int lastInterlocutor[MAXPLAYERS+1];

char prefix[MAXPLAYERS+1][32];
char prefixColor[MAXPLAYERS+1][4];
char nameColor[MAXPLAYERS+1][4];
char textColor[MAXPLAYERS+1][4];
char adminPrefix[MAXPLAYERS+1][32];
bool disableAdminPrefix[MAXPLAYERS+1];

bool isWaitPrefix[MAXPLAYERS+1];

Handle h_prefixCookie = INVALID_HANDLE;
Handle h_prefixColorCookie = INVALID_HANDLE;
Handle h_nameColorCookie = INVALID_HANDLE;
Handle h_textColorCookie = INVALID_HANDLE;
Handle h_disableAdminPrefixCookie = INVALID_HANDLE;

char cWhite[32] = 		"\x01",
	cTeamColor[32] = 	"\x03",
	cDarkred[32] = 		"\x02",
	cGreen[32] = 		"\x04",
	cLightgreen[32] = 	"\x05",
	cLime[32] = 		"\x06",
	cRed[32] = 			"\x07",
	cGrey[32] = 		"\x08",
	cOlive[32] = 		"\x09",
	cGrayblue[32] = 	"\x0A",
	cLightblue[32] = 	"\x0B",
	cBlue[32] = 		"\x0C",
	cPurple[32] = 		"\x0E",
	cDarkorange[32] = 	"\x0F",
	cOrange[32] = 		"\x10";

// Список заблокированных радиокоманд.
char radioMsg[][] = {"go", "fallback", "sticktog", "holdpos", "followme", "roger", "negative", "cheer", "compliment", "thanks", "enemyspot", "needbackup", "takepoint", "sectorclear", "inposition"};

public Plugin myinfo =
{
	name = "Chat Manager",
	author = "Walderr",
	description = "Управляет текстовым чатом в игре",
	version = "1.0",
	url = "http://jaze.ru/"
};

public void OnPluginStart()
{
	LoadTranslations("ChatManager.phrases");
	LoadTranslations("common.phrases");
	
	RegConsoleCmd("sm_chat", Command_Chat, "Меню настроек чата");
	
	RegAdminCmd("sm_hsay", Command_HSay, ADMFLAG_CHAT, "Отправить сообщение-подсказку всем игрокам");
	RegAdminCmd("sm_csay", Command_CSay, ADMFLAG_CHAT, "Отправить всем игрокам сообщение по центру экрана");
	RegAdminCmd("sm_msay", Command_MSay, ADMFLAG_CHAT, "Отправить всем игрокам сообщение через меню");
	RegAdminCmd("sm_sayfor", Command_SayFor, ADMFLAG_UNBAN, "Написать в чат за игрока");
	
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	HookEvent("round_start", Event_RoundStart);
	
	// Куки
	h_prefixCookie = RegClientCookie("Prefix", "Префикс", CookieAccess_Private);
	h_prefixColorCookie = RegClientCookie("PrefixColor", "Цвет префикса", CookieAccess_Private);
	h_nameColorCookie = RegClientCookie("NameColor", "Цвет ника", CookieAccess_Private);
	h_textColorCookie = RegClientCookie("TextColor", "Цвет текста", CookieAccess_Private);
	h_disableAdminPrefixCookie = RegClientCookie("DisableAdminPrefix", "Выключить дополнительный префикс", CookieAccess_Private);
	
	// Блокируем все радиокоманды.
	for(int i = 0; i <= sizeof(radioMsg)-1; i++) AddCommandListener(UserMsg_RadioAudio, radioMsg[i]);
}

public void OnMapStart()
{
	CreateTimer(hintsInterval, Timer_Advertisements, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientPostAdminCheck(int client)
{
	if(CheckCommandAccess(client, "", ADMFLAG_ROOT, true)) FormatEx(adminPrefix[client], sizeof(adminPrefix[]), "Prefix_Technical_Administrator");
	else if(CheckCommandAccess(client, "", ADMFLAG_CHEATS, true)) FormatEx(adminPrefix[client], sizeof(adminPrefix[]), "Prefix_Senior_Administrator");
	else if(CheckCommandAccess(client, "", ADMFLAG_UNBAN, true)) FormatEx(adminPrefix[client], sizeof(adminPrefix[]), "Prefix_Administrator");
	else if(CheckCommandAccess(client, "", ADMFLAG_BAN, true)) FormatEx(adminPrefix[client], sizeof(adminPrefix[]), "Prefix_Junior_Administrator");
	else if(CheckCommandAccess(client, "", ADMFLAG_GENERIC, true)) FormatEx(adminPrefix[client], sizeof(adminPrefix[]), "Prefix_Moderator");
}

public void OnClientCookiesCached(client)
{
	if(IsFakeClient(client)) return;
	
	char tempChar[64];
	
	GetClientCookie(client, h_prefixCookie, tempChar, sizeof(tempChar));
	if(!StrEqual(tempChar, "")) FormatEx(prefix[client], sizeof(prefix[]), "%s", tempChar);

	GetClientCookie(client, h_prefixColorCookie, tempChar, sizeof(tempChar));
	if(!StrEqual(tempChar, "")) FormatEx(prefixColor[client], sizeof(prefixColor[]), "%s", tempChar);
	
	GetClientCookie(client, h_nameColorCookie, tempChar, sizeof(tempChar));
	if(!StrEqual(tempChar, "")) FormatEx(nameColor[client], sizeof(nameColor[]), "%s", tempChar);
	
	GetClientCookie(client, h_textColorCookie, tempChar, sizeof(tempChar));
	if(!StrEqual(tempChar, "")) FormatEx(textColor[client], sizeof(textColor[]), "%s", tempChar);
	
	GetClientCookie(client, h_disableAdminPrefixCookie, tempChar, sizeof(tempChar));
	if(StrEqual(tempChar, "1")) disableAdminPrefix[client] = true;
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast) 
{
	// Блокируем сообщение о присоединении игрока к команде.
	event.SetBool("silent", true);
}

public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast) 
{
	// Получаем index игрока из его UserID.
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	FormatEx(prefix[client], sizeof(prefix[]), "");
	FormatEx(prefixColor[client], sizeof(prefixColor[]), "");
	FormatEx(nameColor[client], sizeof(nameColor[]), "");
	FormatEx(textColor[client], sizeof(textColor[]), "");
	FormatEx(adminPrefix[client], sizeof(adminPrefix[]), "");
	
	// Сбрасываем собеседника этому игроку.
	lastInterlocutor[client] = 0;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	if(countdownTimer != INVALID_HANDLE)
	{
		KillTimer(countdownTimer);
		countdownTimer = INVALID_HANDLE;
	}
}

public Action UserMsg_RadioAudio(int client, const char[] command, int argc)
{
	// Блокируем аудиосообщение.
	return Plugin_Handled;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	// Если сообщение написал сервер, раскрашиваем и выходим.
	if(client == 0)
	{
		PrintToChatAll(" %N --> %s <--", client, sArgs);
		DetectCountdown(sArgs);
		
		return Plugin_Handled;
	}
	
	// Выходим, если клиент не в игре.
	if(!IsClientInGame(client)) return Plugin_Handled;
	
	// Если активно ожидание ввода префикса, устанавливаем и выходим.
	if(isWaitPrefix[client])
	{
		SetPlayerPrefix(client, sArgs);
		return Plugin_Handled;
	}
	
	//=====================================
	if(StrContains(sArgs, "Я играю на лайфхакерском конфиге") != -1)
	{
		FakeClientCommand(client, "say Я дурачок который хочет спамить в чат тупым конфигом! Замутьте меня!");
		return Plugin_Handled;
	}
	else if(StrContains(sArgs, "AHAHAHHAAH") != -1)
	{
		FakeClientCommand(client, "say Никогда не пользуйтесь конфигом еблана шока! Это такая параша!");
		return Plugin_Handled;
	}
	else if(StrContains(sArgs, "LIFEEEEHAAAACK") != -1)
	{
		FakeClientCommand(client, "say Я долбаеб, пришел от Шока!");
		return Plugin_Handled;
	}
	//=====================================
	
	// Если игрок написал личное сообщение
	if(StrContains(sArgs, "#") == 0)
	{
		PrintPM(client, sArgs);
		return Plugin_Handled;
	}
	
	// Если игрок написал в вип чат
	if(StrContains(sArgs, "$") == 0 && (GetUserFlagBits(client) & ADMFLAG_CUSTOM1))
	{
		PrintToVipChat(client, sArgs);
		return Plugin_Handled;
	}
	
	bool bIsAdminPrefix;
	char tempAdminPrefix[32];
	
	if(!StrEqual(adminPrefix[client], "") && !disableAdminPrefix[client]) bIsAdminPrefix = true;
	
	bool bIsClientVIP;
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1) bIsClientVIP = true;
	
	char protoMessage[512];
	
	// Если игрок написал в общий чат:
	if(StrEqual(command, "say"))
	{
		// Если игрок написал от имени администратора
		if(StrContains(sArgs, "@") == 0 && CheckCommandAccess(client, "", ADMFLAG_CHAT, true))
		{
			PrintFromAdmin(client, sArgs);
			return Plugin_Handled;
		}
		
		// Выходим, если у игрока имеется блокировка чата.
		if(SourceComms_GetClientGagType(client) != bNot) return Plugin_Continue;
		
		// Создаем фейковый ивент для того чтобы карта могла видеть сообщение игрока.
		CreateFakeEvent(client, sArgs);
		
		int team = GetClientTeam(client);
		bool alive = IsPlayerAlive(client);
		char cStatus[32];
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				SetGlobalTransTarget(i);
				
				if(team == CS_TEAM_NONE || team == CS_TEAM_SPECTATOR) FormatEx(cStatus, sizeof(cStatus), "%t", "Spectator_All");
				else if(!alive) FormatEx(cStatus, sizeof(cStatus), "%t", "Dead");
				
				if(bIsAdminPrefix)
					FormatEx(tempAdminPrefix, sizeof(tempAdminPrefix), "%t", adminPrefix[client]);
				
				if(bIsClientVIP)
				{
					FormatEx(protoMessage, sizeof(protoMessage), "%s %s%s%s %s%N : %s%s", cStatus, prefixColor[client], prefix[client], tempAdminPrefix, nameColor[client], client, textColor[client], sArgs);
				}
				else
				{
					FormatEx(protoMessage, sizeof(protoMessage), "%s %s %N : %s", cStatus, tempAdminPrefix, client, sArgs);
				}
				
				Handle pbSay = StartMessageOne("SayText2", i);
				PbSetInt(pbSay, "ent_idx", client);
				PbSetBool(pbSay, "chat", true);
				PbSetString(pbSay, "msg_name", protoMessage);
				PbAddString(pbSay, "params", "");
				PbAddString(pbSay, "params", "");
				PbAddString(pbSay, "params", "");
				PbAddString(pbSay, "params", "");
				EndMessage();
			}
		}
	}
	// Если игрок написал в командный чат:
	else if(StrEqual(command, "say_team"))
	{
		// Если игрок написал в админ чат:
		if(StrContains(sArgs, "@") == 0)
		{
			PrintToAdminChat(client, sArgs);
			return Plugin_Handled;
		}
		
		// Выходим, если у игрока имеется блокировка чата.
		if(SourceComms_GetClientGagType(client) != bNot) return Plugin_Continue;
	
		// Создаем фейковый ивент для того чтобы карта могла видеть сообщение игрока.
		CreateFakeEvent(client, sArgs);
		
		int team = GetClientTeam(client);
		bool alive = IsPlayerAlive(client);
		char cTeam[32], cStatus[32];
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				if(GetClientTeam(i) == team)
				{
					SetGlobalTransTarget(i);
					
					if(!alive && (team == CS_TEAM_CT || team == CS_TEAM_T)) FormatEx(cStatus, sizeof(cStatus), "%t ", "Dead");
					
					if(team == CS_TEAM_CT) FormatEx(cTeam, sizeof(cTeam), "%t ", "Human");
					else if(team == CS_TEAM_T) FormatEx(cTeam, sizeof(cTeam), "%t ", "Zombie");
					else FormatEx(cTeam, sizeof(cTeam), "%t ", "Spectator");
					
					if(bIsAdminPrefix)
						FormatEx(tempAdminPrefix, sizeof(tempAdminPrefix), "%t", adminPrefix[client]);
					
					if(bIsClientVIP)
					{
						FormatEx(protoMessage, sizeof(protoMessage), "%s%s%s%s%s %s%N : %s%s", cStatus, cTeam, prefixColor[client], prefix[client], tempAdminPrefix, nameColor[client], client, textColor[client], sArgs);
					}
					else
					{
						FormatEx(protoMessage, sizeof(protoMessage), "%s%s%s %N : %s", cStatus, cTeam, tempAdminPrefix, client, sArgs);
					}
				
					Handle pbSayTeam = StartMessageOne("SayText2", i);
					PbSetInt(pbSayTeam, "ent_idx", client);
					PbSetBool(pbSayTeam, "chat", true);
					PbSetString(pbSayTeam, "msg_name", protoMessage);
					PbAddString(pbSayTeam, "params", "");
					PbAddString(pbSayTeam, "params", "");
					PbAddString(pbSayTeam, "params", "");
					PbAddString(pbSayTeam, "params", "");
					EndMessage();
				}
				else if(CheckCommandAccess(i, "", ADMFLAG_CHAT, true)) PrintToChat(i, " \x09[В командный чат] %N : %s", client, sArgs);
			}
		}
	}
	
	// Блокируем стандартное сообщение.
	return Plugin_Handled;
}

void PrintFromAdmin(int client, const char[] sArgs)
{
	char adminMsg[512];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			
			if(CheckCommandAccess(i, "", ADMFLAG_CHAT, true)) FormatEx(adminMsg, sizeof(adminMsg), "%t", "Admin_Admins_Message", client, sArgs[1]);
			else FormatEx(adminMsg, sizeof(adminMsg), "%t", "Admin_All_Message", sArgs[1]);
			
			PrintToChat(i, "%s", adminMsg);
		}
	}
}

void PrintToAdminChat(int client, const char[] sArgs)
{
	char adminChatMessage[512];
	bool admin = CheckCommandAccess(client, "", ADMFLAG_CHAT, true);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			
			if(admin) FormatEx(adminChatMessage, sizeof(adminChatMessage), "%t", "Admin_Chat", client, sArgs[1]);
			else FormatEx(adminChatMessage, sizeof(adminChatMessage), "%t", "To_Admin_Chat", client, sArgs[1]);
		
			if(CheckCommandAccess(i, "", ADMFLAG_CHAT, true)) PrintToChat(i,  adminChatMessage);
			else if(i == client) PrintToChat(i,  adminChatMessage);
		}
	}
}

void PrintPM(int client, const char[] sArgs)
{
	char log[256];
	
	// Если это быстрый ответ на личное сообщение
	if(StrContains(sArgs[1], "#") == 0)
	{
		// Если игрок еще никому не писал, выходим.
		if(lastInterlocutor[client] == 0)
		{
			PrintToChat(client, "%t", "PM_NoInterlocutor");
			return;
		}
		
		// Получаем индекс из UserID получателя.
		int recipient = GetClientOfUserId(lastInterlocutor[client]);
		
		if(recipient == 0) PrintToChat(client, "%t", "PM_PlayerDisconnected");
		else
		{
			// Отправляем личное сообщение.
			if(recipient != client) PrintToChat(client, "%t", "PM_Sender", recipient, sArgs[2]);
			PrintToChat(recipient, "%t", "PM_Recipient", client, sArgs[2]);
			
			// Обновляем последнего собеседника для получателя (это будет отправитель).
			lastInterlocutor[recipient] = GetClientUserId(client);
			
			FormatEx(log, sizeof(log), " [%N игроку %N]: %s", client, recipient, sArgs[2]);
			PmLogToAdmins(log, client, recipient);
			
			LogAction(client, -1, "%N ответил игроку %N: %s", client, recipient, sArgs[2]);
		}
		
		return;
	}

	char name[128];
	
	// Вытаскиваем из сообщения ник получателя и запоминаем номер в строке, с которого начинается сообщение.
	int len = BreakString(sArgs[1], name, sizeof(name));
	
	if(len == -1)
	{
		PrintToChat(client, "%t", "PM_Enter_Message");
		return;
	}
	
	// Ищем получателя по нику.
	int recipient = FindTarget(client, name, false, false);
	
	// Если получатель не найден
	if(recipient == -1)
	{
		PrintToChat(client, "%t", "No matching client");
		return;
	}
	
	// Отправляем личное сообщение.
	if(recipient != client) PrintToChat(client, "%t", "PM_Sender", recipient, sArgs[len+1]);
	PrintToChat(recipient, "%t", "PM_Recipient", client, sArgs[len+1]);
	
	// Связываем игроков, чтобы могли отвечать друг другу.
	lastInterlocutor[client] = GetClientUserId(recipient);
	lastInterlocutor[recipient] = GetClientUserId(client);
	
	FormatEx(log, sizeof(log), " [%N игроку %N]: %s", client, recipient, sArgs[len+1]);
	PmLogToAdmins(log, client, recipient);
	
	LogAction(client, -1, "%N написал игроку %N сообщение: %s", client, recipient, sArgs[len+1]);
}

void PrintToVipChat(int client, const char[] sArgs)
{
	char vipChatMessage[512];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			
			FormatEx(vipChatMessage, sizeof(vipChatMessage), "%t", "VIP_Chat", client, sArgs[1]);

			if((GetUserFlagBits(i) & ADMFLAG_CUSTOM1) || CheckCommandAccess(i, "", ADMFLAG_CHAT, true)) PrintToChat(i,  vipChatMessage);
		}
	}
}

void SetPlayerPrefix(int client, const char[] message)
{
	if(strlen(message) >= 30)
	{
		PrintToChat(client, "%t", "Prefix_MaxLength");
		return;
	}
	else if(StrEqual(message, ""))
	{
		PrintToChat(client, "%t", "Empty_Prefix");
		return;
	}
	else if(StrContains(message, " ") == 0)
	{
		PrintToChat(client, "%t", "Space_Prefix");
		return;
	}
	else if(StrContains(message, "[") != -1 || StrContains(message, "]") != -1)
	{
		PrintToChat(client, "%t", "Prefix_Forbidden_Symbols");
		return;
	}
	else if(StrEqual(message, "М", false) ||	// Русские
			StrEqual(message, "МА", false) ||
			StrEqual(message, "А", false) ||
			StrEqual(message, "СА", false) ||
			StrEqual(message, "ТА", false) ||
			StrEqual(message, "M", false) ||	// Английские
			StrEqual(message, "JA", false) ||
			StrEqual(message, "A", false) ||
			StrEqual(message, "SA", false) ||
			StrEqual(message, "SM", false) ||
			StrEqual(message, "SМ", false) ||	// Смешанные
			StrEqual(message, "Модератор", false) ||
			StrEqual(message, "МОДЕРАТОР", false) ||
			StrEqual(message, "Администратор", false) ||
			StrEqual(message, "АДМИНИСТРАТОР", false) ||
			StrEqual(message, "Админ", false) ||
			StrEqual(message, "АДМИН", false) ||
			StrEqual(message, "Moderator", false) ||
			StrEqual(message, "Administrator", false) ||
			StrEqual(message, "MA", false) ||
			StrEqual(message, "МA", false) ||
			StrEqual(message, "MА", false) ||
			StrEqual(message, "CA", false) ||
			StrEqual(message, "СA", false) ||
			StrEqual(message, "CА", false) ||
			StrEqual(message, "TA", false) ||
			StrEqual(message, "TА", false) ||
			StrEqual(message, "ТA", false) ||
			StrEqual(message, "Admin", false))
	{
		PrintToChat(client, "%t", "Prefix_Forbidden");
		return;
	}
	
	else
	{
		FormatEx(prefix[client], sizeof(prefix[]), "[%s]", message);
		SetClientCookie(client, h_prefixCookie, prefix[client]);
	}
	
	isWaitPrefix[client] = false;
	
	ShowSetPrefixMenu(client);
	
	return;
}

public Action Command_Chat(int client, int args)
{
	ShowChatMenu(client);
	return Plugin_Handled;
}

public Action Command_HSay(int client, int args)
{
	char msg[256], hsay[256];
	GetCmdArgString(msg, sizeof(msg));
	
	LogAction(client, -1, "\"%L\" написал через sm_hsay (сообщение: %s)", client, msg);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			
			if(CheckCommandAccess(i, "", ADMFLAG_CHAT, true)) FormatEx(hsay, sizeof(hsay), "%t", "Admin_Admins_Message", client, msg);
			else FormatEx(hsay, sizeof(hsay), "%t", "Admin_All_Message", msg);
			
			PrintHintText(i, "%s", hsay);
		}
	}
	
	return Plugin_Handled;
}

public Action Command_CSay(int client, int args)
{
	char msg[256], csay[256];
	GetCmdArgString(msg, sizeof(msg));
	
	LogAction(client, -1, "\"%L\" написал через sm_csay (сообщение: %s)", client, msg);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			
			if(CheckCommandAccess(i, "", ADMFLAG_CHAT, true)) FormatEx(csay, sizeof(csay), "%t", "Admin_Admins_Message", client, msg);
			else FormatEx(csay, sizeof(csay), "%t", "Admin_All_Message", msg);
			
			PrintCenterText(i, "%s", csay);
		}
	}
	
	return Plugin_Handled;
}

public Action Command_MSay(int client, int args)
{
	char message[256], title[64];
	GetCmdArgString(message, sizeof(message));
	
	LogAction(client, -1, "\"%L\" написал через sm_msay (сообщение: %s)", client, message);
	
	FormatEx(title, 64, "%N:", client);
	
	Panel mSayPanel = new Panel();
	mSayPanel.SetTitle(title);
	mSayPanel.DrawItem("", ITEMDRAW_SPACER);
	mSayPanel.DrawText(message);
	mSayPanel.DrawItem("", ITEMDRAW_SPACER);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i)) mSayPanel.Send(i, Handler_DoNothing, 10);
	}
	
	return Plugin_Handled;
}

public int Handler_DoNothing(Menu menu, MenuAction action, int param1, int param2) {}

public Action Command_SayFor(int client, int args)
{
	if (args < 2)
	{
		PrintToChat(client, "Нужно вводить: /sayfor \x07имя \x0Bсообщение!");
		return Plugin_Handled;
	}
	
	char msg[256], name[64], logMsg[128];
	GetCmdArgString(msg, sizeof(msg));

	int len = BreakString(msg, name, sizeof(name));

	int target = FindTarget(client, name, false, false);
	
	if(target == -1) return Plugin_Handled;
	
	FakeClientCommand(target, "say %s", msg[len]);
	
	FormatEx(logMsg, sizeof(logMsg), " \x0B%N \x06написал в чат за игрока \x0B%N", client, target);
	LogToAdmins(logMsg);
	
	return Plugin_Handled;
}

char GetCurrentColor(int client, int type)
{
	char currentColor[32], tag[4];

	if(type == 1) FormatEx(tag, sizeof(tag), "%s", prefixColor[client]);	// Цвет префикса.
	else if(type == 2) FormatEx(tag, sizeof(tag), "%s", nameColor[client]);	// Цвет ника.
	else if(type == 3) FormatEx(tag, sizeof(tag), "%s", textColor[client]);	// Цвет текста.
	
	if(StrEqual(tag, cWhite)) FormatEx(currentColor, sizeof(currentColor), "%t", "Color_White");
	else if(StrEqual(tag, cTeamColor)) FormatEx(currentColor, sizeof(currentColor), "%t", "Color_Teamcolor");
	else if(StrEqual(tag, cDarkred)) FormatEx(currentColor, sizeof(currentColor), "%t", "Color_Drakred");
	else if(StrEqual(tag, cGreen)) FormatEx(currentColor, sizeof(currentColor), "%t", "Color_Green");
	else if(StrEqual(tag, cLightgreen)) FormatEx(currentColor, sizeof(currentColor), "%t", "Color_Lightgreen");
	else if(StrEqual(tag, cLime)) FormatEx(currentColor, sizeof(currentColor), "%t", "Color_Lime");
	else if(StrEqual(tag, cRed)) FormatEx(currentColor, sizeof(currentColor), "%t", "Color_Red");
	else if(StrEqual(tag, cGrey)) FormatEx(currentColor, sizeof(currentColor), "%t", "Color_Grey");
	else if(StrEqual(tag, cOlive)) FormatEx(currentColor, sizeof(currentColor), "%t", "Color_Olive");
	else if(StrEqual(tag, cGrayblue)) FormatEx(currentColor, sizeof(currentColor), "%t", "Color_Greyblue");
	else if(StrEqual(tag, cLightblue)) FormatEx(currentColor, sizeof(currentColor), "%t", "Color_LightBlue");
	else if(StrEqual(tag, cBlue)) FormatEx(currentColor, sizeof(currentColor), "%t", "Color_Blue");
	else if(StrEqual(tag, cPurple)) FormatEx(currentColor, sizeof(currentColor), "%t", "Color_Purple");
	else if(StrEqual(tag, cDarkorange)) FormatEx(currentColor, sizeof(currentColor), "%t", "Color_Darkorange");
	else if(StrEqual(tag, cOrange)) FormatEx(currentColor, sizeof(currentColor), "%t", "Color_Orange");
	else FormatEx(currentColor, sizeof(currentColor), "%t", "Color_Default");
	
	return currentColor;
}

void ShowChatMenu(int client)
{
	SetGlobalTransTarget(client);
	
	char mPrefix[64], mPrefixColor[128], mNameColor[128], mTextColor[128], mAdditionalPrefix[128], mClear[64];
	
	FormatEx(mPrefix, sizeof(mPrefix), "%t", "Chat_SetPrefix");
	FormatEx(mPrefixColor, sizeof(mPrefixColor), "%t", "Chat_SetPrefixColor", GetCurrentColor(client, 1));
	FormatEx(mNameColor, sizeof(mNameColor), "%t", "Chat_SetNameColor", GetCurrentColor(client, 2));
	FormatEx(mTextColor, sizeof(mTextColor), "%t\n ", "Chat_SetTextColor", GetCurrentColor(client, 3));
	FormatEx(mClear, sizeof(mClear), "%t", "Chat_Clear");
	FormatEx(mAdditionalPrefix, sizeof(mAdditionalPrefix), "%t", "Chat_SetAdditionalPrefix");
	
	Menu chat = new Menu(ChatHandler);
	chat.SetTitle("%T", "Chat_Menu_Title", client);
	
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1) chat.AddItem("", mPrefix);
	else chat.AddItem("", mPrefix, ITEMDRAW_DISABLED);
	
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1) chat.AddItem("", mPrefixColor);
	else chat.AddItem("", mPrefixColor, ITEMDRAW_DISABLED);
	
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1) chat.AddItem("", mNameColor);
	else chat.AddItem("", mNameColor, ITEMDRAW_DISABLED);
	
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1) chat.AddItem("", mTextColor);
	else chat.AddItem("", mTextColor, ITEMDRAW_DISABLED);
	
	if(StrEqual(prefix[client], "") && StrEqual(prefixColor[client], "") && StrEqual(nameColor[client], "") && StrEqual(textColor[client], "")) chat.AddItem("", mClear, ITEMDRAW_DISABLED);
	else chat.AddItem("", mClear);
	
	if(CheckCommandAccess(client, "", ADMFLAG_GENERIC, true)) chat.AddItem("", mAdditionalPrefix);
	
	chat.ExitBackButton = true;
	chat.Display(client, 180);
}

public ChatHandler(Menu chat, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) 
	{
		if(option == 0) ShowSetPrefixMenu(client);
		else if(option == 1) ShowSetPrefixColorMenu(client);
		else if(option == 2) ShowSetNameColorMenu(client);
		else if(option == 3) ShowSetTextColorMenu(client);
		else if(option == 5) ShowAdditionalPrefixMenu(client);
		else if(option == 4)
		{
			FormatEx(prefix[client], sizeof(prefix[]), "");
			SetClientCookie(client, h_prefixCookie, "");
			FormatEx(prefixColor[client], sizeof(prefixColor[]), "");
			SetClientCookie(client, h_prefixColorCookie, "");
			FormatEx(nameColor[client], sizeof(nameColor[]), "");
			SetClientCookie(client, h_nameColorCookie, "");
			FormatEx(textColor[client], sizeof(textColor[]), "");
			SetClientCookie(client, h_textColorCookie, "");
			ShowChatMenu(client);
		}
	}
	else if(action == MenuAction_Cancel) 
	{
		if(option == MenuCancel_ExitBack) FakeClientCommand(client, "sm_vip");
	}
	else if(action == MenuAction_End) delete chat;
}

void ShowSetPrefixMenu(int client)
{
	SetGlobalTransTarget(client);
	
	char currentPrefix[128], changePrefix[64], back[32];
	
	Menu prefixmenu = new Menu(PrefixMenuHandler);
	prefixmenu.SetTitle("%T", "Prefix_Menu_Title", client);
	
	if(isWaitPrefix[client])
	{
		if(StrEqual(prefix[client], ""))
		{
			FormatEx(currentPrefix, sizeof(currentPrefix), "%t", "None_Prefix");
			prefixmenu.AddItem("", currentPrefix, ITEMDRAW_DISABLED);
			
			FormatEx(changePrefix, sizeof(changePrefix), "%t\n ", "Setup_Prefix");
			prefixmenu.AddItem("", changePrefix, ITEMDRAW_DISABLED);
			
			FormatEx(back, sizeof(back), "%t", "Cancel");
			prefixmenu.AddItem("", back);
		}
		else
		{
			FormatEx(currentPrefix, sizeof(currentPrefix), "%t", "Current_Prefix", prefix[client]);
			prefixmenu.AddItem("", currentPrefix, ITEMDRAW_DISABLED);
			
			FormatEx(changePrefix, sizeof(changePrefix), "%t\n ", "Change_Prefix");
			prefixmenu.AddItem("", changePrefix, ITEMDRAW_DISABLED);
			
			FormatEx(back, sizeof(back), "%t", "Cancel");
			prefixmenu.AddItem("", back);
		}
	}
	else
	{
		if(StrEqual(prefix[client], ""))
		{
			FormatEx(currentPrefix, sizeof(currentPrefix), "%t", "None_Prefix");
			prefixmenu.AddItem("", currentPrefix, ITEMDRAW_DISABLED);
			
			FormatEx(changePrefix, sizeof(changePrefix), "%t\n ", "Setup_Prefix");
			prefixmenu.AddItem("", changePrefix);
			
			FormatEx(back, sizeof(back), "%t", "Back");
			prefixmenu.AddItem("", back);
		}
		else
		{
			FormatEx(currentPrefix, sizeof(currentPrefix), "%t", "Current_Prefix", prefix[client]);
			prefixmenu.AddItem("", currentPrefix);
			
			FormatEx(changePrefix, sizeof(changePrefix), "%t\n ", "Change_Prefix");
			prefixmenu.AddItem("", changePrefix);
			
			FormatEx(back, sizeof(back), "%t", "Back");
			prefixmenu.AddItem("", back);
		}
	}

	prefixmenu.Display(client, 180);
}

public PrefixMenuHandler(Menu prefixmenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) 
	{
		if(option == 0)
		{
			FormatEx(prefix[client], sizeof(prefix[]), "");
			SetClientCookie(client, h_prefixCookie, "");
			ShowSetPrefixMenu(client);
		}
		else if(option == 1)
		{
			PrintToChat(client, "%t", "Print_Prefix");
			isWaitPrefix[client] = true;
			ShowSetPrefixMenu(client);
		}
		else if(option == 2)
		{
			if(isWaitPrefix[client])
			{
				PrintToChat(client, "%t", "Action_Cancel");
				isWaitPrefix[client] = false;
				ShowSetPrefixMenu(client);
			}
			else ShowChatMenu(client);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		// Прекращаем ожидание ввода тега если меню закрылось.
		if(isWaitPrefix[client])
		{
			PrintToChat(client, "%t", "Action_Cancel");
			isWaitPrefix[client] = false;
		}
	}
	else if(action == MenuAction_End) delete prefixmenu;
}

void ShowSetPrefixColorMenu(int client)
{
	SetGlobalTransTarget(client);
	
	char mcWhite[32], mcTeamColor[32], mcDarkred[32], mcGreen[32], mcLightgreen[32], mcLime[32], mcRed[32], mcGrey[32], mcOlive[32], mcGrayblue[32], mcLightblue[32], mcBlue[32], mcPurple[32], mcDarkorange[32], mcOrange[32];
	
	FormatEx(mcWhite, sizeof(mcWhite), "%t", "Color_White");
	FormatEx(mcTeamColor, sizeof(mcTeamColor), "%t", "Color_Teamcolor");
	FormatEx(mcDarkred, sizeof(mcDarkred), "%t", "Color_Drakred");
	FormatEx(mcGreen, sizeof(mcGreen), "%t", "Color_Green");
	FormatEx(mcLightgreen, sizeof(mcLightgreen), "%t", "Color_Lightgreen");
	FormatEx(mcLime, sizeof(mcLime), "%t", "Color_Lime");
	FormatEx(mcRed, sizeof(mcRed), "%t", "Color_Red");
	FormatEx(mcGrey, sizeof(mcGrey), "%t", "Color_Grey");
	FormatEx(mcOlive, sizeof(mcOlive), "%t", "Color_Olive");
	FormatEx(mcGrayblue, sizeof(mcGrayblue), "%t", "Color_Greyblue");
	FormatEx(mcLightblue, sizeof(mcLightblue), "%t", "Color_LightBlue");
	FormatEx(mcBlue, sizeof(mcBlue), "%t", "Color_Blue");
	FormatEx(mcPurple, sizeof(mcPurple), "%t", "Color_Purple");
	FormatEx(mcDarkorange, sizeof(mcDarkorange), "%t", "Color_Darkorange");
	FormatEx(mcOrange, sizeof(mcOrange), "%t", "Color_Orange");
	
	Menu pcolor = new Menu(PrefixColorMenuHandler);
	pcolor.SetTitle("%T", "Color_Menu_Title", client);
	
	if(StrEqual(prefixColor[client], cWhite)) pcolor.AddItem(cWhite, mcWhite, ITEMDRAW_DISABLED);
	else pcolor.AddItem(cWhite, mcWhite);
	if(StrEqual(prefixColor[client], cTeamColor)) pcolor.AddItem(cTeamColor, mcTeamColor, ITEMDRAW_DISABLED);
	else pcolor.AddItem(cTeamColor, mcTeamColor);
	if(StrEqual(prefixColor[client], cDarkred)) pcolor.AddItem(cDarkred, mcDarkred, ITEMDRAW_DISABLED);
	else pcolor.AddItem(cDarkred, mcDarkred);
	if(StrEqual(prefixColor[client], cGreen)) pcolor.AddItem(cGreen, mcGreen, ITEMDRAW_DISABLED);
	else pcolor.AddItem(cGreen, mcGreen);
	if(StrEqual(prefixColor[client], cLightgreen)) pcolor.AddItem(cLightgreen, mcLightgreen, ITEMDRAW_DISABLED);
	else pcolor.AddItem(cLightgreen, mcLightgreen);
	if(StrEqual(prefixColor[client], cLime)) pcolor.AddItem(cLime, mcLime, ITEMDRAW_DISABLED);
	else pcolor.AddItem(cLime, mcLime);
	if(StrEqual(prefixColor[client], cRed)) pcolor.AddItem(cRed, mcRed, ITEMDRAW_DISABLED);
	else pcolor.AddItem(cRed, mcRed);
	if(StrEqual(prefixColor[client], cGrey)) pcolor.AddItem(cGrey, mcGrey, ITEMDRAW_DISABLED);
	else pcolor.AddItem(cGrey, mcGrey);
	if(StrEqual(prefixColor[client], cOlive)) pcolor.AddItem(cOlive, mcOlive, ITEMDRAW_DISABLED);
	else pcolor.AddItem(cOlive, mcOlive);
	if(StrEqual(prefixColor[client], cGrayblue)) pcolor.AddItem(cGrayblue, mcGrayblue, ITEMDRAW_DISABLED);
	else pcolor.AddItem(cGrayblue, mcGrayblue);
	if(StrEqual(prefixColor[client], cLightblue)) pcolor.AddItem(cLightblue, mcLightblue, ITEMDRAW_DISABLED);
	else pcolor.AddItem(cLightblue, mcLightblue);
	if(StrEqual(prefixColor[client], cBlue)) pcolor.AddItem(cBlue, mcBlue, ITEMDRAW_DISABLED);
	else pcolor.AddItem(cBlue, mcBlue);
	if(StrEqual(prefixColor[client], cPurple)) pcolor.AddItem(cPurple, mcPurple, ITEMDRAW_DISABLED);
	else pcolor.AddItem(cPurple, mcPurple);
	if(StrEqual(prefixColor[client], cDarkorange)) pcolor.AddItem(cDarkorange, mcDarkorange, ITEMDRAW_DISABLED);
	else pcolor.AddItem(cDarkorange, mcDarkorange);
	if(StrEqual(prefixColor[client], cOrange)) pcolor.AddItem(cOrange, mcOrange, ITEMDRAW_DISABLED);
	else pcolor.AddItem(cOrange, mcOrange);
	
	pcolor.ExitBackButton = true;
	pcolor.Display(client, 180);
}

public PrefixColorMenuHandler(Menu pcolor, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) 
	{
		char item[64];
		pcolor.GetItem(option, item, sizeof(item));
		
		FormatEx(prefixColor[client], sizeof(prefixColor[]), "%s", item);
		SetClientCookie(client, h_prefixColorCookie, item);
		ShowSetPrefixColorMenu(client);
	}
	else if(action == MenuAction_Cancel) 
	{
		if(option == MenuCancel_ExitBack) ShowChatMenu(client);
	}
	else if(action == MenuAction_End) delete pcolor;
}

void ShowSetNameColorMenu(int client)
{
	SetGlobalTransTarget(client);
	
	char mcWhite[32], mcTeamColor[32], mcDarkred[32], mcGreen[32], mcLightgreen[32], mcLime[32], mcRed[32], mcGrey[32], mcOlive[32], mcGrayblue[32], mcLightblue[32], mcBlue[32], mcPurple[32], mcDarkorange[32], mcOrange[32];
	
	FormatEx(mcWhite, sizeof(mcWhite), "%t", "Color_White");
	FormatEx(mcTeamColor, sizeof(mcTeamColor), "%t", "Color_Teamcolor");
	FormatEx(mcDarkred, sizeof(mcDarkred), "%t", "Color_Drakred");
	FormatEx(mcGreen, sizeof(mcGreen), "%t", "Color_Green");
	FormatEx(mcLightgreen, sizeof(mcLightgreen), "%t", "Color_Lightgreen");
	FormatEx(mcLime, sizeof(mcLime), "%t", "Color_Lime");
	FormatEx(mcRed, sizeof(mcRed), "%t", "Color_Red");
	FormatEx(mcGrey, sizeof(mcGrey), "%t", "Color_Grey");
	FormatEx(mcOlive, sizeof(mcOlive), "%t", "Color_Olive");
	FormatEx(mcGrayblue, sizeof(mcGrayblue), "%t", "Color_Greyblue");
	FormatEx(mcLightblue, sizeof(mcLightblue), "%t", "Color_LightBlue");
	FormatEx(mcBlue, sizeof(mcBlue), "%t", "Color_Blue");
	FormatEx(mcPurple, sizeof(mcPurple), "%t", "Color_Purple");
	FormatEx(mcDarkorange, sizeof(mcDarkorange), "%t", "Color_Darkorange");
	FormatEx(mcOrange, sizeof(mcOrange), "%t", "Color_Orange");
	
	Menu ncolor = new Menu(NameColorMenuHandler);
	ncolor.SetTitle("%T", "Color_Menu_Title", client);
	
	if(StrEqual(nameColor[client], cWhite)) ncolor.AddItem(cWhite, mcWhite, ITEMDRAW_DISABLED);
	else ncolor.AddItem(cWhite, mcWhite);
	if(StrEqual(nameColor[client], cTeamColor)) ncolor.AddItem(cTeamColor, mcTeamColor, ITEMDRAW_DISABLED);
	else ncolor.AddItem(cTeamColor, mcTeamColor);
	if(StrEqual(nameColor[client], cDarkred)) ncolor.AddItem(cDarkred, mcDarkred, ITEMDRAW_DISABLED);
	else ncolor.AddItem(cDarkred, mcDarkred);
	if(StrEqual(nameColor[client], cGreen)) ncolor.AddItem(cGreen, mcGreen, ITEMDRAW_DISABLED);
	else ncolor.AddItem(cGreen, mcGreen);
	if(StrEqual(nameColor[client], cLightgreen)) ncolor.AddItem(cLightgreen, mcLightgreen, ITEMDRAW_DISABLED);
	else ncolor.AddItem(cLightgreen, mcLightgreen);
	if(StrEqual(nameColor[client], cLime)) ncolor.AddItem(cLime, mcLime, ITEMDRAW_DISABLED);
	else ncolor.AddItem(cLime, mcLime);
	if(StrEqual(nameColor[client], cRed)) ncolor.AddItem(cRed, mcRed, ITEMDRAW_DISABLED);
	else ncolor.AddItem(cRed, mcRed);
	if(StrEqual(nameColor[client], cGrey)) ncolor.AddItem(cGrey, mcGrey, ITEMDRAW_DISABLED);
	else ncolor.AddItem(cGrey, mcGrey);
	if(StrEqual(nameColor[client], cOlive)) ncolor.AddItem(cOlive, mcOlive, ITEMDRAW_DISABLED);
	else ncolor.AddItem(cOlive, mcOlive);
	if(StrEqual(nameColor[client], cGrayblue)) ncolor.AddItem(cGrayblue, mcGrayblue, ITEMDRAW_DISABLED);
	else ncolor.AddItem(cGrayblue, mcGrayblue);
	if(StrEqual(nameColor[client], cLightblue)) ncolor.AddItem(cLightblue, mcLightblue, ITEMDRAW_DISABLED);
	else ncolor.AddItem(cLightblue, mcLightblue);
	if(StrEqual(nameColor[client], cBlue)) ncolor.AddItem(cBlue, mcBlue, ITEMDRAW_DISABLED);
	else ncolor.AddItem(cBlue, mcBlue);
	if(StrEqual(nameColor[client], cPurple)) ncolor.AddItem(cPurple, mcPurple, ITEMDRAW_DISABLED);
	else ncolor.AddItem(cPurple, mcPurple);
	if(StrEqual(nameColor[client], cDarkorange)) ncolor.AddItem(cDarkorange, mcDarkorange, ITEMDRAW_DISABLED);
	else ncolor.AddItem(cDarkorange, mcDarkorange);
	if(StrEqual(nameColor[client], cOrange)) ncolor.AddItem(cOrange, mcOrange, ITEMDRAW_DISABLED);
	else ncolor.AddItem(cOrange, mcOrange);
	
	ncolor.ExitBackButton = true;
	ncolor.Display(client, 180);
}

public NameColorMenuHandler(Menu ncolor, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) 
	{
		char item[64];
		ncolor.GetItem(option, item, sizeof(item));
		
		FormatEx(nameColor[client], sizeof(nameColor[]), "%s", item);
		SetClientCookie(client, h_nameColorCookie, item);
		ShowSetNameColorMenu(client);
	}
	else if(action == MenuAction_Cancel) 
	{
		if(option == MenuCancel_ExitBack) ShowChatMenu(client);
	}
	else if(action == MenuAction_End) delete ncolor;
}

void ShowSetTextColorMenu(int client)
{
	SetGlobalTransTarget(client);
	
	char mcWhite[32], mcTeamColor[32], mcDarkred[32], mcGreen[32], mcLightgreen[32], mcLime[32], mcRed[32], mcGrey[32], mcOlive[32], mcGrayblue[32], mcLightblue[32], mcBlue[32], mcPurple[32], mcDarkorange[32], mcOrange[32];
	
	FormatEx(mcWhite, sizeof(mcWhite), "%t", "Color_White");
	FormatEx(mcTeamColor, sizeof(mcTeamColor), "%t", "Color_Teamcolor");
	FormatEx(mcDarkred, sizeof(mcDarkred), "%t", "Color_Drakred");
	FormatEx(mcGreen, sizeof(mcGreen), "%t", "Color_Green");
	FormatEx(mcLightgreen, sizeof(mcLightgreen), "%t", "Color_Lightgreen");
	FormatEx(mcLime, sizeof(mcLime), "%t", "Color_Lime");
	FormatEx(mcRed, sizeof(mcRed), "%t", "Color_Red");
	FormatEx(mcGrey, sizeof(mcGrey), "%t", "Color_Grey");
	FormatEx(mcOlive, sizeof(mcOlive), "%t", "Color_Olive");
	FormatEx(mcGrayblue, sizeof(mcGrayblue), "%t", "Color_Greyblue");
	FormatEx(mcLightblue, sizeof(mcLightblue), "%t", "Color_LightBlue");
	FormatEx(mcBlue, sizeof(mcBlue), "%t", "Color_Blue");
	FormatEx(mcPurple, sizeof(mcPurple), "%t", "Color_Purple");
	FormatEx(mcDarkorange, sizeof(mcDarkorange), "%t", "Color_Darkorange");
	FormatEx(mcOrange, sizeof(mcOrange), "%t", "Color_Orange");
	
	Menu tcolor = new Menu(TextColorMenuHandler);
	tcolor.SetTitle("%T", "Color_Menu_Title", client);
	
	if(StrEqual(textColor[client], cWhite)) tcolor.AddItem(cWhite, mcWhite, ITEMDRAW_DISABLED);
	else tcolor.AddItem(cWhite, mcWhite);
	if(StrEqual(textColor[client], cTeamColor)) tcolor.AddItem(cTeamColor, mcTeamColor, ITEMDRAW_DISABLED);
	else tcolor.AddItem(cTeamColor, mcTeamColor);
	if(StrEqual(textColor[client], cDarkred)) tcolor.AddItem(cDarkred, mcDarkred, ITEMDRAW_DISABLED);
	else tcolor.AddItem(cDarkred, mcDarkred);
	if(StrEqual(textColor[client], cGreen)) tcolor.AddItem(cGreen, mcGreen, ITEMDRAW_DISABLED);
	else tcolor.AddItem(cGreen, mcGreen);
	if(StrEqual(textColor[client], cLightgreen)) tcolor.AddItem(cLightgreen, mcLightgreen, ITEMDRAW_DISABLED);
	else tcolor.AddItem(cLightgreen, mcLightgreen);
	if(StrEqual(textColor[client], cLime)) tcolor.AddItem(cLime, mcLime, ITEMDRAW_DISABLED);
	else tcolor.AddItem(cLime, mcLime);
	if(StrEqual(textColor[client], cRed)) tcolor.AddItem(cRed, mcRed, ITEMDRAW_DISABLED);
	else tcolor.AddItem(cRed, mcRed);
	if(StrEqual(textColor[client], cGrey)) tcolor.AddItem(cGrey, mcGrey, ITEMDRAW_DISABLED);
	else tcolor.AddItem(cGrey, mcGrey);
	if(StrEqual(textColor[client], cOlive)) tcolor.AddItem(cOlive, mcOlive, ITEMDRAW_DISABLED);
	else tcolor.AddItem(cOlive, mcOlive);
	if(StrEqual(textColor[client], cGrayblue)) tcolor.AddItem(cGrayblue, mcGrayblue, ITEMDRAW_DISABLED);
	else tcolor.AddItem(cGrayblue, mcGrayblue);
	if(StrEqual(textColor[client], cLightblue)) tcolor.AddItem(cLightblue, mcLightblue, ITEMDRAW_DISABLED);
	else tcolor.AddItem(cLightblue, mcLightblue);
	if(StrEqual(textColor[client], cBlue)) tcolor.AddItem(cBlue, mcBlue, ITEMDRAW_DISABLED);
	else tcolor.AddItem(cBlue, mcBlue);
	if(StrEqual(textColor[client], cPurple)) tcolor.AddItem(cPurple, mcPurple, ITEMDRAW_DISABLED);
	else tcolor.AddItem(cPurple, mcPurple);
	if(StrEqual(textColor[client], cDarkorange)) tcolor.AddItem(cDarkorange, mcDarkorange, ITEMDRAW_DISABLED);
	else tcolor.AddItem(cDarkorange, mcDarkorange);
	if(StrEqual(textColor[client], cOrange)) tcolor.AddItem(cOrange, mcOrange, ITEMDRAW_DISABLED);
	else tcolor.AddItem(cOrange, mcOrange);
	
	tcolor.ExitBackButton = true;
	tcolor.Display(client, 180);
}

public TextColorMenuHandler(Menu tcolor, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) 
	{
		char item[64];
		tcolor.GetItem(option, item, sizeof(item));
		
		FormatEx(textColor[client], sizeof(textColor[]), "%s", item);
		SetClientCookie(client, h_textColorCookie, item);
		ShowSetTextColorMenu(client);
	}
	else if(action == MenuAction_Cancel) 
	{
		if(option == MenuCancel_ExitBack) ShowChatMenu(client);
	}
	else if(action == MenuAction_End) delete tcolor;
}

PmLogToAdmins(char[] logMessage, int client, int recipient)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && CheckCommandAccess(i, "", ADMFLAG_ROOT, true) && i != client && i != recipient) PrintToChat(i, logMessage);
	}
}

LogToAdmins(char[] logMessage)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && CheckCommandAccess(i, "", ADMFLAG_UNBAN, true)) PrintToChat(i, logMessage);
	}
}

void ShowAdditionalPrefixMenu(int client)
{
	SetGlobalTransTarget(client);
	
	char disabled[128], back[32], tAdminPrefix[16];
	
	Menu addPrefixmenu = new Menu(AddPrefixMenuHandler);
	addPrefixmenu.SetTitle("%T", "Additional_Prefix_Title", client);

	FormatEx(disabled, sizeof(disabled), "%t", "Prefix_Disabled");
	
	if(disableAdminPrefix[client]) addPrefixmenu.AddItem("disable", disabled, ITEMDRAW_DISABLED);
	else addPrefixmenu.AddItem("disable", disabled);
	
	if(CheckCommandAccess(client, "", ADMFLAG_GENERIC, true))
	{
		FormatEx(tAdminPrefix, sizeof(tAdminPrefix), "%t\n ", adminPrefix[client]);
		
		if(!disableAdminPrefix[client]) addPrefixmenu.AddItem("", tAdminPrefix[1], ITEMDRAW_DISABLED);
		else addPrefixmenu.AddItem("", tAdminPrefix[1]);
	}
	
	FormatEx(back, sizeof(back), "%t", "Back");
	addPrefixmenu.AddItem("back", back);
	
	addPrefixmenu.Display(client, 180);
}

public AddPrefixMenuHandler(Menu addPrefixmenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) 
	{
		char item[32];
		addPrefixmenu.GetItem(option, item, sizeof(item));

		if(StrEqual(item, "back")) ShowChatMenu(client);
		
		else if(StrEqual(item, "disable"))
		{
			disableAdminPrefix[client] = true;
			SetClientCookie(client, h_disableAdminPrefixCookie, "1");
			ShowAdditionalPrefixMenu(client);
		}
		else
		{
			disableAdminPrefix[client] = false;
			SetClientCookie(client, h_disableAdminPrefixCookie, "0");
			ShowAdditionalPrefixMenu(client);
		}
	}
	else if(action == MenuAction_End) delete addPrefixmenu;
}

DetectCountdown(const char[] buffer)
{
	char numbersInString[256];

	bool numeric = false;
	
	for(int i = 0; i < strlen(buffer); i++)
	{
		if (IsCharNumeric(buffer[i]))
		{
			if(!numeric) Format(numbersInString, 256, "");
			numeric = true;
			Format(numbersInString, 256, "%s%c", numbersInString, buffer[i]);
		}
		else if(IsCharSpace(buffer[i])) continue;
		else if(numeric)
		{
			if((buffer[i] == 's' || buffer[i] == 'S') && (strlen(buffer) <= i+1 || buffer[i+1] == 'e' || buffer[i+1] == 'E' || IsCharSpace(buffer[i+1]) || buffer[i+1] == '!' || buffer[i+1] == '*'))
			{
				seconds = StringToInt(numbersInString);
				CountDown();
				return;
			}
			numeric = false;
		}
		else numeric = false;
	}
}

CountDown()
{
	if(countdownTimer != INVALID_HANDLE)
	{
		KillTimer(countdownTimer);
		countdownTimer = INVALID_HANDLE;
	}
	
	SetHudTextParams(-1.0, 0.08, 2.0, 255, 255, 255, 255, 0, 30.0, 0.0, 0.0);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i)) ShowHudText(i, 3, ">%i<", seconds);
	}
	
	countdownTimer = CreateTimer(1.0, Timer_Counter, _, TIMER_REPEAT);
}

public Action Timer_Counter(Handle timer)
{
	seconds--;
	if(seconds <= 0)
	{
		if(countdownTimer != INVALID_HANDLE)
		{
			KillTimer(countdownTimer);
			countdownTimer = INVALID_HANDLE;
		}
		return;
	}

	SetHudTextParams(-1.0, 0.08, 2.0, 255, 255, 255, 255, 0, 30.0, 0.0, 0.0);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i)) ShowHudText(i, 3, ">%i<", seconds);
	}
}

public Action Timer_Advertisements(Handle timer)
{
	char hintName[32];

	FormatEx(hintName, sizeof(hintName), "Hint_%i", currentHint);
	PrintToChatAll("%t", hintName);
	
	currentHint++;
	if(currentHint > hintsCount) currentHint = 1;
}

public void CreateFakeEvent(int client, const char[] sArgs)
{
	Handle serverEvent = CreateEvent("player_say", true);
	SetEventInt(serverEvent, "userid", GetClientUserId(client));
	SetEventString(serverEvent, "text", sArgs);
	FireEvent(serverEvent);
}
