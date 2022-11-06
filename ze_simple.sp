
float infectTime;
int zombieRatio;
int maxFirstZombies;
int humanHealth;
int vipHumanHealth = 150;
int zombieHealth;
int vipZombieHealth = 16000;
int gainHealth;
int zteleMaxUses;
float respawnTime;
//float heightMultiplier;

ConVar Convar_InfectTime;
ConVar Convar_ZombieRatio;
ConVar Convar_MaxFirstZombies;
ConVar Convar_HumanHealth;
ConVar Convar_ZombieHealth;
ConVar Convar_GainHealth;
ConVar Convar_ZteleMaxUses;
ConVar Convar_RespawnTime;
//ConVar Convar_JumpHeight;

ConVar Convar_ZR_InfectTime;
ConVar Convar_ZR_ZombieRatio;

//int g_vecVelocity;
int g_WaterLevel;

int iKills[MAXPLAYERS+1];
int iAssists[MAXPLAYERS+1];
int iDeaths[MAXPLAYERS+1];
int iMVP[MAXPLAYERS+1];
int iScore[MAXPLAYERS+1];

int infectCountdownCounter;
int zteleCounter[MAXPLAYERS+1];
int zteleAmount[MAXPLAYERS+1];
float startZteleCoordinates[MAXPLAYERS+1][3];
float g_vecSpawn[MAXPLAYERS+1][3];
float g_fDeathTime[MAXPLAYERS+1];

float hurtVolume[MAXPLAYERS+1];
float deathVolume[MAXPLAYERS+1];
float infectVolume[MAXPLAYERS+1];

bool b_FirstZombieInfected;
bool g_bBlockRespawn = false;
bool g_bDoubleInfectProtect[MAXPLAYERS+1];
bool g_b_TempDoubleInfectProtect[MAXPLAYERS+1];
Handle tFirstInfect = INVALID_HANDLE;
Handle tInfectCountdown = INVALID_HANDLE;
Handle tZtele[MAXPLAYERS+1] = INVALID_HANDLE;
Handle fullAllTalk = INVALID_HANDLE;
Handle roundRestartDelay = INVALID_HANDLE;

Handle h_HurtVolumeCookie = INVALID_HANDLE;
Handle h_DeathVolumeCookie = INVALID_HANDLE;
Handle h_InfectVolumeCookie = INVALID_HANDLE;

#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <ClientPrefs>
#include <ze_simple_lib>

public Plugin myinfo =
{
	name = "Simple Zombie Escape",
	author = "Walderr",
	description = "Simple Zombie Escape Mod",
	version = "0.9.2 Beta",
	url = "http://jaze.ru/"
};

public void OnPluginStart()
{
	LoadTranslations("ze_simple.phrases");

	HookEvent("player_team", Event_PlayerTeam);
	//HookEvent("player_jump", Event_PlayerJump);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("round_prestart", Event_RoundPreStart);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	
	AddCommandListener(OnJoinTeam, "jointeam");
	
	// Добавляем возможность включать фонарик.
	AddCommandListener(Command_LookAtWeapon, "+lookatweapon");	
	
	// Блокируем выполнение суицидальных команд.
	AddCommandListener(BlockCommand, "spectate");
	AddCommandListener(BlockCommand, "explode");
	AddCommandListener(BlockCommand, "explodevector");
	AddCommandListener(BlockCommand, "kill");
	AddCommandListener(BlockCommand, "killvector");
	
	fullAllTalk = FindConVar("sv_full_alltalk");
	roundRestartDelay = FindConVar("mp_round_restart_delay");
	
	//g_vecVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	g_WaterLevel = FindSendPropInfo("CBasePlayer", "m_nWaterLevel");
	
	// Регистрируем команды.
	RegConsoleCmd("sm_ztele", Command_Ztele, "Телепортироваться в точку возрождения");
	RegConsoleCmd("ztele", Command_Ztele, "Телепортироваться в точку возрождения");
	RegConsoleCmd("sm_zvolume", Command_Zvolume, "Управление громкостью звуков зомби");
	RegConsoleCmd("sm_zsound", Command_Zvolume, "Управление громкостью звуков зомби");
	
	RegAdminCmd("sm_movetohumans", Command_MoveToHumans, ADMFLAG_UNBAN, "Перенести игрока к людям");
	RegAdminCmd("sm_movetozombies", Command_MoveToZombies, ADMFLAG_UNBAN, "Перенести игрока к зомби");
	
	// Куки
	h_HurtVolumeCookie = RegClientCookie("HurtVolume", "Громкость звука когда зомби получает урон", CookieAccess_Private);
	h_DeathVolumeCookie = RegClientCookie("DeathVolume", "Громкость звука когда зомби умирает", CookieAccess_Private);
	h_InfectVolumeCookie = RegClientCookie("InfectVolume", "Громкость звука при заражении", CookieAccess_Private);
	
	// Конвары
	Convar_InfectTime = CreateConVar("ze_infect_time", "20", "Время до появления первых зомби");
	Convar_ZombieRatio = CreateConVar("ze_zombie_ratio", "7", "Соотношение зомби к людям");
	Convar_MaxFirstZombies = CreateConVar("ze_max_first_zombies", "64", "Максимальное количество первых зомби");
	Convar_HumanHealth = CreateConVar("ze_human_health", "100", "Количество здоровья у людей");
	Convar_ZombieHealth = CreateConVar("ze_zombie_health", "12000", "Количество здоровья у зомби");
	Convar_GainHealth = CreateConVar("ze_gain_health", "2000", "Количество здоровья, добавляемое за заражение человека");
	Convar_ZteleMaxUses = CreateConVar("ze_ztele_max_uses", "3", "Количество использований ztele за раунд");
	Convar_RespawnTime = CreateConVar("ze_respawn_time", "7", "Время до возрождения после смерти");
	//Convar_JumpHeight = CreateConVar("ze_jump_height", "1.1", "Высота прыжка");
	
	// Дублирование для поддержки настроек карт
	Convar_ZR_InfectTime = CreateConVar("zr_infect_spawntime_min", "20", "(ZR Map Support) Время до появления первых зомби");
	Convar_ZR_ZombieRatio = CreateConVar("zr_infect_mzombie_ratio", "7", "(ZR Map Support) Соотношение зомби к людям");
	
	HookConVarChange(Convar_InfectTime, OnCvarChanged);
	HookConVarChange(Convar_ZombieRatio, OnCvarChanged);
	HookConVarChange(Convar_MaxFirstZombies, OnCvarChanged);
	HookConVarChange(Convar_HumanHealth, OnCvarChanged);
	HookConVarChange(Convar_ZombieHealth, OnCvarChanged);
	HookConVarChange(Convar_GainHealth, OnCvarChanged);
	HookConVarChange(Convar_ZteleMaxUses, OnCvarChanged);
	HookConVarChange(Convar_RespawnTime, OnCvarChanged);
	//HookConVarChange(Convar_JumpHeight, OnCvarChanged);
	
	HookConVarChange(Convar_ZR_InfectTime, OnCvarChanged);
	HookConVarChange(Convar_ZR_ZombieRatio, OnCvarChanged);
}

