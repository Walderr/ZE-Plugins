#include <sdktools>
#include <cstrike>
#include <ClientPrefs>

char defaultModel[128] = "models/player/custom_player/kuristaja/re6/chris/chrisv4.mdl";
char defaultArms[128] = "models/player/custom_player/kuristaja/re6/chris/chris_arms.mdl";
char defaultName[16] = "Chris";

bool bIsClientVIP[MAXPLAYERS+1];
bool bIsClientSkinOwner[MAXPLAYERS+1];
bool bIsClientEventWinner[MAXPLAYERS+1];
bool infectionStarted;

char humanModel[MAXPLAYERS+1][256];
char humanArms[MAXPLAYERS+1][256];
char choosenModelName[MAXPLAYERS+1][32];

Handle h_ModelCookie = INVALID_HANDLE;
Handle h_ArmsCookie = INVALID_HANDLE;
Handle h_NameCookie = INVALID_HANDLE;

public Plugin myinfo =
{
	name = "VIP - Skins",
	author = "Walderr",
	description = "Модуль скинов для VIP плагина",
	version = "1.0",
	url = "http://www.jaze.ru/"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_zclass", Command_Skin, "Открыть меню выбора скинов");
	RegConsoleCmd("sm_class", Command_Skin, "Открыть меню выбора скинов");
	RegConsoleCmd("sm_skin", Command_Skin, "Открыть меню выбора скинов");
	RegConsoleCmd("sm_model", Command_Skin, "Открыть меню выбора скинов");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	
	// Куки
	h_ModelCookie = RegClientCookie("ModelPath", "Путь до модели", CookieAccess_Private);
	h_ArmsCookie = RegClientCookie("ArmsPath", "Путь до рук", CookieAccess_Private);
	h_NameCookie = RegClientCookie("ModelName", "Название выбранной модели", CookieAccess_Private);
}

public void OnClientConnected(int client)
{
	bIsClientVIP[client] = false;
	bIsClientSkinOwner[client] = false;
	bIsClientEventWinner[client] = false;
	
	FormatEx(humanModel[client], sizeof(humanModel[]), "");
	FormatEx(humanArms[client], sizeof(humanArms[]), "");
	FormatEx(choosenModelName[client], sizeof(choosenModelName[]), "");
}

public void OnClientPostAdminCheck(int client)
{
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
	{
		bIsClientVIP[client] = true;
	}
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM2)
	{
		bIsClientSkinOwner[client] = true;
	}
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM5)
	{
		bIsClientEventWinner[client] = true;
	}
}

public void OnClientCookiesCached(client)
{
	if(IsFakeClient(client)) return;
	
	char tempChar[256];
	
	GetClientCookie(client, h_ModelCookie, tempChar, sizeof(tempChar));
	if(!StrEqual(tempChar, "")) FormatEx(humanModel[client], sizeof(humanModel[]), tempChar);
	
	GetClientCookie(client, h_ArmsCookie, tempChar, sizeof(tempChar));
	if(!StrEqual(tempChar, "")) FormatEx(humanArms[client], sizeof(humanArms[]), tempChar);
	
	GetClientCookie(client, h_NameCookie, tempChar, sizeof(tempChar));
	if(!StrEqual(tempChar, "")) FormatEx(choosenModelName[client], sizeof(choosenModelName[]), tempChar);
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	infectionStarted = false;
}

