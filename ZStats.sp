#include <sdktools>
//#include <sdkhooks>
#include <cstrike>
#include <geoip>

// "ZStats" // ZBR рейтинг зомби, HMR рейтинг человека, JZP - очки.

// Настройки

char prefix[16] = " [ZStats]";
char clantag[16] = "ɈAZΣ";

int minPlayers = 8;

int rewardKill = 3;
int rewardGrenadeKill = 2;
int rewardMolotovKill = 2;
int rewardInfection = 2;
int rewardDeath = 1;
int rewardAssist = 1;
int rewardHeadshot = 1;
int rewardActivity = 5;
int rewardClantagActivity = 10;
int rewardDamage = 5;
int rewardSoloWin = 9;
int rewardDuoWin = 7;
int rewardTrioWin = 5;
int rewardWin = 3;
int rewardLose = 2;
int rewardPropDamage = 5;
int rewardTopDamager1 = 5;
int rewardTopDamager2 = 4;
int rewardTopDamager3 = 3;
int rewardTopDamagerOthers = 2;

// Переменные статистики.
Database g_hDatabase; // Глобальная переменная для соеденения с базой

int	g_iClientID[MAXPLAYERS+1];	// SteamID игрока
int	g_iOnlineTime[MAXPLAYERS+1];	// Общий онлайн игрока
int	g_iOnlinePlayTime[MAXPLAYERS+1];	// Активный онлайн игрока

int	g_iHumanKills[MAXPLAYERS+1];	// Количество убийств зомби игроком-человеком
int	g_iAssists[MAXPLAYERS+1];	// Количество ассистов
int	g_iHumanHeadShots[MAXPLAYERS+1];	// Количество убийств в голову
int	g_iZombieInfections[MAXPLAYERS+1];	// Количество заражений людей игроком-зомби

int	g_iHumanDeaths[MAXPLAYERS+1];	// Количество смертей человека
int	g_iZombieDeaths[MAXPLAYERS+1];	// Количество смертей зомби

int	g_iHumanDamage[MAXPLAYERS+1];	// Урон нанесённый игроком-человеком по зомби
int	g_iHumanShots[MAXPLAYERS+1];	// Количество выстрелов игроком-человеком
int	g_iHumanHeadShotsHits[MAXPLAYERS+1];	// Количество выстрелов в голову
int	g_iHumanHits[MAXPLAYERS+1];	// Количество попаданий игроком-человеком

int	g_iHumanRoundsWon[MAXPLAYERS+1];	// Количество раундов, выигранных за человека
int	g_iZombieRoundsWon[MAXPLAYERS+1];	// Количество раундов, выигранных за первого зомби
int	g_iHumanRoundsLose[MAXPLAYERS+1];	// Количество раундов, проигранных за человека
int	g_iZombieRoundsLose[MAXPLAYERS+1];	// Количество раундов, проигранных за первого зомби

int	g_iZombieTakedDamage[MAXPLAYERS+1];	// Урон, полученный игроком-зомби от выстрелов людей
int	g_iPropsDamage[MAXPLAYERS+1];	// Урон, нанесенный пропам

int	g_iFirstZombiePlays[MAXPLAYERS+1];	// Количество игр за первого зомби

int	g_iTop1Damager[MAXPLAYERS+1];	// Количество топ 1 мест, занятых игроком
int	g_iTop2Damager[MAXPLAYERS+1];	// Количество топ 2 мест, занятых игроком
int	g_iTop3Damager[MAXPLAYERS+1];	// Количество топ 3 мест, занятых игроком
int	g_iTop4Damager[MAXPLAYERS+1];	// Количество топ 4 мест, занятых игроком
int	g_iTop5Damager[MAXPLAYERS+1];	// Количество топ 5 мест, занятых игроком

int	g_iJZP[MAXPLAYERS+1];	// Очки игрока
int	g_iZBR[MAXPLAYERS+1];	// Рейтинг зомби
int	g_iHMR[MAXPLAYERS+1];	// Рейтинг человека

// Локальные переменные плагина.
bool statsEnabled;
bool bActivityNewRound;
bool isFirstZombie[MAXPLAYERS+1];
int spawnsCount[MAXPLAYERS+1];
int onlineTime[MAXPLAYERS+1];
int roundDamage[MAXPLAYERS+1];
int oldHealth[2048];
int tempDamageForReward[MAXPLAYERS+1];
int tempPropDamageForReward[MAXPLAYERS+1];
//int rankOffset;
int playersRank[MAXPLAYERS+1];
//float oldAfkCoordinates[MAXPLAYERS+1][3];

public Plugin myinfo =
{
	name = "Zombie Escape Stats",
	author = "Walderr",
	description = "Статистика игроков, созданная под режим Zombie Escape",
	version = "1.6",
	url = "http://www.jaze.ru/"
};

public void OnPluginStart()
{
	LoadTranslations("zstats.phrases");
	
	RegConsoleCmd("sm_zstats", Command_ZStats, "Просмотр своей статистики");
	RegConsoleCmd("sm_top", Command_Top, "Просмотр лучших игроков");
	
	// Добавляем прослушивание чата на ввод комманд.
	AddCommandListener(CommandListener_Say, "say");
	AddCommandListener(CommandListener_Say, "say_team");
	
	Database.Connect(ConnectCallBack, "zstats"); // Имя секции в databases.cfg

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	HookEvent("round_end", Event_RoundEnd);
	//HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("round_mvp", Event_Round_MVP);
	
	HookEntityOutput("func_breakable", "OnHealthChanged", OnHealthChanged);
	HookEntityOutput("func_physbox", "OnHealthChanged", OnHealthChanged);
	HookEntityOutput("prop_physics", "OnHealthChanged", OnHealthChanged);
	HookEntityOutput("func_physbox_multiplayer", "OnHealthChanged", OnHealthChanged);
	HookEntityOutput("prop_physics_multiplayer", "OnHealthChanged", OnHealthChanged);
	
	CreateTimer(20.0, AfkTimer, _, TIMER_REPEAT);
}

public Action Command_ZStats(int client, int args)
{
	ShowStatsMenu(client);
	return Plugin_Handled;
}

public Action Command_Top(int client, int args)
{
	ShowTopMenu(client);
	return Plugin_Handled;
}

public Action AfkTimer(Handle timer)
{
	if(!statsEnabled) return;
	
	// Если начался новый раунд, не даем игрокам очки за активность.
	if(!bActivityNewRound)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				// Берём координаты игрока.
//				float afkCoordinates[3];
//				GetClientAbsOrigin(i, afkCoordinates);
				
				// Рассчитываем расстояние между старыми и новыми координатами игрока.
//				float distance = GetVectorDistance(afkCoordinates, oldAfkCoordinates[i]);
				
				// Если расстояние больше 100 юнитов
//				if(distance > 100.0)
//				{
					// Перезаписываем старые координаты новыми.
//					oldAfkCoordinates[i] = afkCoordinates;
					
					// Добавляем 20 секунд к времени активной игры игрока.
					g_iOnlinePlayTime[i] += 20;
					
					// Выдача очков за активную игру.
					if(g_iOnlinePlayTime[i] % 600 == 0)
					{
						char tag[16];
						CS_GetClientClanTag(i, tag, sizeof(tag));
						
						if(StrEqual(tag, clantag))
						{
							g_iJZP[i] += rewardClantagActivity;
							PrintToChat(i, "%t", "Reward_Activity", prefix, rewardClantagActivity, g_iJZP[i]);
						}
						else
						{
							g_iJZP[i] += rewardActivity;
							PrintToChat(i, "%t", "Reward_Activity", prefix, rewardActivity, g_iJZP[i]);
						}
					}
//				}
			}
		}
	}
	
	// Выключаем защиту от афк при новом раунде.
	if(bActivityNewRound) bActivityNewRound = false;
}
/*
public void OnMapStart()
{
	rankOffset = FindSendPropInfo("CCSPlayerResource", "m_iCompetitiveRanking");
	
	SDKHook(FindEntityByClassname(-1, "cs_player_manager"), SDKHook_ThinkPost, Hook_ThinkPost);
	
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup51.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup52.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup53.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup54.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup55.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup56.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup57.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup58.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup59.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup60.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup61.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup62.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup63.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup64.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup65.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup66.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup67.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup68.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup71.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup72.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup73.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup74.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup75.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup76.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup77.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup78.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup79.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup80.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup81.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup82.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup83.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup84.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup85.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup90.svg");
	AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup91.svg");
}
*/
public void OnMapEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		// Обнуляем урон за раунд на случай смены карты посреди раунда.
		roundDamage[i] = 0;
		
		// Сбрасываем количество возрождений игрока.
		spawnsCount[i] = 0;
	}
	