public void OnCvarChanged(Handle cvar, const char[] oldValue, const char[] newValue)
{
	if(cvar == Convar_InfectTime) infectTime = StringToFloat(newValue);
	else if(cvar == Convar_ZombieRatio) zombieRatio = StringToInt(newValue);
	else if(cvar == Convar_MaxFirstZombies) maxFirstZombies = StringToInt(newValue);
	else if(cvar == Convar_HumanHealth) humanHealth = StringToInt(newValue);
	else if(cvar == Convar_ZombieHealth) zombieHealth = StringToInt(newValue);
	else if(cvar == Convar_GainHealth) gainHealth = StringToInt(newValue);
	else if(cvar == Convar_ZteleMaxUses) zteleMaxUses = StringToInt(newValue);
	else if(cvar == Convar_RespawnTime) respawnTime = StringToFloat(newValue);
	//else if(cvar == Convar_JumpHeight) heightMultiplier = StringToFloat(newValue);
	
	else if(cvar == Convar_ZR_InfectTime) infectTime = StringToFloat(newValue);
	else if(cvar == Convar_ZR_ZombieRatio) zombieRatio = StringToInt(newValue);
}

public void OnConfigsExecuted()
{
	infectTime = GetConVarFloat(Convar_InfectTime);
	zombieRatio = GetConVarInt(Convar_ZombieRatio);
	maxFirstZombies = GetConVarInt(Convar_MaxFirstZombies);
	humanHealth = GetConVarInt(Convar_HumanHealth);
	zombieHealth = GetConVarInt(Convar_ZombieHealth);
	gainHealth = GetConVarInt(Convar_GainHealth);
	zteleMaxUses = GetConVarInt(Convar_ZteleMaxUses);
	respawnTime = GetConVarFloat(Convar_RespawnTime);
	//heightMultiplier = GetConVarFloat(Convar_JumpHeight);
}

public void OnClientCookiesCached(client)
{
	if(IsFakeClient(client)) return;
	
	char tempChar[4];
	
	GetClientCookie(client, h_HurtVolumeCookie, tempChar, sizeof(tempChar));
	if(StrEqual(tempChar, "")) hurtVolume[client] = 0.5;
	else hurtVolume[client] = StringToFloat(tempChar);
	
	GetClientCookie(client, h_DeathVolumeCookie, tempChar, sizeof(tempChar));
	if(StrEqual(tempChar, "")) deathVolume[client] = 0.5;
	else deathVolume[client] = StringToFloat(tempChar);
	
	GetClientCookie(client, h_InfectVolumeCookie, tempChar, sizeof(tempChar));
	if(StrEqual(tempChar, "")) infectVolume[client] = 0.5;
	else infectVolume[client] = StringToFloat(tempChar);
}