public Action Event_RoundFreezeEnd(Handle event, const char[] name, bool dontBroadcast)
{
	CreateTimer(GetConVarFloat(FindConVar("ze_infect_time")), InfectionTimer, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action InfectionTimer(Handle timer)
{
	infectionStarted = true;
}

public Action Command_Skin(int client, int args)
{
	ShowSkinMenu(client);
	return Plugin_Handled;
}

void ShowSkinMenu(int client)
{
	Menu skin = new Menu(SkinHandler);
	skin.SetTitle("Выбор модели игрока:");
	
	char humanString[128], zombieString[128];
	
	FormatEx(humanString, sizeof(humanString), "Человек:\n  ☑ %s%s", choosenModelName[client], IsModelAvailable(client) ? "" : " [Недоступна]");
	FormatEx(zombieString, sizeof(zombieString), "Зомби:\n  ☑ Случайный зомби\n ");
	
	skin.AddItem("", humanString);
	skin.AddItem("", zombieString);
	
	skin.AddItem("VIP", "VIP меню");
	
	skin.Display(client, 180);
}

public int SkinHandler(Menu skin, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) 
	{
		if(option == 0) ShowHumanMenu(client);
		else if(option == 1) ShowSkinMenu(client);
		else if(option == 2) FakeClientCommand(client, "sm_vip");
	}
	else if(action == MenuAction_End) delete skin;
}

void ShowHumanMenu(int client)
{
	Menu human = new Menu(HumanHandler);
	human.SetTitle("Выбор модели человека:");
	
	if(StrEqual(choosenModelName[client], "Chris")) human.AddItem("Chris", "Стандартный - Chris", ITEMDRAW_DISABLED);
	else human.AddItem("Chris", "Стандартный - Chris");
	
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM5)
	{
		if(StrEqual(choosenModelName[client], "Beef Boss")) human.AddItem("BeefBoss", "Специальный - Beef Boss", ITEMDRAW_DISABLED);
		else human.AddItem("BeefBoss", "Специальный - Beef Boss");
	}
	
	if(GetUserFlagBits(client) & ADMFLAG_GENERIC)
	{
		if(StrEqual(choosenModelName[client], "Carrie")) human.AddItem("Carrie", "Админ - Carrie", ITEMDRAW_DISABLED);
		else human.AddItem("Carrie", "Админ - Carrie");
	}
	
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM2)
	{
		char steamid[32];
		GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid), false);
	
		if(StrEqual(steamid, "STEAM_1:1:50367913"))
		{
			if(StrEqual(choosenModelName[client], "Haku")) human.AddItem("Haku", "Личный - Haku", ITEMDRAW_DISABLED);
			else human.AddItem("Haku", "Личный - Haku");
		}
		else if(StrEqual(steamid, "STEAM_1:0:33795914"))
		{
			if(StrEqual(choosenModelName[client], "Cybernetic")) human.AddItem("Cybernetic", "Личный - Cybernetic", ITEMDRAW_DISABLED);
			else human.AddItem("Cybernetic", "Личный - Cybernetic");
		}
		else if(StrEqual(steamid, "STEAM_1:0:52442965"))
		{
			if(StrEqual(choosenModelName[client], "Toobie")) human.AddItem("Toobie", "Личный - Toobie", ITEMDRAW_DISABLED);
			else human.AddItem("Toobie", "Личный - Toobie");
		}
	}
	
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
	{
		if(StrEqual(choosenModelName[client], "Coconut")) human.AddItem("Coconut", "VIP - Coconut", ITEMDRAW_DISABLED);
		else human.AddItem("Coconut", "VIP - Coconut");
		
		if(StrEqual(choosenModelName[client], "Chokola")) human.AddItem("Chokola", "VIP - Chokola", ITEMDRAW_DISABLED);
		else human.AddItem("Chokola", "VIP - Chokola");
		
		if(StrEqual(choosenModelName[client], "Kanzaki Ranko")) human.AddItem("KanzakiRanko", "VIP - Kanzaki Ranko", ITEMDRAW_DISABLED);
		else human.AddItem("KanzakiRanko", "VIP - Kanzaki Ranko");
		
		if(StrEqual(choosenModelName[client], "Hatsune Miku")) human.AddItem("HatsuneMiku", "VIP - Hatsune Miku", ITEMDRAW_DISABLED);
		else human.AddItem("HatsuneMiku", "VIP - Hatsune Miku");
	}
	
	human.ExitBackButton = true;
	human.Display(client, 180);
}

