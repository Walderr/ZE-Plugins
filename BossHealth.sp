#include <sdktools>

char lastFindUser[64];
bool findCountersSpamProtect;

int damage[MAXPLAYERS+1];
bool bConfigLoaded;
bool spamProtect;
char mapname[128];
KeyValues hpdata;

public Plugin myinfo =
{
    name = "Boss Health",
    author = "Walderr",
    description = "Показывает здоровье боссов",
    version = "2.2.2",
};

public void OnPluginStart()
{
	LoadTranslations("BossHealth.phrases");

	HookEvent("round_start", Event_RoundStart);
	RegAdminCmd("sm_counters", Command_Counters, ADMFLAG_GENERIC);
	RegConsoleCmd("sm_findcounters", Command_FindCounters);
}

public void OnMapStart()
{
	GetCurrentMap(mapname, sizeof(mapname));
	hpdata = new KeyValues("Maps");
	bConfigLoaded = false;
	
	char mapConfig[PLATFORM_MAX_PATH];
	Format(mapConfig, sizeof(mapConfig), "cfg/sourcemod/bosshealth/%s.cfg", mapname);
	if(hpdata.ImportFromFile(mapConfig))
	{
		LogMessage("Загружен конфиг боссов для карты: %s.", mapname);
		bConfigLoaded = true;
		
		hpdata.Rewind();
		hpdata.JumpToKey("Bosses");
		
		int BossType = hpdata.GetNum("BossType", 1);
		
		if(BossType == 1)
			HookEntityOutput("math_counter", "OutValue", OutValue);
		else if(BossType == 2)
			HookEntityOutput("math_counter", "OutValue", OutValueVer2);
		else if(BossType == 3)
			HookEntityOutput("math_counter", "OutValue", OutValueVer3);
		else if(BossType == 4)
			HookEntityOutput("func_physbox_multiplayer", "OnHealthChanged", OnHealthChanged);
	}
}

public void OnMapEnd()
{
	UnhookEntityOutput("math_counter", "OutValue", OutValue);
	UnhookEntityOutput("math_counter", "OutValue", OutValueVer2);
	UnhookEntityOutput("math_counter", "OutValue", OutValueVer3);
	UnhookEntityOutput("func_physbox_multiplayer", "OnHealthChanged", OnHealthChanged);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients + 1; i++)
		damage[i] = 0;
}

public Action Command_Counters(int client, int args)
{
	int index;
	PrintToChat(client, " \x07--------Счётчики:--------");
	
	while((index = FindEntityByClassname(index, "math_counter")) != -1) 
	{
		char strName[64];
		GetEntPropString(index, Prop_Data, "m_iName", strName, sizeof(strName));
		
		int offset = FindDataMapInfo(index, "m_OutValue");
		float value = GetEntDataFloat(index, offset);
		int intValue = RoundToZero(value);
		
		PrintToChat(client, " \x0BИмя:\x04 %s,\x0B Значение:\x04 %i", strName, intValue);
	}
	
	PrintToChat(client, " \x07----------------------------");
	return Plugin_Handled;
}

public Action Command_FindCounters(int client, int args)
{
	if(findCountersSpamProtect)
	{
		PrintToChat(client, "Недавно %s уже использовал эту команду, подождите немного!", lastFindUser);
		return Plugin_Handled;
	}
	
	int index;
	PrintToChat(client, " \x07--------Счётчики:--------");
	
	while((index = FindEntityByClassname(index, "math_counter")) != -1) 
	{
		char strName[64];
		GetEntPropString(index, Prop_Data, "m_iName", strName, sizeof(strName));
		
		int offset = FindDataMapInfo(index, "m_OutValue");
		float value = GetEntDataFloat(index, offset);
		int intValue = RoundToZero(value);
		
		PrintToChat(client, " \x0BИмя:\x04 %s,\x0B Значение:\x04 %i", strName, intValue);
	}
	
	PrintToChat(client, " \x07----------------------------");
	
	FormatEx(lastFindUser, sizeof(lastFindUser), "%N", client);
	findCountersSpamProtect = true;
	
	CreateTimer(20.0, FindSpam);
	return Plugin_Handled;
}

public Action FindSpam(Handle timer, any client)
{
	findCountersSpamProtect = false;
}