public void OnMapStart()
{
	// Объявляем что зомби еще не появились.
	b_FirstZombieInfected = false;
	
	// Выключаем блокировку возрождения.
	g_bBlockRespawn = false;
	
	// Добавляем файлы в строку загрузок.
	
	//Модель зомби.
	AddFileToDownloadsTable("models/player/mapeadores/morell/ghoul/ghoulfix.dx90.vtx");
	AddFileToDownloadsTable("models/player/mapeadores/morell/ghoul/ghoulfix.mdl");
	AddFileToDownloadsTable("models/player/mapeadores/morell/ghoul/ghoulfix.phy");
	AddFileToDownloadsTable("models/player/mapeadores/morell/ghoul/ghoulfix.vvd");
	
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/ghoulfix/body.vmt");
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/ghoulfix/body.vtf");
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/ghoulfix/body_bump.vtf");
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/ghoulfix/glowing_body.vmt");
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/ghoulfix/glowing_body.vtf");
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/ghoulfix/glowing_pants.vmt");
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/ghoulfix/pants.vmt");
	AddFileToDownloadsTable("materials/models/player/mapeadores/morell/ghoulfix/pants.vtf");

	// Модель рук зомби.
	AddFileToDownloadsTable("models/player/colateam/zombie1/arms.dx90.vtx");
	AddFileToDownloadsTable("models/player/colateam/zombie1/arms.mdl");
	AddFileToDownloadsTable("models/player/colateam/zombie1/arms.vvd");
	
	AddFileToDownloadsTable("materials/models/player/colateam/zombie1/slow_body.vmt");
	AddFileToDownloadsTable("materials/models/player/colateam/zombie1/slow_body.vtf");
	AddFileToDownloadsTable("materials/models/player/colateam/zombie1/slow_body_bump.vtf");
	AddFileToDownloadsTable("materials/models/player/colateam/zombie1/slow_pants.vmt");
	AddFileToDownloadsTable("materials/models/player/colateam/zombie1/slow_pants.vtf");
	
	// Модель зомби 2
	/*AddFileToDownloadsTable("models/player/custom/hunter/hunter.dx90.vtx");
	AddFileToDownloadsTable("models/player/custom/hunter/hunter.mdl");
	AddFileToDownloadsTable("models/player/custom/hunter/hunter.phy");
	AddFileToDownloadsTable("models/player/custom/hunter/hunter.vvd");
	
	AddFileToDownloadsTable("materials/models/player/custom/hunter/hunter_01.vmt");
	AddFileToDownloadsTable("materials/models/player/custom/hunter/hunter_01.vtf");
	AddFileToDownloadsTable("materials/models/player/custom/hunter/hunter_exponent.vtf");
	AddFileToDownloadsTable("materials/models/player/custom/hunter/hunter_normal.vtf");*/
	
	// Модель зомби 3
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/walker/walkerv2.dx90.vtx");
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/walker/walkerv2.mdl");
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/walker/walkerv2.phy");
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/walker/walkerv2.vvd");
	
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_bodyv2.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_body.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_body_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_eyes.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_eyes.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_facev2.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_face.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_face_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_lightwarp.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_lowerbodyv2.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_lowerbody.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/walker/walker_lowerbody_normal.vtf");
	
	// Модель рук зомби 3
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/walker/walker_arms.dx90.vtx");
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/walker/walker_arms.mdl");
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/walker/walker_arms.vvd");
	
	// Оверлеи в конце раунда.
	AddFileToDownloadsTable("materials/overlays/zr/zg_humans_win.vmt");
	AddFileToDownloadsTable("materials/overlays/zr/zg_humans_win.vtf");
	AddFileToDownloadsTable("materials/overlays/zr/zg_zombies_win.vmt");
	AddFileToDownloadsTable("materials/overlays/zr/zg_zombies_win.vtf");
	
	// Звуки.
	AddFileToDownloadsTable("sound/zr/fz_scream1.mp3");
	AddFileToDownloadsTable("sound/zr/zombie_die1.mp3");
	AddFileToDownloadsTable("sound/zr/zombie_die2.mp3");
	AddFileToDownloadsTable("sound/zr/zombie_die3.mp3");
	AddFileToDownloadsTable("sound/zr/zombie_pain1.mp3");
	AddFileToDownloadsTable("sound/zr/zombie_pain2.mp3");
	AddFileToDownloadsTable("sound/zr/zombie_pain3.mp3");
	AddFileToDownloadsTable("sound/zr/zombie_pain4.mp3");
	AddFileToDownloadsTable("sound/zr/zombie_pain5.mp3");
	AddFileToDownloadsTable("sound/zr/zombie_pain6.mp3");
	
	// Иконки оружия.
	AddFileToDownloadsTable("materials/panorama/images/icons/equipment/infection.svg");
	
	// Прекешируем модели.
	PrecacheModel("models/player/mapeadores/morell/ghoul/ghoulfix.mdl", true);
	PrecacheModel("models/player/colateam/zombie1/arms.mdl", true);
	
	//PrecacheModel("models/player/custom/hunter/hunter.mdl", true);
	
	PrecacheModel("models/player/custom_player/kuristaja/walker/walkerv2.mdl", true);
	PrecacheModel("models/player/custom_player/kuristaja/walker/walker_arms.mdl", true);
	
	// Прекешируем звуки.
	PrecacheSound("zr/fz_scream1.mp3");
	PrecacheSound("zr/zombie_die1.mp3");
	PrecacheSound("zr/zombie_die2.mp3");
	PrecacheSound("zr/zombie_die3.mp3");
	PrecacheSound("zr/zombie_pain1.mp3");
	PrecacheSound("zr/zombie_pain2.mp3");
	PrecacheSound("zr/zombie_pain3.mp3");
	PrecacheSound("zr/zombie_pain4.mp3");
	PrecacheSound("zr/zombie_pain5.mp3");
	PrecacheSound("zr/zombie_pain6.mp3");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		g_bDoubleInfectProtect[i] = false;
		g_b_TempDoubleInfectProtect[i] = false;
	}
}

public void OnMapEnd()
{
	// Завершаем таймер заражения.
	SZE_EndTimer(tFirstInfect);
	tFirstInfect = INVALID_HANDLE;
	
	// Завершаем таймер отсчёта до заражения.
	SZE_EndTimer(tInfectCountdown);
	tInfectCountdown = INVALID_HANDLE;
	
	// Сбрасываем данные таблицы очков всем игрокам.
	for(int i = 1; i <= MaxClients; i++)
	{
		iKills[i] = 0;
		iAssists[i] = 0;
		iDeaths[i] = 0;
		iMVP[i] = 0;
		iScore[i] = 0;
	}
}

public void OnClientPutInServer(int client)
{
	// Отлавливаем подбор оружия игроком.
	SDKHook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
	
	// Отлавливаем получение урона игроком.
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	
	// Обнуляем данные таблицы очков индексу подключившегося игрока.
	iKills[client] = 0;
	iAssists[client] = 0;
	iDeaths[client] = 0;
	iMVP[client] = 0;
	iScore[client] = 0;
}

public void OnClientDisconnect(int client)
{
	// Если игрок не на сервере (вышел не подключившись), выходим.
	if(!IsClientInGame(client)) return;
	
	// Обнуляем счетчик телепортов и количество секунд до телепортации.
	zteleAmount[client] = 0;
	zteleCounter[client] = 0;
	
	// Обнуляем время смерти игрока.
	g_fDeathTime[client] = 0.0;
	
	// Сбрасываем переменную, которая хранит информацию о последнем заражении игрока (для защиты от повторного заражения).
	g_bDoubleInfectProtect[client] = false;
	g_b_TempDoubleInfectProtect[client] = false;
	
	// Если первые зомби есть
	if(b_FirstZombieInfected)
	{
		// Берём номер команды игрока.
		int clientTeam = GetClientTeam(client);

		// Если игроков в команде вышедшего игрока меньше двух (только он 1)
		if(GetTeamClientCount(clientTeam) < 2)
		{
			// Если игрок вышел из команды зомби
			if(clientTeam == CS_TEAM_T)
			{
				// Заражаем случайного игрока.
				int newZombie = SZE_InfectRandomPlayer();
				
				// Пишем игроку уведомление о том, что он заражён, так как отключился единственный зомби.
				if(newZombie != -1) PrintToChat(newZombie, "%t", "RandomInfectOnDisconnect");
			}
			// Если же игрок вышел из команды людей, завершаем раунд, так как людей больше нет.
			else if(clientTeam == CS_TEAM_CT) CS_TerminateRound(GetConVarFloat(roundRestartDelay), CSRoundEnd_TerroristWin);
		}
	}
}

public Action Event_PlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
	// Обнуляем данные таблицы очков индексу вышедшего игрока.
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	iKills[client] = 0;
	iAssists[client] = 0;
	iDeaths[client] = 0;
	iMVP[client] = 0;
	iScore[client] = 0;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	// Когда граната запущена, убираем ей коллизию.
	if(StrContains(classname, "_projectile", false) != -1) SetEntProp(entity, Prop_Data, "m_CollisionGroup", 2);
}