//	SDKUnhook(FindEntityByClassname(-1, "cs_player_manager"), SDKHook_ThinkPost, Hook_ThinkPost);
}
/*
public void Hook_ThinkPost(int ent)
{
	SetEntDataArray(ent, rankOffset, playersRank, MAXPLAYERS+1);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(buttons & IN_SCORE && !(GetEntProp(client, Prop_Data, "m_nOldButtons") & IN_SCORE))
	{
		if(StartMessageOne("ServerRankRevealAll", client)) EndMessage();
	}

	return Plugin_Continue;
}
*/
public void ConnectCallBack(Database hDatabase, const char[] sError, any data) // Пришел результат соеденения
{
	if (hDatabase == null)	// Соединение  не удачное
	{
		SetFailState("Ошибка базы данных: %s", sError); // Отключаем плагин
		return;
	}

	g_hDatabase = hDatabase; // Присваиваем глобальной переменной соеденения значение текущего соеденения
	
	SQL_LockDatabase(g_hDatabase); // Блокируем базу для других запросов

	g_hDatabase.Query(SQL_Callback_CheckError,	"CREATE TABLE IF NOT EXISTS `table_zstats` (\
												`id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,\
												`auth` VARCHAR(32) NOT NULL,\
												`name` VARCHAR(32) NOT NULL default 'unknown',\
												`last_connect` INTEGER UNSIGNED NOT NULL,\
												`online_time` INTEGER NOT NULL default '0',\
												`online_playtime` INTEGER NOT NULL default '0',\
												`human_kills` INTEGER NOT NULL default '0',\
												`assists` INTEGER NOT NULL default '0',\
												`human_headshots` INTEGER NOT NULL default '0',\
												`zombie_infections` INTEGER NOT NULL default '0',\
												`human_deaths` INTEGER NOT NULL default '0',\
												`zombie_deaths` INTEGER NOT NULL default '0',\
												`human_damage` INTEGER NOT NULL default '0',\
												`human_shots` INTEGER NOT NULL default '0',\
												`human_headshots_hits` INTEGER NOT NULL default '0',\
												`human_hits` INTEGER NOT NULL default '0',\
												`human_rounds_won` INTEGER NOT NULL default '0',\
												`zombie_rounds_won` INTEGER NOT NULL default '0',\
												`human_rounds_lose` INTEGER NOT NULL default '0',\
												`zombie_rounds_lose` INTEGER NOT NULL default '0',\
												`zombie_taked_damage` INTEGER NOT NULL default '0',\
												`props_damage` INTEGER NOT NULL default '0',\
												`first_zombie_plays` INTEGER NOT NULL default '0',\
												`top1_damager` INTEGER NOT NULL default '0',\
												`top2_damager` INTEGER NOT NULL default '0',\
												`top3_damager` INTEGER NOT NULL default '0',\
												`top4_damager` INTEGER NOT NULL default '0',\
												`top5_damager` INTEGER NOT NULL default '0',\
												`JZP` INTEGER NOT NULL default '1000',\
												`ZBR` INTEGER NOT NULL default '0',\
												`HMR` INTEGER NOT NULL default '0');");
	SQL_UnlockDatabase(g_hDatabase); // Разблокируем базу
	
	g_hDatabase.SetCharset("utf8"); // Устанавливаем кодировку
}

// Обработчик ошибок
public void SQL_Callback_CheckError(Database hDatabase, DBResultSet results, const char[] szError, any data)
{
	if(szError[0]) LogError("SQL_Callback_CheckError: %s", szError);
}

public void OnClientConnected(client)
{
	// Сбрасываем количество возрождений игрока.
	spawnsCount[client] = 0;
}

// Игрок подключился
public void OnClientPostAdminCheck(int client)
{
	if(!IsFakeClient(client))
	{
		char szQuery[1024], szAuth[32];
		GetClientAuthId(client, AuthId_Engine, szAuth, sizeof(szAuth), true); // Получаем SteamID игрока
		FormatEx(szQuery, sizeof(szQuery), "SELECT `id`, `online_time`, `online_playtime`, `human_kills`, `assists`, `human_headshots`, `zombie_infections`, `human_deaths`, `zombie_deaths`, `human_damage`, `human_shots`, `human_headshots_hits`, `human_hits`, `human_rounds_won`, `zombie_rounds_won`, `human_rounds_lose`, `zombie_rounds_lose`, `zombie_taked_damage`, `props_damage`, `first_zombie_plays`, `top1_damager`, `top2_damager`, `top3_damager`, `top4_damager`, `top5_damager`, `JZP` FROM `table_zstats` WHERE `auth` = '%s';", szAuth);	// Формируем запрос
		g_hDatabase.Query(SQL_Callback_SelectClient, szQuery, GetClientUserId(client)); // Отправляем запрос
		
		// Сохраняем время захода игрока.
		onlineTime[client] = GetTime();
	}
}

// Пришел ответ на запрос
public void SQL_Callback_SelectClient(Database hDatabase, DBResultSet hResults, const char[] sError, any userID)
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQL_Callback_SelectClient: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение функции
	}
	
	int client = GetClientOfUserId(userID);
	if(client)
	{
		char szQuery[256], szName[MAX_NAME_LENGTH*2+1];
		GetClientName(client, szQuery, MAX_NAME_LENGTH);
		g_hDatabase.Escape(szQuery, szName, sizeof(szName)); // Экранируем запрещенные символы в имени

		// Игрок всё еще на сервере
		if(hResults.FetchRow())	// Игрок есть в базе
		{
			// Получаем значения из результата
			g_iClientID[client] = hResults.FetchInt(0);	// SteamID игрока
			g_iOnlineTime[client] = hResults.FetchInt(1);	// Общий онлайн игрока
			g_iOnlinePlayTime[client] = hResults.FetchInt(2);	// Активный онлайн игрока

			g_iHumanKills[client] = hResults.FetchInt(3);	// Количество убийств зомби игроком-человеком
			g_iAssists[client] = hResults.FetchInt(4);	// Количество ассистов
			g_iHumanHeadShots[client] = hResults.FetchInt(5);	// Количество убийств в голову
			g_iZombieInfections[client] = hResults.FetchInt(6);	// Количество заражений людей игроком-зомби

			g_iHumanDeaths[client] = hResults.FetchInt(7);	// Количество смертей человека
			g_iZombieDeaths[client] = hResults.FetchInt(8);	// Количество смертей зомби

			g_iHumanDamage[client] = hResults.FetchInt(9);	// Урон нанесённый игроком-человеком по зомби
			g_iHumanShots[client] = hResults.FetchInt(10);	// Количество выстрелов игроком-человеком
			g_iHumanHeadShotsHits[client] = hResults.FetchInt(11);	// Количество выстрелов в голову
			g_iHumanHits[client] = hResults.FetchInt(12);	// Количество попаданий игроком-человеком

			g_iHumanRoundsWon[client] = hResults.FetchInt(13);	// Количество раундов, выигранных за человека
			g_iZombieRoundsWon[client] = hResults.FetchInt(14);	// Количество раундов, выигранных за первого зомби
			g_iHumanRoundsLose[client] = hResults.FetchInt(15);	// Количество раундов, проигранных за человека
			g_iZombieRoundsLose[client] = hResults.FetchInt(16);	// Количество раундов, проигранных за первого зомби

			g_iZombieTakedDamage[client] = hResults.FetchInt(17);	// Урон, полученный игроком-зомби от выстрелов людей
			g_iPropsDamage[client] = hResults.FetchInt(18);	// Урон, нанесенный пропам
			
			g_iFirstZombiePlays[client] = hResults.FetchInt(19);	// Урон, нанесенный пропам
			
			g_iTop1Damager[client] = hResults.FetchInt(20);	// Количество топ 1 мест, занятых игроком
			g_iTop2Damager[client] = hResults.FetchInt(21);	// Количество топ 2 мест, занятых игроком
			g_iTop3Damager[client] = hResults.FetchInt(22);	// Количество топ 3 мест, занятых игроком
			g_iTop4Damager[client] = hResults.FetchInt(23);	// Количество топ 4 мест, занятых игроком
			g_iTop5Damager[client] = hResults.FetchInt(24);	// Количество топ 5 мест, занятых игроком

			g_iJZP[client] = hResults.FetchInt(25);	// Очки игрока

			// Обновляем в базе ник и дату последнего входа
			FormatEx(szQuery, sizeof(szQuery), "UPDATE `table_zstats` SET `last_connect` = %i, `name` = '%s' WHERE `id` = %i;", GetTime(), szName, g_iClientID[client]);
			g_hDatabase.Query(SQL_Callback_CheckError, szQuery);
		}
		else
		{
			g_iClientID[client] = 0;
			g_iOnlineTime[client] = 0;
			g_iOnlinePlayTime[client] = 0;
			g_iHumanKills[client] = 0;
			g_iAssists[client] = 0;
			g_iHumanHeadShots[client] = 0;
			g_iZombieInfections[client] = 0;
			g_iHumanDeaths[client] = 0;
			g_iZombieDeaths[client] = 0;
			g_iHumanDamage[client] = 0;
			g_iHumanShots[client] = 0;
			g_iHumanHeadShotsHits[client] = 0;
			g_iHumanHits[client] = 0;
			g_iHumanRoundsWon[client] = 0;
			g_iZombieRoundsWon[client] = 0;
			g_iHumanRoundsLose[client] = 0;
			g_iZombieRoundsLose[client] = 0;
			g_iZombieTakedDamage[client] = 0;
			g_iPropsDamage[client] = 0;
			g_iFirstZombiePlays[client] = 0;
			g_iTop1Damager[client] = 0;
			g_iTop2Damager[client] = 0;
			g_iTop3Damager[client] = 0;
			g_iTop4Damager[client] = 0;
			g_iTop5Damager[client] = 0;
			g_iJZP[client] = 1000;
			
			// Добавляем игрока в базу
			char szAuth[32];
			GetClientAuthId(client, AuthId_Engine, szAuth, sizeof(szAuth));
			FormatEx(szQuery, sizeof(szQuery), "INSERT INTO `table_zstats` (`auth`, `name`, `last_connect`) VALUES ( '%s', '%s', %i);", szAuth, szName, GetTime());
			g_hDatabase.Query(SQL_Callback_CreateClient, szQuery, GetClientUserId(client));
		}

		// Пишем сообщение о подключении игрока.
		char sIP[32], sCountry[64], sCountryRU[64];
		GetClientIP(client, sIP, sizeof(sIP));
		GeoipCountry(sIP, sCountry, sizeof(sCountry), "en");
		GeoipCountry(sIP, sCountryRU, sizeof(sCountryRU), "ru");

		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i)) continue;
			
			if(GetClientLanguage(i) == 22) PrintToChat(i, "%t", "Player_Connect", prefix, client, g_iJZP[client], sCountryRU);
			else PrintToChat(i, "%t", "Player_Connect", prefix, client, g_iJZP[client], sCountry);
		}
	}
}

public void SQL_Callback_CreateClient(Database hDatabase, DBResultSet results, const char[] szError, any userID)
{
	if(szError[0])
	{
		LogError("SQL_Callback_CreateClient: %s", szError);
		return;
	}
	
	int client = GetClientOfUserId(userID);
	if(client) g_iClientID[client] = results.InsertId; // Получаем ID только что добавленного игрока
}

