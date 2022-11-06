#include <sdktools>

public Plugin myinfo =
{
	name = "entWatch Finder",
	author = "Walderr",
	description = "Позволяет искать материи на карте",
	version = "1.1",
	url = "http://jaze.ru/"
};

public void OnPluginStart()
{
	RegAdminCmd("findents", Command_FindEnts, ADMFLAG_UNBAN, "Найти все материи на карте");
	RegAdminCmd("entlist", Command_FindEnts, ADMFLAG_UNBAN, "Найти все материи на карте");
	
	RegAdminCmd("findmakers", Command_FindMakers, ADMFLAG_UNBAN, "Найти все спавнеры материй на карте");
	RegAdminCmd("makerslist", Command_FindMakers, ADMFLAG_UNBAN, "Найти все спавнеры материй на карте");
	
	RegAdminCmd("spawn", Command_Spawn, ADMFLAG_UNBAN, "Принудительно создать материю");
	
	RegAdminCmd("gotoent", Command_Goto, ADMFLAG_UNBAN, "Телепортироваться к энтити");
}

public Action Command_FindEnts(int client, int args)
{
	PrintToConsole(client, "------------------------Map Items:------------------------");
	
	for(int i = 1; i <= GetEntityCount(); i++)
	{
		if(!IsValidEdict(i)) continue;
		
		int hid = GetEntProp(i, Prop_Data, "m_iHammerID");
		
		if(!hid) continue;
		
		char class[MAX_NAME_LENGTH];
		GetEdictClassname(i, class, sizeof(class));
		
		if(StrContains(class, "weapon_") != -1)
		{
			char name[MAX_NAME_LENGTH];
			GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
			
			PrintToConsole(client, "ID: %i | HID: %i | %s | %s", i, hid, class, name);
		}
	}
	
	PrintToConsole(client, "----------------------------------------------------------");
	
	return Plugin_Handled;
}

public Action Command_FindMakers(int client, int args)
{
	PrintToConsole(client, "----------------------Entity Makers:----------------------");
	
	for(int i = 1; i <= GetEntityCount(); i++)
	{
		if(!IsValidEdict(i)) continue;
		
		int hid = GetEntProp(i, Prop_Data, "m_iHammerID");
		
		if(!hid) continue;
		
		char class[MAX_NAME_LENGTH];
		GetEdictClassname(i, class, sizeof(class));
		
		if(StrEqual(class, "env_entity_maker"))
		{
			char name[MAX_NAME_LENGTH];
			GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
			
			PrintToConsole(client, "ID: %i | HID: %i | %s", i, hid, name);
		}
	}
	
	PrintToConsole(client, "----------------------------------------------------------");
	
	return Plugin_Handled;
}

public Action Command_Spawn(int client, int args)
{
	char arg1[16];
	GetCmdArgString(arg1, sizeof(arg1));

	int index = StringToInt(arg1);
	
	if(!IsValidEdict(index))
	{
		PrintToConsole(client, "Энтити не найдена!");
		return Plugin_Handled;
	}
	
	int hid = GetEntProp(index, Prop_Data, "m_iHammerID");
	
	char name[MAX_NAME_LENGTH];
	GetEntPropString(index, Prop_Data, "m_iName", name, sizeof(name));
	
	AcceptEntityInput(index, "ForceSpawn");
	
	PrintToConsole(client, "Энтити %s (ID: %i | HID: %i) Успешно создана!", name, index, hid);
	return Plugin_Handled;
}

public Action Command_Goto(int client, int args)
{
	char arg1[256];
	GetCmdArgString(arg1, sizeof(arg1));

	if(StrEqual(arg1, ""))
	{
		ReplyToCommand(client, "Введите ID энтити!");
		return Plugin_Handled;
	}
	
	int index = StringToInt(arg1);
	
	if(!IsValidEdict(index))
	{
		ReplyToCommand(client, "Неверный ID энтити!");
		return Plugin_Handled;
	}

	float pos[3];
	GetEntPropVector(index, Prop_Send, "m_vecOrigin", pos);
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
	
	ReplyToCommand(client, "Вы телепортировались к %i!", index);

	return Plugin_Handled;
}