public Action Command_MoveToHumans(int client, int args)
{
	// Если аргументов нет, оповещаем и выходим.
	if(args < 1)
	{
		ReplyToCommand(client, "Используйте: sm_movetohumans <ник>");
		return Plugin_Handled;
	}

	// Получаем аргумент команды (часть ника или полный ник).
	char nickName[64];
	GetCmdArgString(nickName, sizeof(nickName));

	// Находим ник игрока.
	int target = FindTarget(client, nickName);
	
	// Если цель уже человек, сообщаем и выходим.
	if(GetClientTeam(target) == CS_TEAM_CT)
	{
		PrintToChat(client, "%t", "AlreadyHuman", target);
		return Plugin_Handled;
	}
	
	// Переносим игрока к людям.
	SZE_MoveToHumans(target);
	
	// Пишем администратору об успешном перемещении.
	PrintToChat(client, "%t", "SuccessfullyMovedToHumans", target);
	
	// Если игроков в команде зомби больше нет
	if(GetTeamClientCount(CS_TEAM_T) == 0)
	{
		// Завершаем раунд, так как зомби больше нет.
		CS_TerminateRound(GetConVarFloat(roundRestartDelay), CSRoundEnd_CTWin);
		
		int teamscore = GetTeamScore(CS_TEAM_CT) + 1;
		SetTeamScore(CS_TEAM_CT, teamscore);
		CS_SetTeamScore(CS_TEAM_CT, teamscore);
	}
	
	// Завершаем выполнение команды.
	return Plugin_Handled;
}

public Action Command_MoveToZombies(int client, int args)
{
	// Если аргументов нет, оповещаем и выходим.
	if(args < 1)
	{
		ReplyToCommand(client, "Используйте: sm_movetozombies <ник>");
		return Plugin_Handled;
	}
	
	// Получаем аргумент команды (часть ника или полный ник).
	char nickName[64];
	GetCmdArgString(nickName, sizeof(nickName));
	
	// Находим ник игрока.
	int target = FindTarget(client, nickName);
	
	// Если цель уже зомби, сообщаем и выходим.
	if(GetClientTeam(target) == CS_TEAM_T)
	{
		PrintToChat(client, "%t", "AlreadyZombie", target);
		return Plugin_Handled;
	}
	
	// Заражаем игрока.
	SZE_InfectPlayer(target);
	
	// Если зомби еще не появились
	if(!b_FirstZombieInfected)
	{
		// Завершаем таймер заражения.
		SZE_EndTimer(tFirstInfect);
		tFirstInfect = INVALID_HANDLE;
		
		// Завершаем таймер отсчёта до заражения.
		SZE_EndTimer(tInfectCountdown);
		tInfectCountdown = INVALID_HANDLE;
		
		// Объявляем что зомби появились.
		b_FirstZombieInfected = true;
		
		// Пишем всем игрокам в центре экрана, что заражение началось.
		PrintHintTextToAll("%t", "InfectionStarted");
	}
	
	// Пишем администратору об успешном перемещении.
	PrintToChat(client, "%t", "SuccessfullyMovedToZombies", target);
	
	// Если игроков в команде людей больше нет
	if(GetTeamClientCount(CS_TEAM_CT) == 0)
	{
		// Завершаем раунд, так как людей больше нет.
		CS_TerminateRound(GetConVarFloat(roundRestartDelay), CSRoundEnd_TerroristWin);
	}
	
	// Завершаем выполнение команды.
	return Plugin_Handled;
}

public Action BlockCommand(int client, const char[] command, argc)
{
	// Блокируем выполнение команды.
	return Plugin_Handled;
}

public Action OnJoinTeam(int client, const char[] command, argc)
{
	// Берём текущую команду игрока.
	int team = GetClientTeam(client);
	
	// Если игрок еще не присоединился к команде или наблюдатель
	if(team == CS_TEAM_NONE || team == CS_TEAM_SPECTATOR)
	{
		// Получаем номер команды, к которой хочет присоединиться игрок.
		char arg[2] = "";
		GetCmdArg(1, arg, sizeof(arg));

		// Переводим номер из строки в число.
		int selectedTeam = StringToInt(arg);
		
		// Если это первый подключившийся игрок, разрешаем стандартную смену для того чтобы игра началась правильно.
		if(GetTeamClientCount(CS_TEAM_T) == 0 && GetTeamClientCount(CS_TEAM_CT) == 0) return Plugin_Continue;
		
		// Если игрок выбрал команду зомби, людей или случайный выбор
		if(selectedTeam == CS_TEAM_T || selectedTeam == CS_TEAM_CT || selectedTeam == CS_TEAM_NONE)
		{
			// Меняем выбранную команду на команду людей (чтобы раунд не завершился), возрождаем игрока и блокируем стандартную смену команды.
			CS_SwitchTeam(client, CS_TEAM_CT);
			CreateTimer(1.0, RespawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Handled;
		}
		
		// Если игрок выбрал команду наблюдателей, разрешаем стандартную смену команды.
		return Plugin_Continue;
	}
	
	// Если игрок пытается сменить команду, находясь в команде людей или зомби, включим ему звук "нет доступа" и запрещаем смену.
	ClientCommand(client, "playgamesound buttons/button11.wav");
	return Plugin_Handled;
}

public Action Hook_WeaponCanUse(int client, int weapon)
{
	// Если игрок - зомби
	if(GetClientTeam(client) == CS_TEAM_T)
	{
		// Получаем тип оружия.
		char classname[32] = "";
		GetEntityClassname(weapon, classname, sizeof(classname));
		
		// Если оружие - нож, разрешаем подобрать.
		if(StrContains(classname, "knife") != -1) return Plugin_Continue;
		
		// Запрещаем подбирать любое другое оружие.
		else return Plugin_Handled;
	}
	
	// Если игрок - человек, разрешаем подобрать оружие.
	else return Plugin_Continue;
}

public Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// Если игрок горит
	if(damagetype == 268435464)
	{
		// Проверяем в воде ли игрок ( 0 - сухой, 1 - по пятку, 2 - по пояс, 3 - полностью в воде)
		int waterLevel = GetEntData(victim, g_WaterLevel);
	
		// Если игрок в воде (по пояс)
		if(waterLevel > 1)
		{
			// Получаем index эффекта на игроке.
			int fire = GetEntPropEnt(victim, Prop_Data, "m_hEffectEntity");
			
			// Если эффект есть, тушим игрока.
			if(IsValidEdict(fire)) SetEntPropFloat(fire, Prop_Data, "m_flLifetime", 0.0);
		}
		
		// Пусть горит дальше, выходим для оптимизации.
		return Plugin_Continue;
	}

	// Если урон нанёс не игрок, выходим.
	if(attacker < 1 || attacker > MaxClients) return Plugin_Continue;
	
	// Блокируем людям урон от гранат.
	if(GetClientTeam(victim) == CS_TEAM_CT)
	{
		if(damagetype == DMG_BURN || damagetype == DMG_BLAST) return Plugin_Handled;
	}
	
	// Получаем класс оружия игрока.
	char weapon[32] = "";
	GetClientWeapon(attacker, weapon, sizeof(weapon));

	// Если атакующий - зомби, жертва - человек, а оружие - нож (или штык-нож), меняем урон на минимально возможный для заражения.
	if(GetClientTeam(attacker) == CS_TEAM_T && GetClientTeam(victim) == CS_TEAM_CT && StrContains(weapon, "knife") != -1 || StrContains(weapon, "bayonet") != -1) 
	{
		damage = 2.0;
		
		// Возвращаем изменённый урон.
		return Plugin_Changed;
	}
	
	return Plugin_Continue; 
}

