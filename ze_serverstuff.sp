#include <sdktools>
#include <sdkhooks>

// Список кваров, которым будет отключена синхронизация с клиентом.
char ConVars_RemoveReplicated[][] = {"sv_staminajumpcost", "sv_staminalandcost", "sv_staminamax", "sv_staminarecoveryrate"};

// Список кваров, которым будет отключено уведомление об изменении.
char ConVars_RemoveNotify[][] = {"mp_timelimit"};

bool bCriticalState;
bool bShowEntityCounter[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "Server Sequrity & Performance",
	author = "Walderr",
	description = "Безопасность, производительность и расширенные параметры сервера",
	version = "1.1.1",
	url = "http://www.jaze.ru/"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	
	CreateTimer(1.0, Timer_EntityCounter, _, TIMER_REPEAT);
	
	ChangeConVarsFlags();
}

public void OnMapStart()
{
	char map[128];
	GetCurrentMap(map, sizeof(map));
	
	if(StrEqual(map, "ze_lotr_minas_tirith_p5"))
	{
		// Добавляем изменённую модель в строку загрузок.
		AddFileToDownloadsTable("models/player/custom_player/legacy/gondorknight_jaze/gondorknight_jaze.dx90.vtx");
		AddFileToDownloadsTable("models/player/custom_player/legacy/gondorknight_jaze/gondorknight_jaze.mdl");
		AddFileToDownloadsTable("models/player/custom_player/legacy/gondorknight_jaze/gondorknight_jaze.phy");
		AddFileToDownloadsTable("models/player/custom_player/legacy/gondorknight_jaze/gondorknight_jaze.vvd");
		
		// Прекешируем модель.
		PrecacheModel("models/player/custom_player/legacy/gondorknight_jaze/gondorknight_jaze.mdl");
	}
	else if(StrEqual(map, "ze_minecraft_adventure_v1_3d"))
	{
		// Добавляем изменённую модель в строку загрузок.
		AddFileToDownloadsTable("models/player/custom/mine_jaze/mine_jaze.dx90.vtx");
		AddFileToDownloadsTable("models/player/custom/mine_jaze/mine_jaze.mdl");
		AddFileToDownloadsTable("models/player/custom/mine_jaze/mine_jaze.phy");
		AddFileToDownloadsTable("models/player/custom/mine_jaze/mine_jaze.vvd");
		
		// Прекешируем модель.
		PrecacheModel("models/player/custom/mine_jaze/mine_jaze.mdl");
	}
	else if(StrEqual(map, "ze_FFVII_Mako_Reactor_v5_3_v5"))
	{
		// Добавляем новую музыку в строку загрузок.
		AddFileToDownloadsTable("sound/zombieden/custommusic/advent2.mp3");
		AddFileToDownloadsTable("sound/zombieden/custommusic/m2fix.mp3");
		AddFileToDownloadsTable("sound/zombieden/custommusic/m3fix.mp3");
		AddFileToDownloadsTable("sound/zombieden/custommusic/m4fix.mp3");
		AddFileToDownloadsTable("sound/zombieden/custommusic/m5fix.mp3");
		AddFileToDownloadsTable("sound/zombieden/custommusic/m6.mp3");
	}
}

public void OnConfigsExecuted()
{
	// Присваиваем серверу статус "официального".
	GameRules_SetProp("m_bIsValveDS", 1);
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	bCriticalState = false;
}

public void OnClientPostAdminCheck(int client)
{
	if(CheckCommandAccess(client, "", ADMFLAG_UNBAN, true)) bShowEntityCounter[client] = true;
}

public void OnClientDisconnect(int client)
{
	bShowEntityCounter[client] = false;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(entity > 1950)
	{
		if(!bCriticalState)
		{
			bCriticalState = true;
			LogToAdmins("ВНИМАНИЕ! Достигнуто критическое количество энтити!", true);
		}
	}
}

ChangeConVarsFlags()
{
	ConVar cvar;
	int flags;
	
	for(int i = 0; i <= sizeof(ConVars_RemoveReplicated)-1; i++)
	{
		cvar = FindConVar(ConVars_RemoveReplicated[i]);
		flags = GetConVarFlags(cvar) & ~FCVAR_REPLICATED;
		SetConVarFlags(cvar, flags);
	}
	
	for(int i = 0; i <= sizeof(ConVars_RemoveNotify)-1; i++)
	{
		cvar = FindConVar(ConVars_RemoveNotify[i]);
		flags = GetConVarFlags(cvar) & ~FCVAR_NOTIFY;
		SetConVarFlags(cvar, flags);
	}
}

public Action Timer_EntityCounter(Handle timer)
{
	int count = 0;
	int index = -1;
	
	while((index = FindEntityByClassname(index, "*")) != -1) count++;

	int reachedCount = GetEntityCount();

	if(count >= 2000) SetHudTextParams(0.62, 0.0, 2.0, 255, 0, 0, 255, 0, 30.0, 0.0, 0.0);
	else if(count >= 1500) SetHudTextParams(0.62, 0.0, 2.0, 255, 165, 0, 255, 0, 30.0, 0.0, 0.0);
	else SetHudTextParams(0.62, 0.0, 2.0, 255, 255, 255, 255, 0, 30.0, 0.0, 0.0);
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && bShowEntityCounter[client]) ShowHudText(client, 6, "Энтити: %i\n(%i/2048)", count, reachedCount);
	}
}

LogToAdmins(char[] logMessage, bool siren = false)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && CheckCommandAccess(client, "", ADMFLAG_UNBAN, true))
		{
			PrintToChat(client, " [LOGS] %s", logMessage);
			
			if(siren) ClientCommand(client, "playgamesound error.wav");
		}
	}
}