public int HumanHandler(Menu human, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) 
	{
		char item[16];
		human.GetItem(option, item, sizeof(item));
		
		int team = GetClientTeam(client);
		
		if(StrEqual(item, "Chris"))
		{
			if(IsPlayerAlive(client) && team == CS_TEAM_CT && !infectionStarted)
			{
				SetEntityModel(client, "models/player/custom_player/kuristaja/re6/chris/chrisv4.mdl");
				SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/kuristaja/re6/chris/chris_arms.mdl");
			}
			
			FormatEx(humanModel[client], sizeof(humanModel[]), "models/player/custom_player/kuristaja/re6/chris/chrisv4.mdl");
			FormatEx(humanArms[client], sizeof(humanArms[]), "models/player/custom_player/kuristaja/re6/chris/chris_arms.mdl");
			FormatEx(choosenModelName[client], sizeof(choosenModelName[]), "Chris");
		}
		else if(StrEqual(item, "BeefBoss"))
		{
			if(IsPlayerAlive(client) && team == CS_TEAM_CT && !infectionStarted)
			{
				SetEntityModel(client, "models/player/custom_player/napas/garrys/beefboss_pm_beefboss_v2.mdl");
				SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/kuristaja/re6/chris/chris_arms.mdl");
			}
			
			FormatEx(humanModel[client], sizeof(humanModel[]), "models/player/custom_player/napas/garrys/beefboss_pm_beefboss_v2.mdl");
			FormatEx(humanArms[client], sizeof(humanArms[]), "models/player/custom_player/kuristaja/re6/chris/chris_arms.mdl");
			FormatEx(choosenModelName[client], sizeof(choosenModelName[]), "Beef Boss");
		}
		else if(StrEqual(item, "Carrie"))
		{
			if(IsPlayerAlive(client) && team == CS_TEAM_CT && !infectionStarted)
			{
				SetEntityModel(client, "models/player/custom_player/kuristaja/cso2/carrie/carrie.mdl");
				SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/kuristaja/cso2/carrie/carrie_arms.mdl");
			}
			
			FormatEx(humanModel[client], sizeof(humanModel[]), "models/player/custom_player/kuristaja/cso2/carrie/carrie.mdl");
			FormatEx(humanArms[client], sizeof(humanArms[]), "models/player/custom_player/kuristaja/cso2/carrie/carrie_arms.mdl");
			FormatEx(choosenModelName[client], sizeof(choosenModelName[]), "Carrie");
		}
		else if(StrEqual(item, "Haku"))
		{
			if(IsPlayerAlive(client) && team == CS_TEAM_CT && !infectionStarted)
			{
				SetEntityModel(client, "models/player/custom_player/monsterko/haku_wedding_dress/haku_v3.mdl");
				SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/monsterko/haku_wedding_dress/haku_arms.mdl");
			}
			
			FormatEx(humanModel[client], sizeof(humanModel[]), "models/player/custom_player/monsterko/haku_wedding_dress/haku_v3.mdl");
			FormatEx(humanArms[client], sizeof(humanArms[]), "models/player/custom_player/monsterko/haku_wedding_dress/haku_arms.mdl");
			FormatEx(choosenModelName[client], sizeof(choosenModelName[]), "Haku");
		}
		else if(StrEqual(item, "Cybernetic"))
		{
			if(IsPlayerAlive(client) && team == CS_TEAM_CT && !infectionStarted)
			{
				SetEntityModel(client, "models/player/custom_player/maoling/closeronline/cybernetic/cybernetic.mdl");
				SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/maoling/closeronline/cybernetic/cybernetic_arms.mdl");
			}
			
			FormatEx(humanModel[client], sizeof(humanModel[]), "models/player/custom_player/maoling/closeronline/cybernetic/cybernetic.mdl");
			FormatEx(humanArms[client], sizeof(humanArms[]), "models/player/custom_player/maoling/closeronline/cybernetic/cybernetic_arms.mdl");
			FormatEx(choosenModelName[client], sizeof(choosenModelName[]), "Cybernetic");
		}
		else if(StrEqual(item, "Toobie"))
		{
			if(IsPlayerAlive(client) && team == CS_TEAM_CT && !infectionStarted)
			{
				SetEntityModel(client, "models/player/custom_player/gkuo88/nier/toobie_fix3/toobie.mdl");
				SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/gkuo88/nier/toobie_fix/toobie_hands.mdl");
			}
			
			FormatEx(humanModel[client], sizeof(humanModel[]), "models/player/custom_player/gkuo88/nier/toobie_fix3/toobie.mdl");
			FormatEx(humanArms[client], sizeof(humanArms[]), "models/player/custom_player/gkuo88/nier/toobie_fix/toobie_hands.mdl");
			FormatEx(choosenModelName[client], sizeof(choosenModelName[]), "Toobie");
		}
		else if(StrEqual(item, "Coconut"))
		{
			if(IsPlayerAlive(client) && team == CS_TEAM_CT && !infectionStarted)
			{
				SetEntityModel(client, "models/player/custom_player/bbs_93x_net_2016/coconut/update_2016_12_30/coconut.mdl");
				SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/bbs_93x_net_2016/coconut/update_2016_12_30/coconuthands.mdl");
			}
			
			FormatEx(humanModel[client], sizeof(humanModel[]), "models/player/custom_player/bbs_93x_net_2016/coconut/update_2016_12_30/coconut.mdl");
			FormatEx(humanArms[client], sizeof(humanArms[]), "models/player/custom_player/bbs_93x_net_2016/coconut/update_2016_12_30/coconuthands.mdl");
			FormatEx(choosenModelName[client], sizeof(choosenModelName[]), "Coconut");
		}
		else if(StrEqual(item, "Chokola"))
		{
			if(IsPlayerAlive(client) && team == CS_TEAM_CT && !infectionStarted)
			{
				SetEntityModel(client, "models/player/custom_player/kodua/chocola/chocola.mdl");
				SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/kodua/chocola/chocola_arms.mdl");
			}
			
			FormatEx(humanModel[client], sizeof(humanModel[]), "models/player/custom_player/kodua/chocola/chocola.mdl");
			FormatEx(humanArms[client], sizeof(humanArms[]), "models/player/custom_player/kodua/chocola/chocola_arms.mdl");
			FormatEx(choosenModelName[client], sizeof(choosenModelName[]), "Chokola");
		}
		else if(StrEqual(item, "KanzakiRanko"))
		{
			if(IsPlayerAlive(client) && team == CS_TEAM_CT && !infectionStarted)
			{
				SetEntityModel(client, "models/player/custom_player/maoling/idolm@ster/kanzaki_ranko/kanzaki.mdl");
				SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/maoling/idolm@ster/kanzaki_ranko/kanzaki_arms.mdl");
			}
			
			FormatEx(humanModel[client], sizeof(humanModel[]), "models/player/custom_player/maoling/idolm@ster/kanzaki_ranko/kanzaki.mdl");
			FormatEx(humanArms[client], sizeof(humanArms[]), "models/player/custom_player/maoling/idolm@ster/kanzaki_ranko/kanzaki_arms.mdl");
			FormatEx(choosenModelName[client], sizeof(choosenModelName[]), "Kanzaki Ranko");
		}
		else if(StrEqual(item, "HatsuneMiku"))
		{
			if(IsPlayerAlive(client) && team == CS_TEAM_CT && !infectionStarted)
			{
				SetEntityModel(client, "models/player/custom_player/maoling/vocaloid/hatsune_miku/monsterko/tda/miku_tda.mdl");
				SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/maoling/vocaloid/hatsune_miku/monsterko/tda/miku_arms_tda.mdl");
			}
			
			FormatEx(humanModel[client], sizeof(humanModel[]), "models/player/custom_player/maoling/vocaloid/hatsune_miku/monsterko/tda/miku_tda.mdl");
			FormatEx(humanArms[client], sizeof(humanArms[]), "models/player/custom_player/maoling/vocaloid/hatsune_miku/monsterko/tda/miku_arms_tda.mdl");
			FormatEx(choosenModelName[client], sizeof(choosenModelName[]), "Hatsune Miku");
		}
		
		SetClientCookie(client, h_ModelCookie, humanModel[client]);
		SetClientCookie(client, h_ArmsCookie, humanArms[client]);
		SetClientCookie(client, h_NameCookie, choosenModelName[client]);
		
		if(infectionStarted) PrintToChat(client, " \x09[Models] Класс изменится в следующем раунде.");
		
		ShowHumanMenu(client);
	}
	else if(action == MenuAction_Cancel) 
	{
		if(option == MenuCancel_ExitBack) ShowSkinMenu(client);
	}
	else if(action == MenuAction_End) delete human;
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{ 
	int client = GetClientOfUserId(GetEventInt(event, "userid")); 
	CreateTimer(0.2, SetModel, client);
}