public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	// Получаем index команды, из которой игрок перешел в новую.
	int oldTeam = GetEventInt(event, "oldteam");
	
	// Если игрок был в команде людей или зомби:
	if(oldTeam == CS_TEAM_CT || oldTeam == CS_TEAM_T)
	{
		// Получаем index игрока из его UserID.
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
		// Берём список эффектов игрока.
		int fEffects = GetEntProp(client, Prop_Send, "m_fEffects");
		
		// Если среди эффектов есть фонарик, выключаем его.
		if(fEffects & 4) SetEntProp(client, Prop_Send, "m_fEffects", fEffects ^ 4);
	}
}
/*
public Action Event_PlayerJump(Handle event, const char[] name, bool dontBroadcast)
{
	// Выходим если множитель высоты стандартный.
	if(heightMultiplier == 1.0) return;
	
	// Получаем index игрока из его UserID.
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Продолжаем выполнение функции после прыжка.
	CreateTimer(0.0, Timer_PlayerJumpPost, client);
}

public Action Timer_PlayerJumpPost(Handle timer, any client)
{
	// Если игрок не на сервере или не живой, выходим.
	if(!IsClientInGame(client) || !IsPlayerAlive(client)) return;

	// Получаем скорость игрока.
	float vecClientVelocity[3];
	
	for(new x = 0; x < 3; x++) vecClientVelocity[x] = GetEntDataFloat(client, g_vecVelocity + (x*4));
	
	// Изменяем высоту прыжка.
	vecClientVelocity[2] *= heightMultiplier;
	
	// Подкидываем игрока.
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecClientVelocity);
}
*/
public Action Event_WeaponFire(Handle event, const char[] name, bool dontBroadcast)
{
	// Получаем название оружия.
	char weaponName[32] = "";
	GetEventString(event, "weapon", weaponName, sizeof(weaponName));
	
	// Если оружие - нож или граната, выходим.
	if(StrContains(weaponName, "knife") != -1
	|| StrContains(weaponName, "bayonet") != -1
	|| StrContains(weaponName, "grenade") != -1
	|| StrContains(weaponName, "molotov") != -1) return;
	
	// Получаем index игрока из его UserID.
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Получаем index оружия, с которого выстрелил игрок.
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	// Получаем текущее количество патронов в обойме оружия.
	int clipCount = GetEntProp(weapon, Prop_Send, "m_iClip1");
	
	// Если в обойме 0 патронов, выходим.
	if(clipCount == 0) return;
	
	// Получаем максимальное количество патронов в обойме оружия.
	int maxClipAmmo = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoCount");
	
	// Если максимальное количество патронов в обойме не установлено (при первом выстреле)
	if(maxClipAmmo == 0)
	{
		// Записываем в максимальное количество патронов в обойме текущее количество.
		SetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoCount", clipCount);
		
		// Обновляем значение в переменной.
		maxClipAmmo = clipCount;
	}
	
	// Количество пуль, вычитаемое при выстреле.
	int bulletPerShot = 1;
	
	// Если у оружия включен режим стрельбы очередями
	if(GetEntProp(weapon, Prop_Send, "m_bBurstMode") == 1)
	{
		// Если в обойме осталось 2 пули,  меняем количество пуль, вычитаемое при выстреле на 2.
		if(clipCount == 2) bulletPerShot = 2;
		
		// Или если в обойме осталось больше двух пуль, меняем количество пуль, вычитаемое при выстреле на 3.
		else if (clipCount > 2) bulletPerShot = 3;
	}
	
	// Устанавливаем количество патронов в запасе оружия: (максимальное - (текущее - вычитаемое)). Вычитаемое нужно так как пуля всё ещё находится в обойме.
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", maxClipAmmo - (clipCount - bulletPerShot));
}