public void OutValue(char[] output, int caller, int activator, float Any)
{
	if(!bConfigLoaded) return;
	
	hpdata.Rewind();
	hpdata.JumpToKey("Bosses");

	char BossCounterName[128];
	GetEntPropString(caller, Prop_Data, "m_iName", BossCounterName, sizeof(BossCounterName));
	
	if(!hpdata.JumpToKey(BossCounterName)) return;

	char IterationsCounter[128];
	hpdata.GetString("iterationsCounter", IterationsCounter, sizeof(IterationsCounter));
	
	int iterations;
	
	if(StrEqual(IterationsCounter, ""))
	{
		iterations = 1;
	}
	else
	{
		iterations = GetValue(IterationsCounter);
	}

	if(iterations < 1) return;

	int offset = FindDataMapInfo(caller, "m_OutValue");
	if(offset == -1) return;
	
	float value = GetEntDataFloat(caller, offset);
	int intValue = RoundToZero(value);
	
	char BackupHpCounter[128];
	hpdata.GetString("backupHpCounter", BackupHpCounter, sizeof(BackupHpCounter));

	int fullhealth;

	if(StrEqual(BackupHpCounter, ""))
	{
		fullhealth = intValue;
	}
	else
	{
		fullhealth = GetValue(BackupHpCounter);
	}

	if(fullhealth > 0)
	{
		char BossName[128];
		hpdata.GetString("name", BossName, sizeof(BossName));
		
		int finalValue = intValue + (fullhealth * (iterations - 1));
		
		if(finalValue > 0)
		{
			char HudType[128];
			hpdata.GetString("hudType", HudType, sizeof(HudType));
			
			if(StrEqual(HudType, "Center")) PrintCenterTextAll("%t", "Boss Attack", BossName, finalValue, intValue, iterations);
			else PrintHintTextToAll("%t", "Boss Attack", BossName, finalValue, intValue, iterations); // <font color='#FFFFFF'>Босс: </font> <font color='#2EFE2E'>%s</font> \n<font color='#FFFFFF'>Здоровье:</font> <span class='fontSize-xl'><font color='#2EFE2E'>%i</font></span>		<font color='#808080'>%i:%i</font>
			
			if(activator > 0 && activator <= MaxClients + 1)
			{
				damage[activator]++;
				
				// Показываем маркер попадания стреляющему.
				SetHudTextParams(-1.0, -1.0, 0.1, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0);
				ShowHudText(activator, 2, "∷");
			}
		}
	}
	
	if((iterations == 1 && intValue == 0) && spamProtect == false)
	{
		PrintHintTextToAll("%t", "Boss Kill"); //  <span class='fontSize-xl'><font color='#008000'>Босс убит!</font></span>
		if(activator > 0 && activator <= MaxClients + 1)
		{
			RewardBossKiller(activator);
		}

		RewardTopDamager();
		
		spamProtect = true;
		CreateTimer(2.0, Timer_BossKilled);
	}
}

public void OutValueVer2(char[] output, int caller, int activator, float Any)
{
	if(!bConfigLoaded) return;
	
	hpdata.Rewind();
	hpdata.JumpToKey("Bosses");

	char BossCounterName[128];
	GetEntPropString(caller, Prop_Data, "m_iName", BossCounterName, sizeof(BossCounterName));
	
	if(!hpdata.JumpToKey(BossCounterName)) return;

	char PlayersCounter[128];
	hpdata.GetString("PlayersCounter", PlayersCounter, sizeof(PlayersCounter));
	
	int players = GetValue(PlayersCounter);

	if(players < 1) return;

	int offset = FindDataMapInfo(caller, "m_OutValue");
	if(offset == -1) return;
	
	float value = GetEntDataFloat(caller, offset);
	int intValue = RoundToZero(value);
	
	char MultiplierPerPlayer[128];
	hpdata.GetString("MultiplierPerPlayer", MultiplierPerPlayer, sizeof(MultiplierPerPlayer));

	int multiplier = StringToInt(MultiplierPerPlayer);

	char BossName[128];
	hpdata.GetString("name", BossName, sizeof(BossName));
	
	int finalValue = players * multiplier - intValue;
	
	if(finalValue > 0)
	{
		char HudType[128];
		hpdata.GetString("hudType", HudType, sizeof(HudType));

		if(StrEqual(HudType, "Center")) PrintCenterTextAll("%t", "Boss Attack", BossName, finalValue, intValue, players);
		else PrintHintTextToAll("%t", "Boss Attack", BossName, finalValue, intValue, players);

		if(activator > 0 && activator <= MaxClients + 1)
		{
			damage[activator]++;
			
			// Показываем маркер попадания стреляющему.
			SetHudTextParams(-1.0, -1.0, 0.1, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0);
			ShowHudText(activator, 2, "∷");
		}
	}
	
	if((intValue == players * multiplier) && spamProtect == false)
	{
		PrintHintTextToAll("%t", "Boss Kill");
		if(activator > 0 && activator <= MaxClients + 1)
		{
			RewardBossKiller(activator);
		}

		RewardTopDamager();
		
		spamProtect = true;
		CreateTimer(2.0, Timer_BossKilled);
	}
}

