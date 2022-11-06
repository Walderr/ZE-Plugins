#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <ClientPrefs>
#include <WeaponAttachmentAPI>

int beam;

bool bIsClientVIP[MAXPLAYERS+1];

bool tracerEnable[MAXPLAYERS+1];
int tracerColor[MAXPLAYERS+1][4];

char cTracerColor[MAXPLAYERS+1][16];

int red[4] = {255,0,0,255};
int white[4] = {255,255,255,255};
int green[4] = {0,255,0,255};
int blue[4] = {0,0,255,255};
int yellow[4] = {255,255,0,255};
int lightblue[4] = {0,255,255,255};
int pink[4] = {255,0,255,255};

Handle h_tracerCookie = INVALID_HANDLE;
Handle h_tracerColorCookie = INVALID_HANDLE;
Handle h_CustomColorCookie = INVALID_HANDLE;

public Plugin myinfo =
{
	name = "VIP",
	author = "Walderr",
	description = "VIP Функционал на сервере",
	version = "1.1",
	url = "http://www.jaze.ru/"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_vip", Command_VIP, "Открыть VIP меню");
	RegConsoleCmd("nvg", Command_NightVision, "Включить Прибор ночного видения");
	RegConsoleCmd("nightvision", Command_NightVision, "Включить Прибор ночного видения");
	RegConsoleCmd("sm_tcolor", Command_TColor, "Изменить цвет трассера");
	
	HookEvent("bullet_impact", Event_BulletImpact);
	
	h_tracerCookie = RegClientCookie("Tracer", "Трассер", CookieAccess_Private);
	h_tracerColorCookie = RegClientCookie("TracerColor", "Цвет Трассера", CookieAccess_Private);
	h_CustomColorCookie = RegClientCookie("CustomColor", "Свой Цвет Трассера", CookieAccess_Private);
}

public void OnMapStart()
{
	beam = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public void OnClientConnected(int client)
{
	bIsClientVIP[client] = false;
	
	tracerEnable[client] = false;
	tracerColor[client] = white;
	FormatEx(cTracerColor[client], sizeof(cTracerColor[]), "");
}

public void OnClientPostAdminCheck(int client)
{
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
	{
		bIsClientVIP[client] = true;
	}
}

public void OnClientCookiesCached(client)
{
	if(IsFakeClient(client)) return;
	
	char tempChar[64];
	GetClientCookie(client, h_tracerCookie, tempChar, sizeof(tempChar));
	tracerEnable[client] = StringToInt(tempChar) != 0;
	
	GetClientCookie(client, h_tracerColorCookie, tempChar, sizeof(tempChar));
	FormatEx(cTracerColor[client], sizeof(cTracerColor[]), tempChar);
	
	if(StrEqual(tempChar, "")) tracerColor[client] = white;
	else if(StrEqual(tempChar, "custom"))
	{
		GetClientCookie(client, h_CustomColorCookie, tempChar, sizeof(tempChar));
		
		char cutted[3][4];
		ExplodeString(tempChar, ",", cutted, 3 , 4);
		
		int rgb[4];
		rgb[0] = StringToInt(cutted[0]);
		rgb[1] = StringToInt(cutted[1]);
		rgb[2] = StringToInt(cutted[2]);
		rgb[3] = 255;
		
		tracerColor[client] = rgb;
	}
	else
	{
		if(StrEqual(tempChar, "white")) tracerColor[client] = white;
		else if(StrEqual(tempChar, "red")) tracerColor[client] = red;
		else if(StrEqual(tempChar, "green")) tracerColor[client] = green;
		else if(StrEqual(tempChar, "blue")) tracerColor[client] = blue;
		else if(StrEqual(tempChar, "yellow")) tracerColor[client] = yellow;
		else if(StrEqual(tempChar, "lightblue")) tracerColor[client] = lightblue;
		else if(StrEqual(tempChar, "pink")) tracerColor[client] = pink;
	}
}

public Action Event_BulletImpact(Handle event, const char[] name, bool dontBroadcast)
{
	// Получаем index игрока из его UserID.
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!bIsClientVIP[client] || !tracerEnable[client]) return;
	
	float clientPos[3], victimPos[3];

	if(WA_GetAttachmentPos(client, "muzzle_flash", clientPos)) 
	{
		victimPos[0] = GetEventFloat(event, "x");
		victimPos[1] = GetEventFloat(event, "y");
		victimPos[2] = GetEventFloat(event, "z");

		TE_SetupBeamPoints(clientPos, victimPos, beam, 0, 0, 0, 0.1, 0.1, 0.1, 0, 0.0, tracerColor[client], 0);
		TE_SendToAll();
	}
}