// Игрок отключился
public void OnClientDisconnect(int client)
{
	if(!IsFakeClient(client))
	{
		// Высчитываем и сохраняем время игрока на сервере.
		g_iOnlineTime[client] += (GetTime() - onlineTime[client]);
		
		// Высчитываем и сохраняем рейтинги игрока
		g_iZBR[client] = Calculate_ZBR(client);
		g_iHMR[client] = Calculate_HMR(client);
		
		char szQuery[1024];
		FormatEx(szQuery, sizeof(szQuery), "UPDATE `table_zstats` SET `online_time` = %i, `online_playtime` = %i, `human_kills` = %i, `assists` = %i, `human_headshots` = %i, `zombie_infections` = %i, `human_deaths` = %i, `zombie_deaths` = %i, `human_damage` = %i, `human_shots` = %i, `human_headshots_hits` = %i, `human_hits` = %i, `human_rounds_won` = %i, `zombie_rounds_won` = %i, `human_rounds_lose` = %i, `zombie_rounds_lose` = %i, `zombie_taked_damage` = %i, `props_damage` = %i, `first_zombie_plays` = %i, `top1_damager` = %i, `top2_damager` = %i, `top3_damager` = %i, `top4_damager` = %i, `top5_damager` = %i, `JZP` = %i, `ZBR` = %i, `HMR` = %i WHERE `id` = %i;", g_iOnlineTime[client], g_iOnlinePlayTime[client], g_iHumanKills[client], g_iAssists[client], g_iHumanHeadShots[client], g_iZombieInfections[client], g_iHumanDeaths[client], g_iZombieDeaths[client], g_iHumanDamage[client], g_iHumanShots[client], g_iHumanHeadShotsHits[client], g_iHumanHits[client], g_iHumanRoundsWon[client], g_iZombieRoundsWon[client], g_iHumanRoundsLose[client], g_iZombieRoundsLose[client], g_iZombieTakedDamage[client], g_iPropsDamage[client], g_iFirstZombiePlays[client], g_iTop1Damager[client], g_iTop2Damager[client], g_iTop3Damager[client], g_iTop4Damager[client], g_iTop5Damager[client], g_iJZP[client], g_iZBR[client], g_iHMR[client], g_iClientID[client]);
		g_hDatabase.Query(SQL_Callback_CheckError, szQuery);
		
		// Сбрасываем состояние "первого зомби".
		isFirstZombie[client] = false;
		
		// Сбрасываем переменную урона за раунд.
		roundDamage[client] = 0;
		
		// Сбрасываем ранг игрока.
		playersRank[client] = 0;
		
		// Сбрасываем временные переменные урона для наград.
		tempDamageForReward[client] = 0;
		tempPropDamageForReward[client] = 0;
		
		// Сбрасываем все переменные.
		g_iClientID[client] = 0;
		g_iOnlineTime[client] = 0;
		g_iOnlinePlayTime[client] = 0;
		g_iHumanKills[client] = 0;
		g_iAssists[client] = 0;
		g_iHumanHeadShots[client] = 0;
		g_iZombieInfections[client] = 0;
		g_iHumanDeaths[client] = 0;
		g_iZombieDeaths[client] = 0;
		g_iHumanDamage[client] = 0;
		g_iHumanShots[client] = 0;
		g_iHumanHeadShotsHits[client] = 0;
		g_iHumanHits[client] = 0;
		g_iHumanRoundsWon[client] = 0;
		g_iZombieRoundsWon[client] = 0;
		g_iHumanRoundsLose[client] = 0;
		g_iZombieRoundsLose[client] = 0;
		g_iZombieTakedDamage[client] = 0;
		g_iPropsDamage[client] = 0;
		g_iFirstZombiePlays[client] = 0;
		g_iTop1Damager[client] = 0;
		g_iTop2Damager[client] = 0;
		g_iTop3Damager[client] = 0;
		g_iTop4Damager[client] = 0;
		g_iTop5Damager[client] = 0;
		g_iJZP[client] = 1000;
	}
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	// Получаем index игрока из его UserID.
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	spawnsCount[client]++;
	
	if(spawnsCount[client] == 2)
	{
		char tag[16];
		CS_GetClientClanTag(client, tag, sizeof(tag));
		
		if(StrEqual(tag, clantag)) PrintToChat(client, "%t", "Welcome_Good_Clantag_Message", prefix, tag);
		else if(StrEqual(tag, "")) PrintToChat(client, "%t", "Welcome_No_Clantag_Message", prefix, clantag);
		else PrintToChat(client, "%t", "Welcome_Bad_Clantag_Message", prefix, tag, clantag);
	}
	
/*
	if(g_iJZP[client] >= 65000) playersRank[client] = 18;		// "Всемирная Элита"
	else if(g_iJZP[client] >= 45000) playersRank[client] = 17;	// "Великий Магистр Высшего Ранга"
	else if(g_iJZP[client] >= 32800) playersRank[client] = 16;	// "Легендарный Беркут-магистр"
	else if(g_iJZP[client] >= 24800) playersRank[client] = 15;	// "Легендарный Беркут"
	else if(g_iJZP[client] >= 18900) playersRank[client] = 14;	// "Заслуженный Магистр-хранитель"
	else if(g_iJZP[client] >= 14500) playersRank[client] = 13;	// "Магистр-хранитель - Элита"
	else if(g_iJZP[client] >= 11100) playersRank[client] = 12;	// "Магистр-хранитель - II"
	else if(g_iJZP[client] >= 8500) playersRank[client] = 11;	// "Магистр-хранитель - I"
	else if(g_iJZP[client] >= 6400) playersRank[client] = 10;	// "Золотая Звезда - Магистр"
	else if(g_iJZP[client] >= 4900) playersRank[client] = 9;	// "Золотая Звезда - III"
	else if(g_iJZP[client] >= 3800) playersRank[client] = 8;	// "Золотая Звезда - II"
	else if(g_iJZP[client] >= 2900) playersRank[client] = 7;	// "Золотая Звезда - I"
	else if(g_iJZP[client] >= 2200) playersRank[client] = 6;	// "Серебро - Великий Магистр"
	else if(g_iJZP[client] >= 1750) playersRank[client] = 5;	// "Серебро - Элита"
	else if(g_iJZP[client] >= 1450) playersRank[client] = 4;	// "Серебро - IV"
	else if(g_iJZP[client] >= 1250) playersRank[client] = 3;	// "Серебро - III"
	else if(g_iJZP[client] >= 1100) playersRank[client] = 2;	// "Серебро - II"
	else if(g_iJZP[client] >= 1000) playersRank[client] = 1;	// "Серебро - I"
	else playersRank[client] = 0;								// Нет ранга

	char steamid[32];
	GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid), false);
	
	if(StrEqual(steamid, "STEAM_1:0:197719083"))
	{
		playersRank[client] = 85;
		return;
	}
	
	if(g_iJZP[client] >= 102065) playersRank[client] = 68;		// "Всемирная Элита (Мастер)"
	else if(g_iJZP[client] >= 88065) playersRank[client] = 18;	// "Всемирная Элита"
	else if(g_iJZP[client] >= 68065) playersRank[client] = 67;	// "Великий Магистр Высшего Ранга (Мастер)"
	else if(g_iJZP[client] >= 59665) playersRank[client] = 17;	// "Великий Магистр Высшего Ранга"
	else if(g_iJZP[client] >= 47665) playersRank[client] = 66;	// "Легендарный Беркут-магистр (Мастер)"
	else if(g_iJZP[client] >= 42765) playersRank[client] = 16;	// "Легендарный Беркут-магистр"
	else if(g_iJZP[client] >= 35765) playersRank[client] = 65;	// "Легендарный Беркут (Мастер)"
	else if(g_iJZP[client] >= 32265) playersRank[client] = 15;	// "Легендарный Беркут"
	else if(g_iJZP[client] >= 27265) playersRank[client] = 64;	// "Заслуженный Магистр-хранитель (Мастер)"
	else if(g_iJZP[client] >= 24115) playersRank[client] = 14;	// "Заслуженный Магистр-хранитель"
	else if(g_iJZP[client] >= 19615) playersRank[client] = 63;	// "Магистр-хранитель - Элита (Мастер)"
	else if(g_iJZP[client] >= 17305) playersRank[client] = 13;	// "Магистр-хранитель - Элита"
	else if(g_iJZP[client] >= 14005) playersRank[client] = 62;	// "Магистр-хранитель - II (Мастер)"
	else if(g_iJZP[client] >= 12255) playersRank[client] = 12;	// "Магистр-хранитель - II"
	else if(g_iJZP[client] >= 9755) playersRank[client] = 61;	// "Магистр-хранитель - I (Мастер)"
	else if(g_iJZP[client] >= 8565) playersRank[client] = 11;	// "Магистр-хранитель - I"
	else if(g_iJZP[client] >= 6865) playersRank[client] = 60;	// "Золотая Звезда - Магистр (Мастер)"
	else if(g_iJZP[client] >= 6200) playersRank[client] = 10;	// "Золотая Звезда - Магистр"
	else if(g_iJZP[client] >= 5250) playersRank[client] = 59;	// "Золотая Звезда - III (Мастер)"
	else if(g_iJZP[client] >= 4760) playersRank[client] = 9;	// "Золотая Звезда - III"
	else if(g_iJZP[client] >= 4060) playersRank[client] = 58;	// "Золотая Звезда - II (Мастер)"
	else if(g_iJZP[client] >= 3710) playersRank[client] = 8;	// "Золотая Звезда - II"
	else if(g_iJZP[client] >= 3210) playersRank[client] = 57;	// "Золотая Звезда - I (Мастер)"
	else if(g_iJZP[client] >= 2965) playersRank[client] = 7;	// "Золотая Звезда - I"
	else if(g_iJZP[client] >= 2615) playersRank[client] = 56;	// "Серебро - Великий Магистр (Мастер)"
	else if(g_iJZP[client] >= 2440) playersRank[client] = 6;	// "Серебро - Великий Магистр"
	else if(g_iJZP[client] >= 2190) playersRank[client] = 55;	// "Серебро - Элита (Мастер)"
	else if(g_iJZP[client] >= 2050) playersRank[client] = 5;	// "Серебро - Элита"
	else if(g_iJZP[client] >= 1850) playersRank[client] = 54;	// "Серебро - IV (Мастер)"
	else if(g_iJZP[client] >= 1745) playersRank[client] = 4;	// "Серебро - IV"
	else if(g_iJZP[client] >= 1595) playersRank[client] = 53;	// "Серебро - III (Мастер)"
	else if(g_iJZP[client] >= 1490) playersRank[client] = 3;	// "Серебро - III"
	else if(g_iJZP[client] >= 1340) playersRank[client] = 52;	// "Серебро - II (Мастер)"
	else if(g_iJZP[client] >= 1270) playersRank[client] = 2;	// "Серебро - II"
	else if(g_iJZP[client] >= 1170) playersRank[client] = 51;	// "Серебро - I (Мастер)"
	else if(g_iJZP[client] >= 1100) playersRank[client] = 1;	// "Серебро - I"
	else if(g_iJZP[client] >= 980) playersRank[client] = 91;	// "Калибровка"
	else playersRank[client] = 90;								// "Без ранга"
*/
}