public Action Event_RoundPreStart(Handle event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		// Обнуляем счетчик телепортов.
		zteleAmount[i] = 0;
		
		// Выходим, если игрок не на сервере.
		if(!IsClientInGame(i)) continue;
		
		// Сбрасываем игроку путь до модели рук.
		SetEntPropString(i, Prop_Send, "m_szArmsModel", "");
		
		// Сохраняем данные таблицы очков у всех игроков.
		iKills[i] = GetEntProp(i, Prop_Data, "m_iFrags");
		iAssists[i] = CS_GetClientAssists(i);
		iDeaths[i] = GetEntProp(i, Prop_Data, "m_iDeaths");
		iMVP[i] = CS_GetMVPCount(i);
		iScore[i] = CS_GetClientContributionScore(i);
	}
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	// Завершаем таймер заражения.
	SZE_EndTimer(tFirstInfect);
	tFirstInfect = INVALID_HANDLE;
	
	// Завершаем таймер отсчёта до заражения.
	SZE_EndTimer(tInfectCountdown);
	tInfectCountdown = INVALID_HANDLE;
	
	// Объявляем что зомби еще не появились.
	b_FirstZombieInfected = false;
	
	// Убираем оверлей всем игрокам.
	SZE_ShowOverlayToAll("");
	
	// Выключаем блокировку возрождения.
	g_bBlockRespawn = false;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		// Выходим, если игрок не на сервере.
		if(!IsClientInGame(i)) continue;
		
		// Восстанавливаем данные таблицы очков всем игрокам.
		SetEntProp(i, Prop_Data, "m_iFrags", iKills[i]);
		CS_SetClientAssists(i, iAssists[i]);
		SetEntProp(i, Prop_Data, "m_iDeaths", iDeaths[i]);
		CS_SetMVPCount(i, iMVP[i]);
		CS_SetClientContributionScore(i, iScore[i]);
	}
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	// Завершаем таймер заражения.
	SZE_EndTimer(tFirstInfect);
	tFirstInfect = INVALID_HANDLE;
	
	// Завершаем таймер отсчёта до заражения.
	SZE_EndTimer(tInfectCountdown);
	tInfectCountdown = INVALID_HANDLE;
	
	// Убираем урон и заражение в конце раунда (только от оружия).
	for(int i = 1; i <= MaxClients; i++)
	{
		// Если игрок на сервере и живой, изменяем тип получаемого урона на 3 (не получать от оружия).
		if(IsClientInGame(i) && IsPlayerAlive(i)) SetEntProp(i, Prop_Data, "m_takedamage", 3);
	}
	
	// Определяем победившую команду.
	int winnerTeam = GetEventInt(event, "winner");
	
	// Показываем всем игрокам оверлей победившей команды.
	if(winnerTeam == CS_TEAM_CT) SZE_ShowOverlayToAll("overlays/zr/zg_humans_win");
	else if(winnerTeam == CS_TEAM_T)
	{
		int teamscore = GetTeamScore(CS_TEAM_T) + 1;
		SetTeamScore(CS_TEAM_T, teamscore);
		CS_SetTeamScore(CS_TEAM_T, teamscore);
	
		SZE_ShowOverlayToAll("overlays/zr/zg_zombies_win");
	}
}

public Action Event_RoundFreezeEnd(Handle event, const char[] name, bool dontBroadcast)
{
	// Если игроков нет, не начинаем отсчет до заражения и выходим.
	if(GetTeamClientCount(CS_TEAM_CT) < 1 && GetTeamClientCount(CS_TEAM_T) < 1) return;
	
	// Если зомби уже есть, выходим (такое бывает если заразить через админ меню).
	if(b_FirstZombieInfected) return;

	// Обнуляем значение таймера отсчёта до заражения.
	infectCountdownCounter = 0;
	
	// Создаём таймер до первого заражения и таймер отсчёта до заражения.
	tFirstInfect = CreateTimer(infectTime, FirstInfect);
	tInfectCountdown = CreateTimer(1.0, InfectCountdown, _, TIMER_REPEAT);
	
	// Выполним действие таймера отсчёта до заражения сразу, чтобы учитывалась первая секунда.
	InfectCountdown(tInfectCountdown);
	
	// Включаем общий чат всех со всеми (каждый раунд отключается).
	SetConVarInt(fullAllTalk, 1);
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	// Получаем index игрока из его UserID.
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	// Сохраняем координаты точки возрождения.
	GetClientAbsOrigin(client, g_vecSpawn[client]);
	
	// Убираем игроку коллизию.
	SetEntProp(client, Prop_Data, "m_CollisionGroup", 2);
	
	// Устанавливаем игроку здоровье.
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1) SetEntityHealth(client, vipHumanHealth);
	else SetEntityHealth(client, humanHealth);
	
	// Продолжаем выполнение функции через 1/10 секунды (для оптимизации и правильной работы).
	CreateTimer(0.1, Timer_PlayerSpawnPost, client);
}

public Action Timer_PlayerSpawnPost(Handle timer, any client)
{
	// Если игрок не на сервере или не живой, выходим.
	if(!IsClientInGame(client) || !IsPlayerAlive(client)) return;
	
	// Устанавливаем VIP игроку максимальное количество денег.
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1) SetEntProp(client, Prop_Send, "m_iAccount", 16000);
	
	// Если игрок в команде зомби, но первых зомби ещё нет, перемещаем его к людям.
	if(GetClientTeam(client) == CS_TEAM_T && !b_FirstZombieInfected) CS_SwitchTeam(client, CS_TEAM_CT);
	
	// Восстанавливаем звездочки MVP.
	CS_SetMVPCount(client, iMVP[client]);
}