public Action SetModel(Handle timer, any client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT)
	{
		// Если у клиента не задана модель
		if(StrEqual(humanModel[client], ""))
		{
			FormatEx(humanModel[client], sizeof(humanModel[]), defaultModel);
			FormatEx(humanArms[client], sizeof(humanArms[]), defaultArms);
			FormatEx(choosenModelName[client], sizeof(choosenModelName[]), defaultName);
		}
		
		// Если у игрока имеется сохранённая модель, но нет привилегий, устанавливаем стандартную.
		if(!IsModelAvailable(client))
		{
			SetDefaultModel(client);
			return;
		}
		
		// Устанавливаем игроку модель.
		if(IsModelPrecached(humanModel[client]))
		{
			SetEntityModel(client, humanModel[client]);
			SetEntPropString(client, Prop_Send, "m_szArmsModel", humanArms[client]);
		}
		// Иначе если модели нет на сервере, сбрасываем игроку модель.
		else
		{
			LogError("Model %s (player: %N) Not Precached!", humanModel[client], client);
			
			PrintToChat(client, " [Ошибка] Вашей модели нет на сервере! Устанавливаю стандартную.");
			
			// Ставим игроку стандартную модель и сбрасываем куки.
			FormatEx(humanModel[client], sizeof(humanModel[]), defaultModel);
			FormatEx(humanArms[client], sizeof(humanArms[]), defaultArms);
			FormatEx(choosenModelName[client], sizeof(choosenModelName[]), defaultName);
		
			SetClientCookie(client, h_ModelCookie, humanModel[client]);
			SetClientCookie(client, h_ArmsCookie, humanArms[client]);
			SetClientCookie(client, h_NameCookie, choosenModelName[client]);
		}
	}
}

void SetDefaultModel(int client)
{
	if(IsModelPrecached(defaultModel))
	{
		SetEntityModel(client, defaultModel);
		SetEntPropString(client, Prop_Send, "m_szArmsModel", defaultArms);
	}
	else LogError("Model %s (player: %N) Not Precached! (SetDefaultModel)", defaultModel, client);
}

IsModelAvailable(int client)
{
	if(StrEqual(choosenModelName[client], "Chris")) return true;
	
	// Если у игрока выбрана модель победителя ивента
	else if(StrEqual(choosenModelName[client], "Beef Boss"))
	{
		if(bIsClientEventWinner[client]) return true;
	}
	// Если у игрока выбрана модель администратора
	else if(StrEqual(choosenModelName[client], "Carrie"))
	{
		if(GetUserFlagBits(client) & ADMFLAG_GENERIC) return true;
	}
	// Если у игрока выбрана личная модель
	else if(StrEqual(choosenModelName[client], "Haku") || StrEqual(choosenModelName[client], "Cybernetic") || StrEqual(choosenModelName[client], "Toobie"))
	{
		if(bIsClientSkinOwner[client]) return true;
	}
	// Если у игрока выбрана VIP модель
	else if(StrEqual(choosenModelName[client], "Coconut") || StrEqual(choosenModelName[client], "Chokola") ||
	StrEqual(choosenModelName[client], "Kanzaki Ranko") || StrEqual(choosenModelName[client], "Hatsune Miku"))
	{
		if(bIsClientVIP[client]) return true;
	}

	return false;
}