public Action Command_NightVision(int client, int args)
{
	if(!IsClientInGame(client)) return Plugin_Handled;

	if(!(GetUserFlagBits(client) & ADMFLAG_CUSTOM1))
	{
		PrintToChat(client, " \x09[VIP] ПНВ доступен только для VIP игроков!");
		return Plugin_Handled;
	}

	if(GetEntProp(client, Prop_Send, "m_bNightVisionOn") == 0) SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);
	else SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);
	
	ClientCommand(client, "playgamesound items/nvg_off.wav");
	
	return Plugin_Handled;
}

public Action Command_TColor(int client, int args)
{
	if(!(GetUserFlagBits(client) & ADMFLAG_CUSTOM1))
	{
		PrintToChat(client, " \x09[TColor] Выбор цвета трассеров доступен только для VIP игроков!");
		return Plugin_Handled;
	}

	if(args < 3)
	{
		PrintToChat(client, " \x09[TColor] Введите 3 цвета: !tcolor 'r' 'g' 'b'.");
		return Plugin_Handled;
	}
	
	char arg1[4], arg2[4], arg3[4];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	
	int rgb[4];
	
	rgb[0] = StringToInt(arg1);
	rgb[1] = StringToInt(arg2);
	rgb[2] = StringToInt(arg3);
	rgb[3] = 255;
	
	if(rgb[0] < 0 || rgb[1] < 0 || rgb[2] < 0 || rgb[0] > 255 || rgb[1] > 255 || rgb[2] > 255)
	{
		PrintToChat(client, " \x09[TColor] Значения должны быть в диапазоне 0-255!");
		return Plugin_Handled;
	}
	
	FormatEx(cTracerColor[client], sizeof(cTracerColor[]), "custom");
	SetClientCookie(client, h_tracerColorCookie, cTracerColor[client]);
	
	tracerColor[client] = rgb;
	
	char colorToCookie[32];
	FormatEx(colorToCookie, sizeof(colorToCookie), "%i,%i,%i", rgb[0], rgb[1], rgb[2]);
	SetClientCookie(client, h_CustomColorCookie, colorToCookie);
	
	PrintToChat(client, " \x09[TColor] Вы выбрали цвета: %i, %i, %i!", rgb[0], rgb[1], rgb[2]);
	
	return Plugin_Handled;
}

public Action Command_VIP(int client, int args)
{
	ShowVIPMenu(client);
	return Plugin_Handled;
}

void ShowVIPMenu(int client)
{
	if(!(GetUserFlagBits(client) & ADMFLAG_CUSTOM1))
	{
		ClientCommand(client, "playgamesound buttons/button11.wav");
		
		Panel noAccessPanel = new Panel();
		noAccessPanel.SetTitle("VIP Меню:");
		
		noAccessPanel.DrawItem("", ITEMDRAW_SPACER);
		noAccessPanel.DrawText("У вас отсутствует VIP статус!\nКупить можно на сайте: jaze.ru");
		noAccessPanel.DrawItem("", ITEMDRAW_SPACER);
		noAccessPanel.CurrentKey = GetMaxPageItems(noAccessPanel.Style);
		noAccessPanel.DrawItem("Выход", ITEMDRAW_CONTROL);
		noAccessPanel.Send(client, Handler_DoNothing, 180);
	}
	else
	{
		Menu vip = new Menu(VIPHandler);
		vip.SetTitle("VIP Меню:");
		vip.AddItem("sm_chat", "Настройки чата");
		vip.AddItem("tracer", "Трассеры от выстрелов");
		vip.AddItem("nightvision", "Прибор ночного виденья (nvg)");
		vip.AddItem("skin", "Выбрать скин игрока");
		vip.AddItem("rename", "Переименовать оружие", ITEMDRAW_DISABLED);
		vip.AddItem("", "", ITEMDRAW_SPACER);
		
		vip.AddItem("", "Постоянные бонусы:\nДеньги: 16000$\nЗдоровье человека: +50% (до 15.09)\nЗдоровье зомби: +33%\nVIP чат: '$текст' в чат\nПодсветка материй на карте");
		
		vip.Display(client, 180);
	}
}