public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	// Получаем index атакующего и жертвы.
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Если жертва - зомби
	if(GetClientTeam(victim) == CS_TEAM_T)
	{
		// Делаем шанс появления звука 1 к 20 (5%).
		if(GetRandomInt(1, 20) == 1)
		{
			// Выбираем случайный звук получения урона.
			char sound[32] = "";
			Format(sound, 32, "zr/zombie_pain%i.mp3", GetRandomInt(1, 6));
		
			// Воспроизводим звук получения урона.
			SZE_EmitSoundToAll(sound, victim, 1)
		}
	}
	
	// Если урон нанёс не игрок, выходим (0 возвращается если userid атакующего не найден).
	if(attacker == 0) return;
	
	// Если игрок нанёс урон сам себе, выходим.
	if(victim == attacker) return;
	
	// Если атакующий не зомби
	if(GetClientTeam(attacker) != CS_TEAM_T)
	{
		// Берём количество здоровья, оставшееся у жертвы.
		int health = GetEventInt(event, "health")
		
		// Если у жертвы больше 0 здоровья
		if(health > 0)
		{
			// Берем нанесенный жертве урон.
			int damage = GetEventInt(event, "dmg_health");
			
			// Показываем атакующему, кому и сколько урона он нанес.
			PrintHintText(attacker, "%t", "HurtPlayer", victim, health, damage);
		}
		// Иначе пишем атакующему, кого он убил.
		else PrintHintText(attacker, "%t", "KilledPlayer", victim);
		
		// Выходим, так как код ниже предназначен для заражения игрока.
		return;
	}
	
	// Получаем название оружия.
	char weaponName[32] = "";
	GetEventString(event, "weapon", weaponName, sizeof(weaponName));
	
	// Если оружие - не нож и не штык-нож, выходим.
	if(StrContains(weaponName, "knife") == -1 && StrContains(weaponName, "bayonet") == -1) return;
	
	// Заражаем жертву.
	SZE_InfectPlayer(victim);
	
	// Добавляем заражённому + 1 смерть.
	SetEntProp(victim, Prop_Data, "m_iDeaths", GetEntProp(victim, Prop_Data, "m_iDeaths") + 1);
	
	// Добавляем заразившему + 1 убийство.
	SetEntProp(attacker, Prop_Data, "m_iFrags", GetEntProp(attacker, Prop_Data, "m_iFrags") + 1);
	
	// Добавляем заразившему очки (стандартно + 2 за убийство).
	CS_SetClientContributionScore(attacker, CS_GetClientContributionScore(attacker) + 2);
	
	// Добавляем заразившему ХП за заражение.
	SetEntityHealth(attacker, GetEntProp(attacker, Prop_Send, "m_iHealth") + gainHealth); 
	
	// Создаем фейковый ивент для отображения заражения.
	Handle fakeEvent = CreateEvent("player_death");
	
	SetEventInt(fakeEvent, "userid", GetClientUserId(victim));
	SetEventInt(fakeEvent, "attacker", GetClientUserId(attacker));
	SetEventString(fakeEvent, "weapon", "infection");
	FireEvent(fakeEvent);
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	// Получаем index игрока из его UserID.
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Если игрок не живой (для исключения ложных срабатываний)
	if(!IsPlayerAlive(client))
	{
		// Если умерший - зомби
		if(GetClientTeam(client) == CS_TEAM_T)
		{
			// Выбираем случайный звук смерти.
			char sound[32] = "";
			Format(sound, 32, "zr/zombie_die%i.mp3", GetRandomInt(1, 3));
		
			// Воспроизводим звук смерти.
			SZE_EmitSoundToAll(sound, client, 2)
		}
		
		// Если возрождение не отключено
		if(!g_bBlockRespawn)
		{
			// Создаем таймер для возрождения.
			CreateTimer(respawnTime, RespawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
			
			// Получаем название оружия, с которого убит игрок.
			char weapon[32] = "";
			GetEventString(event, "weapon", weapon, sizeof(weapon));
			
			// Если игрока убило триггером
			if(StrEqual(weapon, "trigger_hurt"))
			{
				// Берем текущее время.
				float fGameTime = GetGameTime();
				
				// Если текущее время - время смерти игрока - время возрождения меньше 5 секунд
				if(fGameTime - g_fDeathTime[client] - respawnTime < 5.0)
				{
					// Оповещаем всех.
					PrintToChatAll("%t", "RepeatKillsDetected");
					
					// Блокируем возрождение.
					g_bBlockRespawn = true;
				}
				// Устанавливаем время смерти игрока.
				g_fDeathTime[client] = fGameTime;
			}
		}
	}
	
	// Если живых людей не осталось, завершаем раунд.
	if(SZE_AllHumansInfected()) CS_TerminateRound(GetConVarFloat(roundRestartDelay), CSRoundEnd_TerroristWin);
}

public Action RespawnPlayer(Handle timer, any client)
{
	// Если игрок на сервере, не живой, не наблюдатель и возрождение не отключено
	if(IsClientInGame(client) && !IsPlayerAlive(client) && GetClientTeam(client) > 1 && !g_bBlockRespawn)
	{
		// Возрождаем игрока.
		CS_RespawnPlayer(client);
		
		// Если первые зомби уже появились, заражаем игрока.
		if(b_FirstZombieInfected) SZE_InfectPlayer(client);
	}
	
	// Если живых людей не осталось, завершаем раунд (чтобы когда на сервер заходит второй игрок, раунд завершался).
	if(SZE_AllHumansInfected()) CS_TerminateRound(GetConVarFloat(roundRestartDelay), CSRoundEnd_TerroristWin);
}

public Action FirstInfect(Handle timer)
{
	// Закрываем таймер.
	tFirstInfect = INVALID_HANDLE;
	
	// Останавливаем и закрываем таймер отсчёта до заражения (так как он повторяющийся).
	SZE_EndTimer(tInfectCountdown);
	tInfectCountdown = INVALID_HANDLE;
	
	// Получаем количество подходящих для заражения игроков.
	int eligiblePlayers = SZE_GetEligiblePlayers();
	
	// Рассчитываем количество первых зомби (живые игроки / кол-во зомби на людей).
	int firstZombiesCount = (eligiblePlayers / zombieRatio);
	
	// Если количество игроков меньше нужного для заражения
	if(firstZombiesCount < 1)
	{
		// Если на сервере есть игроки, которых можно заразить, изменяем количество первых зомби на 1.
		if(eligiblePlayers > 0) firstZombiesCount = 1;
		
		// Иначе выходим, так как на сервере нет игроков и некого заражать.
		else return;
	}
	// Если же количество игроков больше максимального, установить на максимальное.
	else if(firstZombiesCount > maxFirstZombies) firstZombiesCount = maxFirstZombies;
	
	for(int i = 1; i <= firstZombiesCount; i++)
	{
		// Заражаем случайного игрока.
		int victim = SZE_InfectRandomPlayer(true);
		
		// Телепортируем в точку возрождения.
		if(victim != -1) TeleportEntity(victim, g_vecSpawn[victim], NULL_VECTOR, Float:{0.0, 0.0, 0.0});
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			g_bDoubleInfectProtect[i] = false;
		
			if(g_b_TempDoubleInfectProtect[i])
			{
				g_bDoubleInfectProtect[i] = true;
				g_b_TempDoubleInfectProtect[i] = false;
			}
		}
	}
	
	// Объявляем что первые зомби появились.
	b_FirstZombieInfected = true;
	
	// Пишем всем игрокам в центре экрана, что заражение началось.
	PrintHintTextToAll("%t", "InfectionStarted");
}

public Action InfectCountdown(Handle timer)
{
	// Пишем всем игрокам в центре экрана, сколько секунд осталось до заражения (время до заражения - количество секунд после начала игры).
	PrintHintTextToAll("%t", "FirstInfectionCountdown", RoundToZero(infectTime) - infectCountdownCounter);

	// Добавляем к счётчику секунд до заражения +1.
	infectCountdownCounter++;
}

public Action Command_LookAtWeapon(int client, const char[] command, argc)
{
	// Если игрок не в игре, выходим.
	if(!IsClientInGame(client)) return;
	
	// Получаем команду игрока.
	int clientTeam = GetClientTeam(client);
	
	// Если игрок - человек или зомби:
	if(clientTeam == CS_TEAM_CT || clientTeam == CS_TEAM_T)
	{
		// Переключаем состояние фонарика (вкл/выкл).
		SetEntProp(client, Prop_Send, "m_fEffects", GetEntProp(client, Prop_Send, "m_fEffects") ^ 4);
		
		// Проигрываем игроку звук фонарика.
		ClientCommand(client, "playgamesound items/flashlight1.wav");
	}
}