public Action Event_PlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
	// Получаем index игрока из его UserID.
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Если индекс игрока не найден, выходим.
	if(client == 0) return Plugin_Handled;
	
	// Пишем в чат что игрок отключился.
	char sReason[256];
	GetEventString(event, "reason", sReason, sizeof(sReason));
	
	/*
	if(StrContains(sReason, "timed out") != -1) PrintToChatAll("%t", "Player_Disconnect_Crash", prefix, client, g_iJZP[client]);
	else if(StrContains(sReason, "no user logon", false) != -1) PrintToChatAll("%t", "Player_Disconnect_NoUserLogon", prefix, client, g_iJZP[client]);
	else if(StrContains(sReason, "VAC authentication error", false) != -1) PrintToChatAll("%t", "Player_Disconnect_VAC", prefix, client, g_iJZP[client]);
	else PrintToChatAll("%t", "Player_Disconnect", prefix, client, g_iJZP[client]);
	*/
	
	LogToFileEx("cfg/sourcemod/logs/disconnect.log", "%N - %s", client, sReason);
	
	char sMessage[256];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && CheckCommandAccess(i, "", ADMFLAG_GENERIC, true))
		{
			SetGlobalTransTarget(i);
	
			if(StrContains(sReason, "timed out") != -1) FormatEx(sMessage, sizeof(sMessage), "%t", "Player_Disconnect_Crash", prefix, client, g_iJZP[client]);
			else if(StrContains(sReason, "no user logon", false) != -1) FormatEx(sMessage, sizeof(sMessage), "%t", "Player_Disconnect_NoUserLogon", prefix, client, g_iJZP[client]);
			else if(StrContains(sReason, "VAC authentication error", false) != -1) FormatEx(sMessage, sizeof(sMessage), "%t", "Player_Disconnect_VAC", prefix, client, g_iJZP[client]);
			else FormatEx(sMessage, sizeof(sMessage), "%t", "Player_Disconnect", prefix, client, g_iJZP[client]);

			PrintToChat(i, "%s", sMessage);
		}
	}
	
	// Блокируем стандартное сообщение о выходе с сервера.
	return Plugin_Handled;
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	if(!statsEnabled) return;
	
	// Получаем index убившего.
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	// Получаем index умершего игрока.
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Если убийца - сервер или сама жертва
	if(attacker < 1 || attacker == client)
	{
		if(GetClientTeam(client) == CS_TEAM_CT) g_iHumanDeaths[client]++;
		else if(GetClientTeam(client) == CS_TEAM_T) g_iZombieDeaths[client]++;	
		
		g_iJZP[client] -= rewardDeath;	
		PrintToChat(client, "%t", "Reward_Death", prefix, rewardDeath, g_iJZP[client]);
		
		return;
	}
	
	// Получаем index помощника в убийстве.
	int assister = GetClientOfUserId(GetEventInt(event, "assister"));
	
	// Узнаем, был ли убит игрок выстрелом в голову.
	bool headshot = GetEventBool(event, "headshot");
	
	if(GetClientTeam(attacker) == CS_TEAM_CT)
	{
		g_iHumanKills[attacker]++;
		
		char weapon[32];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		
		if(StrEqual(weapon, "hegrenade"))
		{
			PrintToChat(attacker, "%t", "Reward_Grenade_Kill", prefix, rewardGrenadeKill, client, g_iJZP[attacker]);
			g_iJZP[attacker] += rewardGrenadeKill;
		}
		else if(StrEqual(weapon, "inferno"))
		{
			PrintToChat(attacker, "%t", "Reward_Molotov_Kill", prefix, rewardMolotovKill, client, g_iJZP[attacker]);
			g_iJZP[attacker] += rewardMolotovKill;
		}
		else
		{
			PrintToChat(attacker, "%t", "Reward_Kill", prefix, rewardKill, client, g_iJZP[attacker]);
			g_iJZP[attacker] += rewardKill;
		}
		
		g_iZombieDeaths[client]++;
		g_iJZP[client] -= rewardDeath;
		PrintToChat(client, "%t", "Reward_Death", prefix, rewardDeath, g_iJZP[client]);
		
		if(headshot)
		{
			g_iHumanHeadShots[attacker]++;
			g_iJZP[attacker] += rewardHeadshot;
			PrintToChat(attacker, "%t", "Reward_HeadShot", prefix, rewardHeadshot, g_iJZP[attacker]);
		}
		
		if(assister != 0)
		{
			g_iAssists[assister]++;
			g_iJZP[assister] += rewardAssist;
			PrintToChat(assister, "%t", "Reward_Assist", prefix, rewardAssist, g_iJZP[assister]);
		}
	}
	else
	{
		g_iZombieInfections[attacker]++;
		g_iJZP[attacker] += rewardInfection;
		PrintToChat(attacker, "%t", "Reward_Infection", prefix, rewardInfection, client, g_iJZP[attacker]);
		
		g_iHumanDeaths[client]++;
		g_iJZP[client] -= rewardDeath;		
		PrintToChat(client, "%t", "Reward_Death", prefix, rewardDeath, g_iJZP[client]);
	}
}

public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	if(!statsEnabled) return;
	
	// Получаем index нанёсшего урон.
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	// Если урон нанёс не игрок, выходим.
	if(attacker < 1) return;
	
	// Если урон игроку нанёс зомби, выходим.
	if(GetClientTeam(attacker) == CS_TEAM_T) return;
	
	// Получаем index жертвы.
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Если игрок нанёс урон сам себе, выходим.
	if(client == attacker) return;
	
	// Берем нанесенный жертве урон.
	int damage = GetEventInt(event, "dmg_health");
	
	// Получаем название оружия.
	char weaponName[32] = "";
	GetEventString(event, "weapon", weaponName, sizeof(weaponName));
	
	// Засчитываем попадание только если оружие - не нож и не гранаты.
	if(StrContains(weaponName, "knife") == -1
	&& StrContains(weaponName, "bayonet") == -1
	&& StrContains(weaponName, "hegrenade") == -1
	&& StrContains(weaponName, "inferno") == -1) g_iHumanHits[attacker]++;
	
	g_iHumanDamage[attacker] += damage;
	g_iZombieTakedDamage[client] += damage;
	
	// Если выстрел был в голову, засчитываем как попадание в голову.
	if(GetEventInt(event, "hitgroup") == 1) g_iHumanHeadShotsHits[attacker]++;
	
	// Сохраняем урон для топа урона за раунд.
	roundDamage[attacker] += damage;
	
	//Награда за определенное количество нанесенного урона.
	tempDamageForReward[attacker] += damage;
	if(tempDamageForReward[attacker] > 10000)
	{
		g_iJZP[attacker] +=  rewardDamage;
		PrintToChat(attacker, "%t", "Reward_Damage", prefix, rewardDamage, g_iJZP[attacker]);
		tempDamageForReward[attacker] = 0;
	}
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	bActivityNewRound = true;
	
	int alivePlayers;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i)) alivePlayers++;
		
		// Сбрасываем состояние "первых зомби".
		isFirstZombie[i] = false;
		
		// Сбрасываем урон за раунд.
		roundDamage[i] = 0;
	}
	
	// Если игроков больше мин. количества, включаем статистику.
	if(alivePlayers >= 8) statsEnabled = true;
	else
	{
		statsEnabled = false;
		PrintToChatAll("%t", "StatsDisabled", prefix, minPlayers);
	}
	
	// Сбрасываем накопленное количество здоровья пропов.
	for(int i = 1; i < 2048; i++) oldHealth[i] = 0;
}

public Action Event_RoundFreezeEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if(!statsEnabled) return;
	
	// Создаем таймер чтобы определить первых зомби.
	CreateTimer(GetConVarFloat(FindConVar("ze_infect_time")) + 1.0, FirstInfect);
}