public int Handler_DoNothing(Menu menu, MenuAction action, int param1, int param2) {}

public int VIPHandler(Menu vip, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) 
	{
		char item[16];
		vip.GetItem(option, item, sizeof(item));
		
		if(StrEqual(item, "sm_chat")) FakeClientCommand(client, "%s", item);
		
		else if(StrEqual(item, "tracer")) ShowTracerMenu(client);
		
		else if(StrEqual(item, "skin")) FakeClientCommand(client, "sm_skin");
		
		else if(StrEqual(item, "nightvision"))
		{
			FakeClientCommand(client, "%s", item);
			ShowVIPMenu(client);
		}
		else ShowVIPMenu(client);
	}
	else if(action == MenuAction_End) delete vip;
}

void ShowTracerMenu(int client)
{
	Menu tracerMenu = new Menu(TracerHandler);
	tracerMenu.SetTitle("Трассеры:");
	
	if(tracerEnable[client]) tracerMenu.AddItem("enable", "Трассеры: [вкл]\nЦвет трассеров:");
	else tracerMenu.AddItem("enable", "Трассеры: [выкл]\nЦвет трассеров:");
	
	if(StrEqual(cTracerColor[client], "custom")) tracerMenu.AddItem("custom", "Свой", ITEMDRAW_DISABLED);
	
	if(StrEqual(cTracerColor[client], "white") || StrEqual(cTracerColor[client], "")) tracerMenu.AddItem("white", "Белый", ITEMDRAW_DISABLED);
	else tracerMenu.AddItem("white", "Белый");
	
	if(StrEqual(cTracerColor[client], "red")) tracerMenu.AddItem("red", "Красный", ITEMDRAW_DISABLED);
	else tracerMenu.AddItem("red", "Красный");
	
	if(StrEqual(cTracerColor[client], "green")) tracerMenu.AddItem("green", "Зелёный", ITEMDRAW_DISABLED);
	else tracerMenu.AddItem("green", "Зелёный");
	
	if(StrEqual(cTracerColor[client], "blue")) tracerMenu.AddItem("blue", "Синий", ITEMDRAW_DISABLED);
	else tracerMenu.AddItem("blue", "Синий");
	
	if(StrEqual(cTracerColor[client], "yellow")) tracerMenu.AddItem("yellow", "Жёлтый", ITEMDRAW_DISABLED);
	else tracerMenu.AddItem("yellow", "Жёлтый");
	
	if(StrEqual(cTracerColor[client], "lightblue")) tracerMenu.AddItem("lightblue", "Голубой", ITEMDRAW_DISABLED);
	else tracerMenu.AddItem("lightblue", "Голубой");
	
	if(StrEqual(cTracerColor[client], "pink")) tracerMenu.AddItem("pink", "Розовый", ITEMDRAW_DISABLED);
	else tracerMenu.AddItem("pink", "Розовый");
	
	tracerMenu.ExitBackButton = true;
	tracerMenu.Display(client, 180);
}

public int TracerHandler(Menu tracerMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) 
	{
		char item[16];
		tracerMenu.GetItem(option, item, sizeof(item));
		
		if(StrEqual(item, "enable"))
		{
			tracerEnable[client] = !tracerEnable[client];
			
			char cookie[2];
			FormatEx(cookie, sizeof(cookie), "%i", tracerEnable[client]);
			SetClientCookie(client, h_tracerCookie, cookie);
		}
		else
		{
			FormatEx(cTracerColor[client], sizeof(cTracerColor[]), "%s", item);
			SetClientCookie(client, h_tracerColorCookie, cTracerColor[client]);
			
			if(StrEqual(item, "white")) tracerColor[client] = white;
			else if(StrEqual(item, "red")) tracerColor[client] = red;
			else if(StrEqual(item, "green")) tracerColor[client] = green;
			else if(StrEqual(item, "blue")) tracerColor[client] = blue;
			else if(StrEqual(item, "yellow")) tracerColor[client] = yellow;
			else if(StrEqual(item, "lightblue")) tracerColor[client] = lightblue;
			else if(StrEqual(item, "pink")) tracerColor[client] = pink;
		}
		
		ShowTracerMenu(client);
	}
	else if(action == MenuAction_Cancel) 
	{
		if(option == MenuCancel_ExitBack) ShowVIPMenu(client);
	}
	else if(action == MenuAction_End) delete tracerMenu;
}