public Action Command_Ztele(int client, int args)
{
	// Если клиент не в игре, выходим.
	if(!IsClientInGame(client)) return Plugin_Handled;
	
	// Если игрок уже ожидает телепортации, выходим.
	if(tZtele[client] != INVALID_HANDLE) return Plugin_Handled;
	
	// Или если игрок уже телепортировался макисмальное количество раз, предупреждаем и выходим.
	else if(zteleAmount[client] == zteleMaxUses)
	{
		PrintHintText(client, "%t", "ZteleLimitExceed", zteleAmount[client], zteleMaxUses);
		return Plugin_Handled;
	}
	
	// Берём координаты игрока.
	GetClientAbsOrigin(client, startZteleCoordinates[client]);
	
	// Создаём таймер телепортации.
	tZtele[client] = CreateTimer(1.0, Timer_Ztele, client, TIMER_REPEAT);
	
	// Выполним действие таймера телепортации сразу, чтобы учитывалась первая секунда.
	Timer_Ztele(tZtele[client], client);
	
	// Завершаем выполнение команды.
	return Plugin_Handled;
}

public Action Timer_Ztele(Handle timer, any client)
{
	// Если игрок не в игре
	if(!IsClientInGame(client))
	{
		// Останавливаем и закрываем таймер телепортации.
		SZE_EndTimer(tZtele[client]);
		tZtele[client] = INVALID_HANDLE;
		
		// Выходим.
		return;
	}
	
	// Берём координаты игрока.
	float afkCoordinates[3];
	GetClientAbsOrigin(client, afkCoordinates);
	
	// Рассчитываем расстояние между старыми и новыми координатами игрока.
	float distance = GetVectorDistance(afkCoordinates, startZteleCoordinates[client]);

	if(distance > 100.0)
	{
		// Останавливаем и закрываем таймер телепортации.
		SZE_EndTimer(tZtele[client]);
		tZtele[client] = INVALID_HANDLE;
		
		// Сбрасываем количество секунд до телепортации.
		zteleCounter[client] = 0;
		
		// Пишем игроку об отмене телепортации.
		PrintHintText(client, "%t", "ZteleCalceled");
		return;
	}
	
	// Пишем игроку сколько секунд осталось до телепортации.
	PrintHintText(client, "%t", "TeleportingToSpawn", 3 - zteleCounter[client]);
	
	// Добавляем +1 секунду в счётчик прошедших секунд.
	zteleCounter[client]++;
	
	// Если прошло 3 секунды (4 потому что мы вызвали таймер когда игрок ввел зтеле), выполняем телепортацию:
	if(zteleCounter[client] == 4)
	{
		// Останавливаем и закрываем таймер телепортации.
		SZE_EndTimer(tZtele[client]);
		tZtele[client] = INVALID_HANDLE;
		
		// Сбрасываем количество секунд до телепортации.
		zteleCounter[client] = 0;
		
		// Телепортируем игрока в точку возрождения.
		TeleportEntity(client, g_vecSpawn[client], NULL_VECTOR, Float:{0.0, 0.0, 0.0});
		
		// Добавляем +1 к количеству телепортов игрока.
		zteleAmount[client]++;
		
		// Пишем игроку уведомление об успешной телепортации.
		PrintHintText(client, "%t", "TeleportedToSpawn", zteleAmount[client], zteleMaxUses);
	}
}

public Action Command_Zvolume(int client, int args)
{
	ShowZvolumeMenu(client);
	return Plugin_Handled;
}

ShowZvolumeMenu(int client)
{
	SetGlobalTransTarget(client);
	
	char hurtVol[4], deathVol[4], infectVol[4], hurtVolPercent[8], deathVolPercent[8], infectVolPercent[8];
	FloatToString(hurtVolume[client], hurtVol, sizeof(hurtVol));
	FloatToString(deathVolume[client], deathVol, sizeof(deathVol));
	FloatToString(infectVolume[client], infectVol, sizeof(infectVol));
	
	Format(hurtVolPercent, sizeof(hurtVolPercent), "%i%", RoundToZero(hurtVolume[client] * 100));
	Format(deathVolPercent, sizeof(deathVolPercent), "%i%", RoundToZero(deathVolume[client] * 100));
	Format(infectVolPercent, sizeof(infectVolPercent), "%i%", RoundToZero(infectVolume[client] * 100));
	
	char hurtTranslate[96], deathTranslate[96], infectTranslate[96];
	Format(hurtTranslate, sizeof(hurtTranslate), "%t", "Hurt_Volume", hurtVolPercent);
	Format(deathTranslate, sizeof(deathTranslate), "%t", "Death_Volume", deathVolPercent);
	Format(infectTranslate, sizeof(infectTranslate), "%t", "Infect_Volume", infectVolPercent);
	
	Menu zvolume = new Menu(ZVolumeHandler);
	
	zvolume.SetTitle("%T", "ZVolume_Menu_Title", client);
	zvolume.AddItem(hurtVol, hurtTranslate);
	zvolume.AddItem(deathVol, deathTranslate);
	zvolume.AddItem(infectVol, infectTranslate);
	zvolume.Display(client, 180);
}

public ZVolumeHandler(Menu zvolume, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select) 
	{
		char item[4];
		zvolume.GetItem(option, item, sizeof(item));
		
		float newVolume = StringToFloat(item);
		
		if(newVolume <= 0.0) newVolume = 1.0;
		else if(newVolume > 0.2) newVolume -= 0.2;
		else if(newVolume <= 0.2) newVolume -= 0.1;

		if(option == 0) hurtVolume[client] = newVolume;
		else if(option == 1) deathVolume[client] = newVolume;
		else if(option == 2) infectVolume[client] = newVolume;
		
		ShowZvolumeMenu(client);
	}
	else if(action == MenuAction_Cancel) 
	{
		if(AreClientCookiesCached(client))
		{
			char tempChar[4];
			
			FloatToString(hurtVolume[client], tempChar, sizeof(tempChar));
			SetClientCookie(client, h_HurtVolumeCookie, tempChar);
			
			FloatToString(deathVolume[client], tempChar, sizeof(tempChar));
			SetClientCookie(client, h_DeathVolumeCookie, tempChar);
			
			FloatToString(infectVolume[client], tempChar, sizeof(tempChar));
			SetClientCookie(client, h_InfectVolumeCookie, tempChar);
		}
	}
	else if(action == MenuAction_End) delete zvolume;
}