public void OutValueVer3(char[] output, int caller, int activator, float Any)
{
	if(!bConfigLoaded) return;
	
	hpdata.Rewind();
	hpdata.JumpToKey("Bosses");

	char BossCounterName[128];
	GetEntPropString(caller, Prop_Data, "m_iName", BossCounterName, sizeof(BossCounterName));
	
	if(!hpdata.JumpToKey(BossCounterName)) return;

	char IterationsCounter[128];
	hpdata.GetString("iterationsCounter", IterationsCounter, sizeof(IterationsCounter));
	
	int iterations, maxiterations;
	
	if(StrEqual(IterationsCounter, ""))
	{
		iterations = 0;
		maxiterations = 1;
	}
	else
	{
		iterations = GetValue(IterationsCounter);
		maxiterations = GetMaxValue(IterationsCounter);
	}

	int offset = FindDataMapInfo(caller, "m_OutValue");
	if(offset == -1) return;
	
	float value = GetEntDataFloat(caller, offset);
	int intValue = RoundToZero(value);
	
	char BackupHpCounter[128];
	hpdata.GetString("backupHpCounter", BackupHpCounter, sizeof(BackupHpCounter));

	int fullhealth;

	if(StrEqual(BackupHpCounter, ""))
	{
		fullhealth = intValue;
	}
	else
	{
		fullhealth = GetValue(BackupHpCounter);
	}
	
	if(maxiterations > 1 && intValue == fullhealth) return;
	
	if(intValue > 0)
	{
		char BossName[128];
		hpdata.GetString("name", BossName, sizeof(BossName));
		
		//new finalValue = intValue + (fullhealth * (maxiterations - 1));
		
		int finalValue = intValue + fullhealth * (maxiterations -1 - iterations);
		
		if(finalValue > 0 && iterations <= maxiterations)
		{
			char HudType[128];
			hpdata.GetString("hudType", HudType, sizeof(HudType));

			if(StrEqual(HudType, "Center")) PrintCenterTextAll("%t", "Boss Attack", BossName, finalValue, intValue, iterations);
			else PrintHintTextToAll("%t", "Boss Attack", BossName, finalValue, intValue, iterations);

			if(activator > 0 && activator <= MaxClients + 1)
			{
				damage[activator]++;
				
				// Показываем маркер попадания стреляющему.
				SetHudTextParams(-1.0, -1.0, 0.1, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0);
				ShowHudText(activator, 2, "∷");
			}
		}
	}
	
	if((iterations == maxiterations - 1 && intValue == 0) && spamProtect == false)
	{
		PrintHintTextToAll("%t", "Boss Kill");
		if(activator > 0 && activator <= MaxClients + 1)
		{
			RewardBossKiller(activator);
		}

		RewardTopDamager();
		
		spamProtect = true;
		CreateTimer(2.0, Timer_BossKilled);
	}
}

public void OnHealthChanged(const char[] output, int caller, int activator, float delay)
{
	if(!bConfigLoaded) return;
	
	hpdata.Rewind();
	hpdata.JumpToKey("Bosses");
	
	char BossCounterName[128];
	GetEntPropString(caller, Prop_Data, "m_iName", BossCounterName, sizeof(BossCounterName));
	
	if(!hpdata.JumpToKey(BossCounterName)) return;
	
	int health = GetEntProp(caller, Prop_Data, "m_iHealth");
	
	if(health > 0 && health < 10000000)
	{
		char BossName[128];
		hpdata.GetString("name", BossName, sizeof(BossName));
		
		char HudType[128];
		hpdata.GetString("hudType", HudType, sizeof(HudType));
		
		if(StrEqual(HudType, "Center")) PrintCenterTextAll("%t", "Boss Attack Breakable", BossName, health);
		else PrintHintTextToAll("%t", "Boss Attack Breakable", BossName, health); 
		
		if(activator > 0 && activator <= MaxClients + 1)
		{
			// Показываем маркер попадания стреляющему.
			SetHudTextParams(-1.0, -1.0, 0.1, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0);
			ShowHudText(activator, 2, "∷");
		}
	}
}

int GetValue(char[] ValueCounter)
{
	char name[128];
	int index;
	
	do {
		index = FindEntityByClassname(index, "math_counter");
		GetEntPropString(index, Prop_Data, "m_iName", name, sizeof(name));
		
	} while(!StrEqual(ValueCounter, name))

	int offset = FindDataMapInfo(index, "m_OutValue");

	float value = GetEntDataFloat(index, offset);
	int intValue = RoundToZero(value);
	
	return intValue;
}

int GetMaxValue(char[] MaxValueCounter)
{
	char name[128];
	int index;
	
	do {
		index = FindEntityByClassname(index, "math_counter");
		GetEntPropString(index, Prop_Data, "m_iName", name, sizeof(name));
		
	} while(!StrEqual(MaxValueCounter, name))

	int offset = FindDataMapInfo(index, "m_flMax");

	float value = GetEntDataFloat(index, offset);
	int intValue = RoundToZero(value);
	
	return intValue;
}

void RewardBossKiller(int client)
{
	PrintToChatAll("%t", "Boss_Killed", client);
}

void RewardTopDamager()
{
	int topDamager = 0;
	
	for(int i = 1; i <= MaxClients + 1; i++)
	{
		if(damage[topDamager] < damage[i])
			topDamager = i;
	}
	
	if(topDamager != 0)
	{
		PrintToChatAll("%t", "Boss_Top_Damager", topDamager, damage[topDamager]);
	}
	
	for(int i = 1; i <= MaxClients + 1; i++)
	{
		if(damage[i] > 0 && i != topDamager && IsClientInGame(i)) PrintToChat(i, "%t", "Boss_Your_Damage", damage[i]);
	
		damage[i] = 0;
	}
}

public Action Timer_BossKilled(Handle timer) 
{ 
	spamProtect = false;
}