//===============================================================================

public OnMapStart() 
{
	// Chris
	
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/re6/chris/chrisv4.phy"); 
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/re6/chris/chrisv4.vvd");
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/re6/chris/chrisv4.dx90.vtx"); 
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/re6/chris/chrisv4.mdl");
	
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/re6/chris/chris_arms.dx90.vtx"); 
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/re6/chris/chris_arms.mdl"); 
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/re6/chris/chris_arms.vvd"); 
	
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_11hair.vmt"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_11hair.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_11hair_normal.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_11hair2.vmt"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0210_20jacket.vmt"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0210_20jacket.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0210_20jacket_normal.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl_earlight.vmt"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl_earlight.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_00eye.vmt"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_00eye.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_00eye_normal.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_00eyelash.vmt"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_00eyelash.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_00face.vmt"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_00face.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_00face_normal.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_00face2.vmt"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_02armor.vmt"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_02armor.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_02armor_normal.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_03pants.vmt"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_03pants.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_03pants_normal.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_04eqipment.vmt"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_04eqipment.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_04eqipment_normal.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_05knife.vmt"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_05knife.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_05knife_normal.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_07hand.vmt"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_07hand.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_07hand_normal.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_08hair.vmt"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_08hair.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_08hair_normal.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_08hair2.vmt"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_09hair.vmt"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_09hair.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_09hair_normal.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_09hair2.vmt"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_10hair.vmt"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_10hair.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_10hair_normal.vtf"); 
	AddFileToDownloadsTable("materials/models/player/kuristaja/re6/chris/pl0200_10hair2.vmt"); 
	
	PrecacheModel("models/player/custom_player/kuristaja/re6/chris/chrisv4.mdl", true); 
	PrecacheModel("models/player/custom_player/kuristaja/re6/chris/chris_arms.mdl", true); 
	
	// Coconut
	
	AddFileToDownloadsTable("models/player/custom_player/bbs_93x_net_2016/coconut/update_2016_12_30/coconut.dx90.vtx");
	AddFileToDownloadsTable("models/player/custom_player/bbs_93x_net_2016/coconut/update_2016_12_30/coconut.mdl");
	AddFileToDownloadsTable("models/player/custom_player/bbs_93x_net_2016/coconut/update_2016_12_30/coconut.phy");
	AddFileToDownloadsTable("models/player/custom_player/bbs_93x_net_2016/coconut/update_2016_12_30/coconut.vvd");
	
	AddFileToDownloadsTable("models/player/custom_player/bbs_93x_net_2016/coconut/update_2016_12_30/coconuthands.dx90.vtx");
	AddFileToDownloadsTable("models/player/custom_player/bbs_93x_net_2016/coconut/update_2016_12_30/coconuthands.mdl");
	AddFileToDownloadsTable("models/player/custom_player/bbs_93x_net_2016/coconut/update_2016_12_30/coconuthands.vvd");
	
	AddFileToDownloadsTable("materials/models/player/custom_player/bbs_93x_net_2016/coconut/body.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/bbs_93x_net_2016/coconut/body.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/bbs_93x_net_2016/coconut/bodyn.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/bbs_93x_net_2016/coconut/co_face.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/bbs_93x_net_2016/coconut/co_face.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/bbs_93x_net_2016/coconut/co_hair.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/bbs_93x_net_2016/coconut/co_hair.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/bbs_93x_net_2016/coconut/eyes.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/bbs_93x_net_2016/coconut/eyes.vtf");
	
	PrecacheModel("models/player/custom_player/bbs_93x_net_2016/coconut/update_2016_12_30/coconut.mdl", true);
	PrecacheModel("models/player/custom_player/bbs_93x_net_2016/coconut/update_2016_12_30/coconuthands.mdl", true);
	
	// Chokola
	
	AddFileToDownloadsTable("models/player/custom_player/kodua/chocola/chocola.mdl");
	AddFileToDownloadsTable("models/player/custom_player/kodua/chocola/chocola.phy");
	AddFileToDownloadsTable("models/player/custom_player/kodua/chocola/chocola.vvd");
	
	AddFileToDownloadsTable("models/player/custom_player/kodua/chocola/chocola.dx90.vtx");
	AddFileToDownloadsTable("models/player/custom_player/kodua/chocola/chocola_arms.mdl");
	AddFileToDownloadsTable("models/player/custom_player/kodua/chocola/chocola_arms.vvd");
	AddFileToDownloadsTable("models/player/custom_player/kodua/chocola/chocola_arms.dx90.vtx");
	
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/bow.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/Dress188_accKamiSub.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/Dress188_accShippo.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/Dress188_accUde.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/Dress188_head.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/Dress188_onep1.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/Dress188_onep2.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/Dress188_shoe.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/eye.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/eyes.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/face.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/face.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/Face008_Mayu (Instance)_(-81352).vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/Face008_Mouth (Instance)_(-81358).vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/Face008_SkinAlpha (Instance)_(-81354).vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/Face008_SkinHi (Instance)_(-81350).vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/hair.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/Hair_Aho006a-HairAho (Instance)_(-84002).vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/hair_f.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/hair_r.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/Hair_R071-HairAcc (Instance)_(-81482).vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/hair_twin.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/hair2.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/HairAho.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/hairEars.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/hairEars2.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/hands.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/headset.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/Mayu.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/mouth.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/onep1.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/onep2.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/pants.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/pants.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/shoe.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/skin.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/skin.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/skin2.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/SkinAlpha.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/SkinHi.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/stkg.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/stkg.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/kodua/chocola/tail.vmt");
	
	PrecacheModel("models/player/custom_player/kodua/chocola/chocola.mdl", true);
	PrecacheModel("models/player/custom_player/kodua/chocola/chocola_arms.mdl", true);
	
	// Kanzaki Ranko
	
	AddFileToDownloadsTable("models/player/custom_player/maoling/idolm@ster/kanzaki_ranko/kanzaki.mdl");
	AddFileToDownloadsTable("models/player/custom_player/maoling/idolm@ster/kanzaki_ranko/kanzaki.phy");
	AddFileToDownloadsTable("models/player/custom_player/maoling/idolm@ster/kanzaki_ranko/kanzaki.vvd");
	AddFileToDownloadsTable("models/player/custom_player/maoling/idolm@ster/kanzaki_ranko/kanzaki.dx90.vtx");
	
	AddFileToDownloadsTable("models/player/custom_player/maoling/idolm@ster/kanzaki_ranko/kanzaki_arms.mdl");
	AddFileToDownloadsTable("models/player/custom_player/maoling/idolm@ster/kanzaki_ranko/kanzaki_arms.vvd");
	AddFileToDownloadsTable("models/player/custom_player/maoling/idolm@ster/kanzaki_ranko/kanzaki_arms.dx90.vtx");
	
	AddFileToDownloadsTable("materials/maoling/player/idolm@ster/kanzaki_ranko/f_007f44.vmt");
	AddFileToDownloadsTable("materials/maoling/player/idolm@ster/kanzaki_ranko/f_007f44.vtf");
	AddFileToDownloadsTable("materials/maoling/player/idolm@ster/kanzaki_ranko/f_007f45.vmt");
	AddFileToDownloadsTable("materials/maoling/player/idolm@ster/kanzaki_ranko/f_007f45.vtf");
	AddFileToDownloadsTable("materials/maoling/player/idolm@ster/kanzaki_ranko/f_007f42.vtf");
	AddFileToDownloadsTable("materials/maoling/player/idolm@ster/kanzaki_ranko/f_007f42.vtf");
	
	PrecacheModel("models/player/custom_player/maoling/idolm@ster/kanzaki_ranko/kanzaki.mdl", true);
	PrecacheModel("models/player/custom_player/maoling/idolm@ster/kanzaki_ranko/kanzaki_arms.mdl", true);
	
	// Carrie
	
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/cso2/carrie/carrie.dx90.vtx");
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/cso2/carrie/carrie.mdl");
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/cso2/carrie/carrie.phy");
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/cso2/carrie/carrie.vvd");
	
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/cso2/carrie/carrie_arms.dx90.vtx");
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/cso2/carrie/carrie_arms.mdl");
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/cso2/carrie/carrie_arms.vvd");
	
	AddFileToDownloadsTable("materials/models/player/kuristaja/cso2/carrie/ct_carrie.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/cso2/carrie/ct_carrie.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/cso2/carrie/ct_carrie_face_eyelashes.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/cso2/carrie/ct_carrie_face_eyelashes.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/cso2/carrie/ct_carrie_glove.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/cso2/carrie/ct_carrie_glove.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/cso2/carrie/ct_carrie_glove_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/cso2/carrie/ct_carrie_hair.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/cso2/carrie/ct_carrie_hair.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/cso2/carrie/ct_carrie_hair_alp.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/cso2/carrie/ct_carrie_hair_alp_inv.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/cso2/carrie/ct_carrie_hair_inv.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/cso2/carrie/ct_carrie_hair_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/cso2/carrie/ct_carrie_hand.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/cso2/carrie/ct_carrie_hand.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/cso2/carrie/ct_carrie_hand_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/cso2/carrie/ct_carrie_normal.vtf");
	
	PrecacheModel("models/player/custom_player/kuristaja/cso2/carrie/carrie.mdl", true);
	PrecacheModel("models/player/custom_player/kuristaja/cso2/carrie/carrie_arms.mdl", true);
	
	// Hatsune Miku
	
	AddFileToDownloadsTable("models/player/custom_player/maoling/vocaloid/hatsune_miku/monsterko/tda/miku_arms_tda.vvd");
	AddFileToDownloadsTable("models/player/custom_player/maoling/vocaloid/hatsune_miku/monsterko/tda/miku_tda.dx90.vtx");
	AddFileToDownloadsTable("models/player/custom_player/maoling/vocaloid/hatsune_miku/monsterko/tda/miku_tda.mdl");
	AddFileToDownloadsTable("models/player/custom_player/maoling/vocaloid/hatsune_miku/monsterko/tda/miku_tda.phy");
	
	AddFileToDownloadsTable("models/player/custom_player/maoling/vocaloid/hatsune_miku/monsterko/tda/miku_tda.vvd");
	AddFileToDownloadsTable("models/player/custom_player/maoling/vocaloid/hatsune_miku/monsterko/tda/miku_arms_tda.dx90.vtx");
	AddFileToDownloadsTable("models/player/custom_player/maoling/vocaloid/hatsune_miku/monsterko/tda/miku_arms_tda.mdl");
	
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/tech.vtf");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/tech_illum.vtf");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/tie.vmt");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/wing.vmt");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/wing.vtf");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/basewarp.vtf");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/body.vmt");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/body.vtf");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/body_illum.vtf");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/body_misc.vmt");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/body_misc.vtf");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/eye.vmt");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/face.vmt");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/face.vtf");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/face_misc.vmt");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/facewarp.vtf");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/hair.vmt");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/hair.vtf");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/hair_illum.vtf");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/hairwarp.vtf");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/lights.vmt");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/lightwarp.vtf");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/normal.vtf");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/phong_exp.vtf");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/shadow.vmt");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/skin.vmt");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/skinwarp.vtf");
	AddFileToDownloadsTable("materials/maoling/player/vocaloid/hatsune_miku/tda/tech.vmt");
	
	PrecacheModel("models/player/custom_player/maoling/vocaloid/hatsune_miku/monsterko/tda/miku_tda.mdl", true);
	PrecacheModel("models/player/custom_player/maoling/vocaloid/hatsune_miku/monsterko/tda/miku_arms_tda.mdl", true);
	
	// Haku Wedding Dress
	
	AddFileToDownloadsTable("models/player/custom_player/monsterko/haku_wedding_dress/haku_v3.dx90.vtx");
	AddFileToDownloadsTable("models/player/custom_player/monsterko/haku_wedding_dress/haku_v3.mdl");
	AddFileToDownloadsTable("models/player/custom_player/monsterko/haku_wedding_dress/haku_v3.phy");
	AddFileToDownloadsTable("models/player/custom_player/monsterko/haku_wedding_dress/haku_v3.vvd");
	
	AddFileToDownloadsTable("models/player/custom_player/monsterko/haku_wedding_dress/haku_arms.dx90.vtx");
	AddFileToDownloadsTable("models/player/custom_player/monsterko/haku_wedding_dress/haku_arms.mdl");
	AddFileToDownloadsTable("models/player/custom_player/monsterko/haku_wedding_dress/haku_arms.vvd");
	
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/pendent_d.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/pendent_d.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/ribbon_c1.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/ribbon_c1.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/ribbon_c2.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/ribbon_c2.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/skin_haku.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/skin_haku.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/stockings-gloves.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/stockings-gloves.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/uv.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/uv.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/uv2.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/uv2.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/acce.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/acce.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/bara.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/bara.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/belt.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/belt.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/bow.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/bow.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/d.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/d.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/dng2.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/dng2.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/face_hakuop_bc.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/face_hakuop_bc.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/g_lace.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/g_lace.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/gem.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/gem.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/jewel.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/jewel.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/kamikazari.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/kamikazari.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/kamikazari2.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/kamikazari2.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/lace_b.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/lace_b.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/lika_dress_b.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/lika_dress_b.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/logo.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/logo.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/longhair_haku.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/longhair_haku.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/mantilla.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/mantilla.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/mantilla2.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/mantilla2.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/mcbn.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/mcbn.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/metalb.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/metalb.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/necklace_d.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/necklace_d.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/nekomimi_haku.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/nekomimi_haku.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/panty_uv.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/monsterko/haku_wedding_dress/panty_uv.vtf");
	
	PrecacheModel("models/player/custom_player/monsterko/haku_wedding_dress/haku_v3.mdl", true);
	PrecacheModel("models/player/custom_player/monsterko/haku_wedding_dress/haku_arms.mdl", true);
	
	// Cybernetic
	
	AddFileToDownloadsTable("models/player/custom_player/maoling/closeronline/cybernetic/cybernetic.vvd");
	AddFileToDownloadsTable("models/player/custom_player/maoling/closeronline/cybernetic/cybernetic.dx90.vtx");
	AddFileToDownloadsTable("models/player/custom_player/maoling/closeronline/cybernetic/cybernetic.mdl");
	AddFileToDownloadsTable("models/player/custom_player/maoling/closeronline/cybernetic/cybernetic.phy");
	
	AddFileToDownloadsTable("models/player/custom_player/maoling/closeronline/cybernetic/cybernetic_arms.dx90.vtx");
	AddFileToDownloadsTable("models/player/custom_player/maoling/closeronline/cybernetic/cybernetic_arms.mdl");
	AddFileToDownloadsTable("models/player/custom_player/maoling/closeronline/cybernetic/cybernetic_arms.vvd");
	
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/than2.vtf");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/than3.vmt");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/than3.vtf");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/than4.vmt");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/than4.vtf");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/toc.vmt");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/toc.vtf");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/0.vmt");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/canh2.vmt");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/canh2.vtf");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/eye.vmt");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/eye.vtf");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/face.vmt");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/face.vtf");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/chan.vmt");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/chan.vtf");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/mu2.vmt");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/mu2.vtf");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/normal.vtf");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/tay.vmt");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/tay.vtf");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/than1.vmt");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/than1.vtf");
	AddFileToDownloadsTable("materials/maoling/player/closeronline/cybernetic/than2.vmt");
	
	PrecacheModel("models/player/custom_player/maoling/closeronline/cybernetic/cybernetic.mdl", true);
	PrecacheModel("models/player/custom_player/maoling/closeronline/cybernetic/cybernetic_arms.mdl", true);
	
	// Toobie
	
	AddFileToDownloadsTable("models/player/custom_player/gkuo88/nier/toobie_fix3/toobie.dx90.vtx");
	AddFileToDownloadsTable("models/player/custom_player/gkuo88/nier/toobie_fix3/toobie.mdl");
	AddFileToDownloadsTable("models/player/custom_player/gkuo88/nier/toobie_fix3/toobie.phy");
	AddFileToDownloadsTable("models/player/custom_player/gkuo88/nier/toobie_fix3/toobie.vvd");
	
	AddFileToDownloadsTable("models/player/custom_player/gkuo88/nier/toobie_fix/toobie_hands.dx90.vtx");
	AddFileToDownloadsTable("models/player/custom_player/gkuo88/nier/toobie_fix/toobie_hands.mdl");
	AddFileToDownloadsTable("models/player/custom_player/gkuo88/nier/toobie_fix/toobie_hands.vvd");
	
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/2b_hair_a.vmt");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/2b_hair_b.vmt");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/2b_hair1_dif.vtf");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/2b_hair1_nrm.vtf");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/2b_hair2_dif.vtf");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/2b_hair2_nrm.vtf");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/2b_head.vmt");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/2b_head_dif.vtf");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/2b_head_nrm.vtf");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/2b_suit.vmt");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/2b_suit_dif.vtf");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/2b_suit_fluff.vmt");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/2b_suit_nrm.vtf");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/2b_suit_spc.vtf");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/body1.vmt");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/body1.vtf");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/body2.vmt");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/body2.vtf");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/copper.vmt");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/copper.vtf");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/gr.vmt");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/gr.vtf");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/nier_swords_virtuous_contract.vmt");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/nier_swords_virtuous_contract_dif.vtf");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/nier_swords_virtuous_contract_nrm.vtf");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/nier_swords_virtuous_contract_spc.vtf");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/patlite1.vmt");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/patlite1.vtf");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/patlite2.vmt");
	AddFileToDownloadsTable("materials/JawSFM/nier/2B/patlite2.vtf");
	
	PrecacheModel("models/player/custom_player/gkuo88/nier/toobie_fix3/toobie.mdl", true);
	PrecacheModel("models/player/custom_player/gkuo88/nier/toobie_fix/toobie_hands.mdl", true);
	
	// Burger
	
	AddFileToDownloadsTable("models/player/custom_player/napas/garrys/beefboss_pm_beefboss_v2.dx90.vtx");
	AddFileToDownloadsTable("models/player/custom_player/napas/garrys/beefboss_pm_beefboss_v2.mdl");
	AddFileToDownloadsTable("models/player/custom_player/napas/garrys/beefboss_pm_beefboss_v2.phy");
	AddFileToDownloadsTable("models/player/custom_player/napas/garrys/beefboss_pm_beefboss_v2.vvd");

	AddFileToDownloadsTable("materials/models/player/custom_player/napas/beefboss/beefbosshat.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/napas/beefboss/beefbosshat.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/napas/beefboss/beefbosshat_n.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/napas/beefboss/beefhead_d.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/napas/beefboss/beefhead_d.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/napas/beefboss/beefhead_n.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/napas/beefboss/burgerbody_d.vmt");
	AddFileToDownloadsTable("materials/models/player/custom_player/napas/beefboss/burgerbody_d.vtf");
	AddFileToDownloadsTable("materials/models/player/custom_player/napas/beefboss/burgerbody_n.vtf");
	
	PrecacheModel("models/player/custom_player/napas/garrys/beefboss_pm_beefboss_v2.mdl", true);
}