public Action FirstInfect(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T)
		{
			isFirstZombie[i] = true;
			
			g_iFirstZombiePlays[i]++;
		}
	}
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if(!statsEnabled) return;
	
	// Определяем победившую команду.
	int winnerTeam = GetEventInt(event, "winner");
	
	// Создаем таймер для подсчета игроков и выдачи очков за победу или поражение.
	CreateTimer(0.5, Timer_RoundEndReward, winnerTeam, TIMER_FLAG_NO_MAPCHANGE);
	
	//======================================================================================
	
	// Создаем переменную в которой будут индексы топ игроков (для награждения).
	int topDamagers[5];
	
	// Создаем переменную и копируем в нее урон всех игроков для последующей сортировки.
	int sortingRoundDamage[MAXPLAYERS+1];
	sortingRoundDamage = roundDamage;
	
	// Сортируем по убыванию.
	SortIntegers(sortingRoundDamage, MaxClients+1, Sort_Descending);
	
	// Ищем игроков, настрелявших больше урона
	for(int i = 0; i < 5; i++)
	{
		// Тут будет найденный игрок.
		int findedClient;
		
		// Проверяем у кого из игроков имеется больше всего урона
		for(int client = 1; client < MaxClients+1; client++)
		{
			// Если урон игрока за раунд больше нуля и равняется отсортированному урону в списке
			if(roundDamage[client] > 0 && roundDamage[client] == sortingRoundDamage[i])
			{
				// Мы нашли нужного игрока.
				findedClient = client;
				
				// Если этот игрок первый, пишем заголовок топа.
				if(i == 0) PrintToChatAll("%t", "TopDamagersTitle");
				
				// выходим из цикла.
				break;
			}
		}
		
		if(roundDamage[findedClient] > 0)
		{
			PrintToChatAll("%t", "TopDamagers", i+1, findedClient, sortingRoundDamage[i]);
			topDamagers[i] = findedClient;
		}
		
		// После последней проверки закрываем топ (если в топе есть хоть 1 игрок).
		if(i == 4 && topDamagers[0] != 0) PrintToChatAll(" =================================");
	}
	
	// Награждаем игроков
	for(int i = 0; i < 5; i++)
	{
		// Если игрока нет, выходим.
		if(topDamagers[i] == 0) break;
		
		if(i == 0){
			g_iJZP[topDamagers[i]] += rewardTopDamager1;
			g_iTop1Damager[topDamagers[i]]++;
			PrintToChat(topDamagers[i], "%t", "Reward_TopDamager", prefix, rewardTopDamager1, g_iJZP[topDamagers[i]]);
		}
		else if(i == 1){
			g_iJZP[topDamagers[i]] += rewardTopDamager2;
			g_iTop2Damager[topDamagers[i]]++;
			PrintToChat(topDamagers[i], "%t", "Reward_TopDamagers", prefix, rewardTopDamager2, g_iJZP[topDamagers[i]]);
		}
		else if(i == 2){
			g_iJZP[topDamagers[i]] += rewardTopDamager3;
			g_iTop3Damager[topDamagers[i]]++;
			PrintToChat(topDamagers[i], "%t", "Reward_TopDamagers", prefix, rewardTopDamager3, g_iJZP[topDamagers[i]]);
		}
		else if(i == 3){
			g_iJZP[topDamagers[i]] += rewardTopDamagerOthers;
			g_iTop4Damager[topDamagers[i]]++;
			PrintToChat(topDamagers[i], "%t", "Reward_TopDamagers", prefix, rewardTopDamagerOthers, g_iJZP[topDamagers[i]]);
		}
		else{
			g_iJZP[topDamagers[i]] += rewardTopDamagerOthers;
			g_iTop5Damager[topDamagers[i]]++;
			PrintToChat(topDamagers[i], "%t", "Reward_TopDamagers", prefix, rewardTopDamagerOthers, g_iJZP[topDamagers[i]]);
		}
	}
}

public Action Timer_RoundEndReward(Handle timer, int winnerTeam)
{
	// Считаем количество живых людей.
	int iAliveHumans = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT) iAliveHumans++;
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(winnerTeam == CS_TEAM_CT)
			{
				if(GetClientTeam(i) == CS_TEAM_CT)
				{
					g_iHumanRoundsWon[i]++;
					
					int mvp = CS_GetMVPCount(i);
					CS_SetMVPCount(i, mvp + 1);
					
					if(IsPlayerAlive(i) && iAliveHumans == 1)
					{
						g_iJZP[i] += rewardSoloWin;
						PrintToChat(i, "%t", "Reward_Solo_Win", prefix, rewardSoloWin, g_iJZP[i]);
					}
					else if(IsPlayerAlive(i) && iAliveHumans == 2)
					{
						g_iJZP[i] += rewardDuoWin;
						PrintToChat(i, "%t", "Reward_Duo_Win", prefix, rewardDuoWin, g_iJZP[i]);
					}
					else if(IsPlayerAlive(i) && iAliveHumans == 3)
					{
						g_iJZP[i] += rewardTrioWin;
						PrintToChat(i, "%t", "Reward_Trio_Win", prefix, rewardTrioWin, g_iJZP[i]);
					}
					else
					{
						g_iJZP[i] += rewardWin;
						PrintToChat(i, "%t", "Reward_Win", prefix, rewardWin, g_iJZP[i]);
					}
				}
				else if(GetClientTeam(i) == CS_TEAM_T)
				{
					g_iZombieRoundsLose[i]++;
					g_iJZP[i] -= rewardLose;
					PrintToChat(i, "%t", "Reward_Lose", prefix, rewardLose, g_iJZP[i]);
				}
			}
			else if(winnerTeam == CS_TEAM_T)
			{
				if(GetClientTeam(i) == CS_TEAM_T)
				{
					// Если игрок проиграл человеком и победил зомби:
					if(!isFirstZombie[i])
					{
						g_iZombieRoundsWon[i]++;
						g_iJZP[i] += rewardWin;
					
						g_iHumanRoundsLose[i]++;
						g_iJZP[i] -= rewardLose;
						
						PrintToChat(i, "%t", "Reward_Win_Lose", prefix, rewardWin, rewardLose, g_iJZP[i]);
						continue;
					}
					
					g_iZombieRoundsWon[i]++;
					g_iJZP[i] += rewardWin;
					PrintToChat(i, "%t", "Reward_Win", prefix, rewardWin, g_iJZP[i]);
				}
				else if(GetClientTeam(i) == CS_TEAM_CT)
				{
					g_iHumanRoundsLose[i]++;
					g_iJZP[i] -= rewardLose;
					PrintToChat(i, "%t", "Reward_Lose", prefix, rewardLose, g_iJZP[i]);
				}
			}
		}
	}
}
/*
public Action Event_WeaponFire(Handle event, const char[] name, bool dontBroadcast)
{
	if(!statsEnabled) return;
	
	// Получаем название оружия.
	char weaponName[32] = "";
	GetEventString(event, "weapon", weaponName, sizeof(weaponName));
	
	// Если оружие - нож или граната, выходим.
	if(StrContains(weaponName, "knife") != -1
	|| StrContains(weaponName, "bayonet") != -1
	|| StrContains(weaponName, "hegrenade") != -1
	|| StrContains(weaponName, "molotov") != -1) return;
	
	// Получаем index стрелявшего игрока.
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Получаем index оружия, с которого выстрелил игрок.
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	// Получаем текущее количество патронов в обойме оружия.
	int clipCount = GetEntProp(weapon, Prop_Send, "m_iClip1");
	
	// Если в обойме 0 патронов, выходим.
	if(clipCount == 0) return;
	
	g_iHumanShots[client]++;
}
*/
public Action Event_Round_MVP(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int mvpcount = CS_GetMVPCount(client);
	
	CS_SetMVPCount(client, mvpcount - 1);
}

public void OnHealthChanged(const char[] output, int caller, int activator, float delay)
{
	// Если урон пропу нанёс не игрок, выходим.
	if(activator < 1 || activator > MaxClients) return;
	
	// Если урон получила несуществующая энтити, выходим.
	if(caller < 1 || caller > 2048) return;
	
	// Получаем здоровье пропа.
	int health = GetEntProp(caller, Prop_Data, "m_iHealth");
	
	// Показываем количество здоровья пропа игроку.
	if(health > 0 && health <= 50000) PrintHintText(activator, "%t", "PropHealth", health);
	
	if(!statsEnabled) return;
	
	// Получаем разницу между хп и старым хп.
	int difference = oldHealth[caller] - health;
	
	// Если разница больше 0 (при первом попадании меньше, т.к. старое здоровье еще не установлено) и меньше 500 (примерный макс. урон от гранат)
	if(oldHealth[caller] - health >= 0 && oldHealth[caller] - health <= 500)
	{
		g_iPropsDamage[activator] += difference;
		
		//Награда за определенное количество нанесенного урона пропам.
		tempPropDamageForReward[activator] += difference;
		if(tempPropDamageForReward[activator] > 5000)
		{
			g_iJZP[activator] += rewardPropDamage;
			PrintToChat(activator, "%t", "Reward_Props", prefix, rewardPropDamage, g_iJZP[activator]);
			tempPropDamageForReward[activator] = 0;
		}
		
		// Если игрок - человек, засчитываем попадание.
		if(GetClientTeam(activator) == CS_TEAM_CT) g_iHumanHits[activator]++;
	}
	
	// Сохраняем количество здоровья пропа.
	oldHealth[caller] = health;
}

int Calculate_ZBR(int client)
{
	// Коэффициент побед.
	float winCoef = float(g_iZombieRoundsWon[client]) / float(g_iZombieRoundsWon[client] + g_iZombieRoundsLose[client]);
	//PrintToChatAll("winCoef: %f", winCoef);
	
	// Компонент побед.
	float winComp = 6000/(1 + Pow(2.71828, 16-19*winCoef));
	//PrintToChatAll("winComp: %f", winComp);
	
	//=======================================
	
	// Коэффициент убийств/смертей.
	float kdCoef = float(g_iZombieInfections[client]) / float(g_iZombieDeaths[client]);
	//PrintToChatAll("kdCoef: %f", kdCoef);
	
	// Компонент убийств/смертей.
	float kdComp = 6000/(1 + Pow(1.71828, 8-2*kdCoef));
	//PrintToChatAll("kdComp: %f", kdComp);
	
	//=======================================
	
	// Защита от малого количества раундов.
	float protect = 1/(1 + Pow(1.71828, 5-0.15*(g_iZombieRoundsWon[client] + g_iZombieRoundsLose[client])));
	//PrintToChatAll("protectCoef: %f", protect);
	
	//=======================================
	
	// Формула ZBR.
	int ZBR = RoundToZero((winComp + kdComp) * protect);
	//PrintToChatAll("ZBR: %i", ZBR);
	
	// Если ZBR меньше 0, устанавливаем на 0.
	if(ZBR < 0) ZBR = 0;
	
	g_iZBR[client] = ZBR;
	
	return ZBR;
}

int Calculate_HMR(int client)
{
	// Коэффициент побед.
	float winCoef = float(g_iHumanRoundsWon[client]) / float(g_iHumanRoundsWon[client] + g_iHumanRoundsLose[client]);
	//PrintToChatAll("winCoef: %f", winCoef);
	
	// Компонент побед.
	float winComp = 3500/(1 + Pow(2.71828, 4-13*winCoef));
	//PrintToChatAll("winComp: %f", winComp);
	
	//=======================================
	
	// Коэффициент убийств/смертей.
	float kdCoef = float(g_iHumanKills[client]) / float(g_iHumanDeaths[client]);
	//PrintToChatAll("kdCoef: %f", kdCoef);
	
	// Компонент убийств/смертей.
	float kdComp = 3000/(1 + Pow(2.71828, 2-5*kdCoef));
	//PrintToChatAll("kdComp: %f", kdComp);
	
	//=======================================
	
	// Средний урон за раунд.
	float dmgAvg = float(g_iHumanDamage[client]) / float(g_iHumanRoundsWon[client] + g_iHumanRoundsLose[client]);
	//PrintToChatAll("dmg: %i, rounds: %i, dmgAvg: %f", g_iHumanDamage[client], g_iHumanRoundsWon[client] + g_iHumanRoundsLose[client], dmgAvg);
	
	// Компонент урона.
	float dmgComp = 3700/(1 + Pow(2.71828, 4-8*(dmgAvg / 10000)));
	//PrintToChatAll("dmgComp: %f", dmgComp);
	
	//=======================================
	
	// Коэффициент убийств/убийств в голову.
	float khsCoef = float(g_iHumanHeadShots[client]) / float(g_iHumanKills[client]);
	//PrintToChatAll("khsCoef: %f", khsCoef);
	
	// Компонент убийств/убийств в голову.
	float khsComp = 1000/(1 + Pow(2.71828, 2-13*khsCoef));
	//PrintToChatAll("khsComp: %f", khsComp);
	
	//=======================================
	
	// Коэффициент выстрелов/попаданий.
	float accCoef = float(g_iHumanHits[client]) / float(g_iHumanShots[client]);
	//PrintToChatAll("accCoef: %f", accCoef);
	
	// Компонент выстрелов/попаданий.
	float accComp = 2000/(1 + Pow(2.71828, 4-10*accCoef));
	//PrintToChatAll("accComp: %f", accComp);
	
	//=======================================
	
	// Защита от малого количества раундов.
	float protect = 1/(1 + Pow(1.71828, 5-0.15*(g_iHumanRoundsWon[client] + g_iHumanRoundsLose[client])));
	//PrintToChatAll("protectCoef: %f", protect);
	
	//=======================================
	
	// Формула HMR.
	int HMR = RoundToZero((winComp + kdComp + dmgComp + khsComp + accComp) * protect);
	//PrintToChatAll("HMR: %i", HMR);
	
	// Если HMR меньше 0, устанавливаем на 0.
	if(HMR < 0) HMR = 0;
	
	g_iHMR[client] = HMR;
	
	return HMR;
}

Action CommandListener_Say(int client, const char[] command, int argc)
{
	char tempChar[8];
	GetCmdArg(1, tempChar, sizeof(tempChar));
	
	// Команда вызова меню со статистикой
	if(StrEqual(tempChar, "zstats", false)) ShowStatsMenu(client);
	
	// Команда вывода топа
	else if(StrEqual(tempChar, "top", false)) ShowTopMenu(client);
}

ShowStatsMenu(int client)
{
	SetGlobalTransTarget(client);
	
	char human[128], zombie[128], all[32], online[32], top[64], HMR[16], ZBR[16], hkd[8], zkd[8];

	int iHMR = Calculate_HMR(client);
	int iZBR = Calculate_ZBR(client);
	
	if(iHMR == 0) Format(HMR, sizeof(HMR), "--");
	else Format(HMR, sizeof(HMR), "%i", iHMR);
	if(iZBR == 0) Format(ZBR, sizeof(ZBR), "--");
	else Format(ZBR, sizeof(ZBR), "%i", iZBR);
	
	// Коэффициент убийств/смертей человека.
	float hkdCoef = float(g_iHumanKills[client]) / float(g_iHumanDeaths[client]);
	if(g_iHumanDeaths[client] == 0) Format(hkd, sizeof(hkd), "--");
	else Format(hkd, sizeof(hkd), "%0.2f", hkdCoef);
	
	// Коэффициент убийств/смертей зомби.
	float zkdCoef = float(g_iZombieInfections[client]) / float(g_iZombieDeaths[client]);
	if(g_iZombieDeaths[client] == 0) Format(zkd, sizeof(zkd), "--");
	else Format(zkd, sizeof(zkd), "%0.2f", zkdCoef); 
	
	Format(human, sizeof(human), "%t", "ZStats_Stats_Human", HMR, g_iHumanKills[client], g_iHumanDeaths[client], hkd);
	Format(zombie, sizeof(zombie), "%t", "ZStats_Stats_Zombie", ZBR, g_iZombieInfections[client], g_iZombieDeaths[client], zkd);
	Format(all, sizeof(all), "JZP: [%i]", g_iJZP[client]);
	Format(online, sizeof(online), "%t", "ZStats_Stats_Online", float(g_iOnlineTime[client] + (GetTime() - onlineTime[client])) / 3600);
	Format(top, sizeof(top), "%t", "ZStats_Top");
	
	Menu stats = new Menu(StatsHandler);
	stats.SetTitle("%T", "ZStats_Menu_Title", client);
	stats.AddItem("", human);
	stats.AddItem("", zombie);
	stats.AddItem("", all);
	stats.AddItem("", online);
	stats.AddItem("", top);
	stats.Display(client, 180);
}

public StatsHandler(Menu stats, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) 
	{
		if(option == 0) ShowHumanMenu(client);
		else if(option == 1) ShowZombieMenu(client);
		else if(option == 2) ShowRankMenu(client);
		else if(option == 3) ShowOnlineMenu(client);
		else if(option == 4) ShowTopMenu(client);
		else ShowStatsMenu(client);
	}
	else if(action == MenuAction_End) delete stats;
}

ShowHumanMenu(int client)
{
	SetGlobalTransTarget(client);
	
	char info[512], info2[128], back[16], wl[8], acc[8], hsacc[8], hs[8];

	// Коэффициент побед.
	float wlCoef = float(g_iHumanRoundsWon[client]) / float(g_iHumanRoundsWon[client] + g_iHumanRoundsLose[client]);
	Format(wl, sizeof(wl), "%0.2f%", wlCoef*100); 
	
	// Средний урон за раунд.
	int dmgAvg = RoundToZero(float(g_iHumanDamage[client]) / (g_iHumanRoundsWon[client] + g_iHumanRoundsLose[client]));
	if(dmgAvg < 0) dmgAvg = 0;
	
	// Коэффициент выстрелов/попаданий.
	float accCoef = float(g_iHumanHits[client]) / float(g_iHumanShots[client]);
	Format(acc, sizeof(acc), "%0.2f%", accCoef*100); 
	
	// Коэффициент попаданий в голову.
	float hssCoef = float(g_iHumanHeadShotsHits[client]) / float(g_iHumanHits[client]);
	Format(hsacc, sizeof(hsacc), "%0.2f%", hssCoef*100);
	
	// Коэффициент убийств/убийств в голову.
	float hsCoef = float(g_iHumanHeadShots[client]) / float(g_iHumanKills[client]);
	Format(hs, sizeof(hs), "%0.2f%", hsCoef*100);
	
	Format(info, sizeof(info), "%t", "ZStats_Extended_Human", g_iHumanRoundsWon[client] + g_iHumanRoundsLose[client], wl, g_iHumanShots[client], acc, hsacc, g_iHumanDamage[client], dmgAvg, g_iAssists[client], hs, g_iPropsDamage[client]);
	Format(info2, sizeof(info2), "%t", "ZStats_Damagers_Human", g_iTop1Damager[client], g_iTop2Damager[client], g_iTop3Damager[client], g_iTop4Damager[client], g_iTop5Damager[client]);
	Format(back, sizeof(back), "%t", "ZStats_Back");
	
	Menu human = new Menu(HumanHandler);
	human.SetTitle("%T", "ZStats_Human_Menu_Title", client);
	human.AddItem("", info);
	human.AddItem("", info2);
	human.AddItem("", back);
	human.Display(client, 180);
}

public HumanHandler(Menu human, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		if(option == 2) ShowStatsMenu(client);
		else ShowHumanMenu(client);
	}
	else if(action == MenuAction_End) delete human;
}

ShowZombieMenu(int client)
{
	SetGlobalTransTarget(client);
	
	char info[512], back[16], wl[8];

	// Коэффициент побед.
	float wlCoef = float(g_iZombieRoundsWon[client]) / float(g_iZombieRoundsWon[client] + g_iZombieRoundsLose[client]);
	Format(wl, sizeof(wl), "%0.2f%", wlCoef*100); 
	
	Format(info, sizeof(info), "%t", "ZStats_Extended_Zombie", g_iZombieRoundsWon[client] + g_iZombieRoundsLose[client], wl, g_iZombieTakedDamage[client], g_iFirstZombiePlays[client]);
	Format(back, sizeof(back), "%t", "ZStats_Back");

	Menu zombie = new Menu(ZombieHandler);
	zombie.SetTitle("%T", "ZStats_Zombie_Menu_Title", client);
	zombie.AddItem("", info);
	zombie.AddItem("", back);
	zombie.Display(client, 180);
}

public ZombieHandler(Menu zombie, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		if(option == 1) ShowStatsMenu(client);
		else ShowZombieMenu(client);
	}
	else if(action == MenuAction_End) delete zombie;
}

ShowRankMenu(int client)
{
	SetGlobalTransTarget(client);
	
	char rank[64], currentRank[128], progress[64], back[16];
	
	int minPoints, neededPoints;
	
	if(g_iJZP[client] >= 102065)
	{
		Format(rank, sizeof(rank), "%t %t", "TheGlobalElite", "Master"); // "Всемирная Элита (Мастер)"
		neededPoints = 10000000;
		minPoints = g_iJZP[client];
	}
	else if(g_iJZP[client] >= 88065)
	{
		Format(rank, sizeof(rank), "%t", "TheGlobalElite"); // "Всемирная Элита"
		neededPoints = 102065;
		minPoints = 88065;
	}
	else if(g_iJZP[client] >= 68065)
	{
		Format(rank, sizeof(rank), "%t %t", "SupremeMasterFirstClass", "Master"); // "Великий Магистр Высшего Ранга (Мастер)"
		neededPoints = 88065;
		minPoints = 68065;
	}
	else if(g_iJZP[client] >= 59665)
	{
		Format(rank, sizeof(rank), "%t", "SupremeMasterFirstClass"); // "Великий Магистр Высшего Ранга"
		neededPoints = 68065;
		minPoints = 59665;
	}
	else if(g_iJZP[client] >= 47665)
	{
		Format(rank, sizeof(rank), "%t %t", "LegendaryEagleMaster", "Master"); // "Легендарный Беркут-магистр (Мастер)"
		neededPoints = 59665;
		minPoints = 47665;
	}
	else if(g_iJZP[client] >= 42765)
	{
		Format(rank, sizeof(rank), "%t", "LegendaryEagleMaster"); // "Легендарный Беркут-магистр"
		neededPoints = 47665;
		minPoints = 42765;
	}
	else if(g_iJZP[client] >= 35765)
	{
		Format(rank, sizeof(rank), "%t %t", "LegendaryEagle", "Master"); // "Легендарный Беркут (Мастер)"
		neededPoints = 42765;
		minPoints = 35765;
	}
	else if(g_iJZP[client] >= 32265)
	{
		Format(rank, sizeof(rank), "%t", "LegendaryEagle"); // "Легендарный Беркут"
		neededPoints = 35765;
		minPoints = 32265;
	}
	else if(g_iJZP[client] >= 27265)
	{
		Format(rank, sizeof(rank), "%t %t", "DistinguishedMasterGuardian", "Master"); // "Заслуженный Магистр-хранитель (Мастер)"
		neededPoints = 32265;
		minPoints = 27265;
	}
	else if(g_iJZP[client] >= 24115)
	{
		Format(rank, sizeof(rank), "%t", "DistinguishedMasterGuardian"); // "Заслуженный Магистр-хранитель"
		neededPoints = 27265;
		minPoints = 24115;
	}
	else if(g_iJZP[client] >= 19615)
	{
		Format(rank, sizeof(rank), "%t %t", "MasterGuardianElite", "Master"); // "Магистр-хранитель - Элита (Мастер)"
		neededPoints = 24115;
		minPoints = 19615;
	}
	else if(g_iJZP[client] >= 17305)
	{
		Format(rank, sizeof(rank), "%t", "MasterGuardianElite"); // "Магистр-хранитель - Элита"
		neededPoints = 19615;
		minPoints = 17305;
	}
	else if(g_iJZP[client] >= 14005)
	{
		Format(rank, sizeof(rank), "%t %t", "MasterGuardianII", "Master"); // "Магистр-хранитель - II (Мастер)"
		neededPoints = 17305;
		minPoints = 14005;
	}
	else if(g_iJZP[client] >= 12255)
	{
		Format(rank, sizeof(rank), "%t", "MasterGuardianII"); // "Магистр-хранитель - II"
		neededPoints = 14005;
		minPoints = 12255;
	}
	else if(g_iJZP[client] >= 9755)
	{
		Format(rank, sizeof(rank), "%t %t", "MasterGuardianI", "Master"); // "Магистр-хранитель - I (Мастер)"
		neededPoints = 12255;
		minPoints = 9755;
	}
	else if(g_iJZP[client] >= 8565)
	{
		Format(rank, sizeof(rank), "%t", "MasterGuardianI"); // "Магистр-хранитель - I"
		neededPoints = 9755;
		minPoints = 8565;
	}
	else if(g_iJZP[client] >= 6865)
	{
		Format(rank, sizeof(rank), "%t %t", "GoldNovaMaster", "Master"); // "Золотая Звезда - Магистр (Мастер)"
		neededPoints = 8565;
		minPoints = 6865;
	}
	else if(g_iJZP[client] >= 6200)
	{
		Format(rank, sizeof(rank), "%t", "GoldNovaMaster"); // "Золотая Звезда - Магистр"
		neededPoints = 6865;
		minPoints = 6200;
	}
	else if(g_iJZP[client] >= 5250)
	{
		Format(rank, sizeof(rank), "%t %t", "GoldNovaIII", "Master"); // "Золотая Звезда - III (Мастер)"
		neededPoints = 6200;
		minPoints = 5250;
	}
	else if(g_iJZP[client] >= 4760)
	{
		Format(rank, sizeof(rank), "%t", "GoldNovaIII"); // "Золотая Звезда - III"
		neededPoints = 5250;
		minPoints = 4760;
	}
	else if(g_iJZP[client] >= 4060)
	{
		Format(rank, sizeof(rank), "%t %t", "GoldNovaII", "Master"); // "Золотая Звезда - II (Мастер)"
		neededPoints = 4760;
		minPoints = 4060;
	}
	else if(g_iJZP[client] >= 3710)
	{
		Format(rank, sizeof(rank), "%t", "GoldNovaII"); // "Золотая Звезда - II"
		neededPoints = 4060;
		minPoints = 3710;
	}
	else if(g_iJZP[client] >= 3210)
	{
		Format(rank, sizeof(rank), "%t %t", "GoldNovaI", "Master"); // "Золотая Звезда - I (Мастер)"
		neededPoints = 3710;
		minPoints = 3210;
	}
	else if(g_iJZP[client] >= 2965)
	{
		Format(rank, sizeof(rank), "%t", "GoldNovaI"); // "Золотая Звезда - I"
		neededPoints = 3210;
		minPoints = 2965;
	}else if(g_iJZP[client] >= 2615)
	{
		Format(rank, sizeof(rank), "%t %t", "SilverEliteMaster", "Master"); // "Серебро - Великий Магистр (Мастер)"
		neededPoints = 2965;
		minPoints = 2615;
	}
	else if(g_iJZP[client] >= 2440)
	{
		Format(rank, sizeof(rank), "%t", "SilverEliteMaster"); // "Серебро - Великий Магистр"
		neededPoints = 2615;
		minPoints = 2440;
	}
	else if(g_iJZP[client] >= 2190)
	{
		Format(rank, sizeof(rank), "%t %t", "SilverElite", "Master"); // "Серебро - Элита (Мастер)"
		neededPoints = 2440;
		minPoints = 2190;
	}
	else if(g_iJZP[client] >= 2050)
	{
		Format(rank, sizeof(rank), "%t", "SilverElite"); // "Серебро - Элита"
		neededPoints = 2190;
		minPoints = 2050;
	}
	else if(g_iJZP[client] >= 1850)
	{
		Format(rank, sizeof(rank), "%t %t", "SilverIV", "Master"); // "Серебро - IV (Мастер)"
		neededPoints = 2050;
		minPoints = 1850;
	}
	else if(g_iJZP[client] >= 1745)
	{
		Format(rank, sizeof(rank), "%t", "SilverIV"); // "Серебро - IV"
		neededPoints = 1850;
		minPoints = 1745;
	}
	else if(g_iJZP[client] >= 1595)
	{
		Format(rank, sizeof(rank), "%t %t", "SilverIII", "Master"); // "Серебро - III (Мастер)"
		neededPoints = 1745;
		minPoints = 1595;
	}
	else if(g_iJZP[client] >= 1490)
	{
		Format(rank, sizeof(rank), "%t", "SilverIII"); // "Серебро - III"
		neededPoints = 1595;
		minPoints = 1490;
	}
	else if(g_iJZP[client] >= 1340)
	{
		Format(rank, sizeof(rank), "%t %t", "SilverII", "Master"); // "Серебро - II (Мастер)"
		neededPoints = 1490;
		minPoints = 1340;
	}
	else if(g_iJZP[client] >= 1270)
	{
		Format(rank, sizeof(rank), "%t", "SilverII"); // "Серебро - II"
		neededPoints = 1340;
		minPoints = 1270;
	}
	else if(g_iJZP[client] >= 1170)
	{
		Format(rank, sizeof(rank), "%t %t", "SilverI", "Master"); // "Серебро - I (Мастер)"
		neededPoints = 1270;
		minPoints = 1170;
	}
	else if(g_iJZP[client] >= 1100)
	{
		Format(rank, sizeof(rank), "%t", "SilverI"); // "Серебро - I"
		neededPoints = 1170;
		minPoints = 1100;
	}
	else if(g_iJZP[client] >= 980)
	{
		Format(rank, sizeof(rank), "%t", "Calibration"); // "Калибровка"
		neededPoints = 1100;
		minPoints = 980;
	}
	else
	{
		Format(rank, sizeof(rank), "%t", "NotRanked"); // "Без ранга"
		neededPoints = 980;
		minPoints = 0;
	}
	
	Format(currentRank, sizeof(currentRank), "%t", "ZStats_Current_Rank", rank);
	
	int percent = RoundToZero(float((g_iJZP[client] - minPoints) * 100) / (neededPoints - minPoints));
	
	Format(progress, sizeof(progress), "%t", "ZStats_Progress", percent);	
	
	Format(back, sizeof(back), "%t", "ZStats_Back");
	
	Menu rankMenu = new Menu(RankHandler);
	rankMenu.SetTitle("%T", "ZStats_Rank_Title", client);
	rankMenu.AddItem("", currentRank);
	rankMenu.AddItem("", progress);
	rankMenu.AddItem("", back);
	rankMenu.Display(client, 180);
}

public RankHandler(Menu rankMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		if(option == 2) ShowStatsMenu(client);
		else ShowRankMenu(client);
	}
	else if(action == MenuAction_End) delete rankMenu;
}

ShowOnlineMenu(int client)
{
	SetGlobalTransTarget(client);
	
	char info[128], info2[128], back[16], totalTime[64], totalPlayTime[64];
	
	// Общее время на сервере.
	int time = g_iOnlineTime[client] + (GetTime() - onlineTime[client]);
	Format(totalTime, sizeof(totalTime), "%t", "ZStats_Total_Online_Time", time/3600/24, time/3600%24, time/60%60, float(time)/3600);
	
	// Время активной игры.
	int playTime = g_iOnlinePlayTime[client];
	Format(totalPlayTime, sizeof(totalPlayTime), "%t", "ZStats_Total_Online_PlayTime", playTime/3600/24, playTime/3600%24, playTime/60%60, float(playTime)/3600);
	
	Format(info, sizeof(info), "%t", "ZStats_Total_Time", totalTime);
	Format(info2, sizeof(info2), "%t", "ZStats_Total_PlayTime", totalPlayTime);
	Format(back, sizeof(back), "%t", "ZStats_Back");

	Menu online = new Menu(OnlineHandler);
	online.SetTitle("%T", "ZStats_Online_Menu_Title", client);
	online.AddItem("", info);
	online.AddItem("", info2);
	online.AddItem("", back);
	online.Display(client, 180);
}

public OnlineHandler(Menu online, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		if(option == 2) ShowStatsMenu(client);
		else ShowOnlineMenu(client);
	}
	else if(action == MenuAction_End) delete online;
}

ShowTopMenu(int client)
{
	SetGlobalTransTarget(client);
	
	char zbr[32], hmr[32], jzp[32], online[32], damage[36], backtostats[32];
	
	Format(zbr, sizeof(zbr), "%t", "ZStats_ZBR");
	Format(hmr, sizeof(hmr), "%t", "ZStats_HMR");
	Format(jzp, sizeof(jzp), "%t", "ZStats_JZP");
	Format(damage, sizeof(damage), "%t", "ZStats_Top_Damage");
	Format(online, sizeof(online), "%t\n ", "ZStats_Online");
	Format(backtostats, sizeof(backtostats), "%t", "ZStats_MyStats");
	
	Menu top = new Menu(TopHandler);
	top.SetTitle("%T", "ZStats_Top_Title", client);
	top.AddItem("zbr", zbr);
	top.AddItem("hmr", hmr);
	top.AddItem("jzp", jzp);
	top.AddItem("damage", damage);
	top.AddItem("online", online);
	top.AddItem("", backtostats);
	top.Display(client, 180);
}

public TopHandler(Menu top, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		if(option == 0)
		{
			char szQuery[128];
			FormatEx(szQuery, sizeof(szQuery),  "SELECT `name`, `ZBR` FROM `table_zstats` ORDER BY `ZBR` DESC LIMIT 12 OFFSET 0");
			g_hDatabase.Query(SQL_ZBRCallback, szQuery, client);
		}
		else if(option == 1)
		{
			char szQuery[128];
			FormatEx(szQuery, sizeof(szQuery),  "SELECT `name`, `HMR` FROM `table_zstats` ORDER BY `HMR` DESC LIMIT 12 OFFSET 0");
			g_hDatabase.Query(SQL_HMRCallback, szQuery, client);
		}
		else if(option == 2)
		{
			char szQuery[128];
			FormatEx(szQuery, sizeof(szQuery),  "SELECT `name`, `JZP` FROM `table_zstats` ORDER BY `JZP` DESC LIMIT 12 OFFSET 0");
			g_hDatabase.Query(SQL_JZPCallback, szQuery, client);
		}
		else if(option == 3)
		{
			char szQuery[128];
			FormatEx(szQuery, sizeof(szQuery),  "SELECT `name`, `human_damage` FROM `table_zstats` ORDER BY `human_damage` DESC LIMIT 12 OFFSET 0");
			g_hDatabase.Query(SQL_DamageCallback, szQuery, client);
		}
		else if(option == 4) ShowExtendedOnlineMenu(client);
		else if(option == 5) ShowStatsMenu(client);
	}
	else if(action == MenuAction_End) delete top;
}

ShowExtendedOnlineMenu(int client)
{
	SetGlobalTransTarget(client);
	
	char totalOnline[64], playTime[64], back[16];
	
	Format(totalOnline, sizeof(totalOnline), "%t", "ZStats_Top_TotalOnline");
	Format(playTime, sizeof(playTime), "%t\n ", "ZStats_Top_PlayTime");
	Format(back, sizeof(back), "%t", "ZStats_Back");
	
	Menu onlineTop = new Menu(OnlineTopHandler);
	onlineTop.SetTitle("%T", "ZStats_Online_Top_Title", client);
	onlineTop.AddItem("total", totalOnline);
	onlineTop.AddItem("playtime", playTime);
	onlineTop.AddItem("", back);
	onlineTop.Display(client, 180);
}

public OnlineTopHandler(Menu onlineTop, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		if(option == 0)
		{
			char szQuery[128];
			FormatEx(szQuery, sizeof(szQuery),  "SELECT `name`, `online_time` FROM `table_zstats` ORDER BY `online_time` DESC LIMIT 12 OFFSET 0");
			g_hDatabase.Query(SQL_TotalOnlineCallback, szQuery, client);
		}
		else if(option == 1)
		{
			char szQuery[128];
			FormatEx(szQuery, sizeof(szQuery),  "SELECT `name`, `online_playtime` FROM `table_zstats` ORDER BY `online_playtime` DESC LIMIT 12 OFFSET 0");
			g_hDatabase.Query(SQL_OnlinePlayTimeCallback, szQuery, client);
		}
		else if(option == 2) ShowTopMenu(client);
	}
	else if(action == MenuAction_End) delete onlineTop;
}

public void SQL_ZBRCallback(Database hDatabase, DBResultSet hResults, const char[] sError, any client)
{
	if(sError[0]) return;
	
	SetGlobalTransTarget(client);
	
	int i;
	char info[512], nick[32];
	Format(info, sizeof(info), "%t", "ZStats_ZBR_Top_Title");
	
	while(hResults.FetchRow())
	{
		i++;
		hResults.FetchString(0, nick, sizeof(nick));
		
		Format(info, sizeof(info), "%s\n%i. %s: %i ZBR", info, i, nick, hResults.FetchInt(1));
	}
	
	Menu zbr = new Menu(TopZBRHandler);
	zbr.AddItem("", info);
	zbr.ExitButton = false;
	zbr.Display(client, 180);
}

public TopZBRHandler(Menu zbr, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) ShowTopMenu(client);
	else if(action == MenuAction_End) delete zbr;
}

public void SQL_HMRCallback(Database hDatabase, DBResultSet hResults, const char[] sError, any client)
{
	if(sError[0]) return;
	
	SetGlobalTransTarget(client);
	
	int i;
	char info[512], nick[32];
	Format(info, sizeof(info), "%t", "ZStats_HMR_Top_Title");
	
	while(hResults.FetchRow())
	{
		i++;
		hResults.FetchString(0, nick, sizeof(nick));
		
		Format(info, sizeof(info), "%s\n%i. %s: %i HMR", info, i, nick, hResults.FetchInt(1));
	}
	
	Menu hmr = new Menu(TopHMRHandler);
	hmr.AddItem("", info);
	hmr.ExitButton = false;
	hmr.Display(client, 180);
}

public TopHMRHandler(Menu hmr, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) ShowTopMenu(client);
	else if(action == MenuAction_End) delete hmr;
}

public void SQL_JZPCallback(Database hDatabase, DBResultSet hResults, const char[] sError, any client)
{
	if(sError[0]) return;
	
	SetGlobalTransTarget(client);
	
	int i;
	char info[512], nick[32];
	Format(info, sizeof(info), "%t", "ZStats_JZP_Top_Title");
	
	while(hResults.FetchRow())
	{
		i++;
		hResults.FetchString(0, nick, sizeof(nick));
		
		Format(info, sizeof(info), "%s\n%i. %s: %i JZP", info, i, nick, hResults.FetchInt(1));
	}
	
	Menu jzp = new Menu(TopJZPHandler);
	jzp.AddItem("", info);
	jzp.ExitButton = false;
	jzp.Display(client, 180);
}

public TopJZPHandler(Menu jzp, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) ShowTopMenu(client);
	else if(action == MenuAction_End) delete jzp;
}

public void SQL_TotalOnlineCallback(Database hDatabase, DBResultSet hResults, const char[] sError, any client)
{
	if(sError[0]) return;
	
	SetGlobalTransTarget(client);
	
	int i;
	char info[512], nick[32];
	Format(info, sizeof(info), "%t", "ZStats_Total_Online_Top_Title");
	
	while(hResults.FetchRow())
	{
		i++;
		hResults.FetchString(0, nick, sizeof(nick));
		
		Format(info, sizeof(info), "%t", "ZStats_Online_Top", info, i, nick, float(hResults.FetchInt(1)) / 3600);
	}
	
	Menu totalOnline = new Menu(TopTotalOnlineHandler);
	totalOnline.AddItem("", info);
	totalOnline.ExitButton = false;
	totalOnline.Display(client, 180);
}

public TopTotalOnlineHandler(Menu totalOnline, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) ShowExtendedOnlineMenu(client);
	else if(action == MenuAction_End) delete totalOnline;
}

public void SQL_OnlinePlayTimeCallback(Database hDatabase, DBResultSet hResults, const char[] sError, any client)
{
	if(sError[0]) return;
	
	SetGlobalTransTarget(client);
	
	int i;
	char info[512], nick[32];
	Format(info, sizeof(info), "%t", "ZStats_Online_PlayTime_Top_Title");
	
	while(hResults.FetchRow())
	{
		i++;
		hResults.FetchString(0, nick, sizeof(nick));
		
		Format(info, sizeof(info), "%t", "ZStats_Online_Top", info, i, nick, float(hResults.FetchInt(1)) / 3600);
	}
	
	Menu onlinePlayTime = new Menu(TopOnlinePlayTimeHandler);
	onlinePlayTime.AddItem("", info);
	onlinePlayTime.ExitButton = false;
	onlinePlayTime.Display(client, 180);
}

public TopOnlinePlayTimeHandler(Menu onlinePlayTime, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) ShowExtendedOnlineMenu(client);
	else if(action == MenuAction_End) delete onlinePlayTime;
}

public void SQL_DamageCallback(Database hDatabase, DBResultSet hResults, const char[] sError, any client)
{
	if(sError[0]) return;
	
	SetGlobalTransTarget(client);
	
	int i;
	char info[512], nick[32];
	Format(info, sizeof(info), "%t", "ZStats_Damage_Top_Title");
	
	while(hResults.FetchRow())
	{
		i++;
		hResults.FetchString(0, nick, sizeof(nick));
		
		Format(info, sizeof(info), "%t", "ZStats_Damage_Top_List", info, i, nick, hResults.FetchInt(1));
	}
	
	Menu damageMenu = new Menu(TopDamageHandler);
	damageMenu.AddItem("", info);
	damageMenu.ExitButton = false;
	damageMenu.Display(client, 180);
}

public TopDamageHandler(Menu damageMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) ShowTopMenu(client);
	else if(action == MenuAction_End) delete damageMenu;
}
