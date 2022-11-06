#include <sdktools>
#include <sdkhooks>

bool isDropped[2048];
int dropTime[2048];

public Plugin myinfo =
{
	name = "Weapon Cleaner",
	author = "Walderr",
	description = "Удаляет лежащее оружие",
	version = "1.0",
	url = "http://jaze.ru/"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
}

public void OnMapStart()
{
	// Создаём таймер, который будет искать лежащее оружие и удалять его.
	CreateTimer(10.0, Timer_DeleteWeapons, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

// Когда игрок подключился к серверу:
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponDropPost, Hook_WeaponDropPost);
	SDKHook(client, SDKHook_WeaponEquipPost, Hook_WeaponEquipPost);
}

// Отлов спавна Weapon manager'a
public void OnEntityCreated(int entity, const char[] classname)
{
    if(StrEqual(classname, "game_weapon_manager")) SDKHook(entity, SDKHook_Spawn, Spawn_GameWeaponManager);
}

// Удаляем встроенный в карту менеджер оружия.
public Action Spawn_GameWeaponManager(int entity)
{
	AcceptEntityInput(entity, "Kill");
	SDKUnhook(entity, SDKHook_Spawn, Spawn_GameWeaponManager);
}

public void OnEntityDestroyed(int entity)
{
	// Если дропнутое оружие удалилось, сбрасываем ему состояние.
	if(1 < entity < 2049 && isDropped[entity]) isDropped[entity] = false;
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i < 2048; i++) isDropped[i] = false;
}

public Action Timer_DeleteWeapons(Handle timer)
{
	// Ищем оружие среди всех энтити:
	for(int i = 1; i < 2048; i++)
	{
		// Если энтити имеет состояние "выброшено":
		if(isDropped[i])
		{
			// Если энтити существует:
			if(IsValidEntity(i))
			{
				// Если оружие выброшено больше 5 секунд назад:
				if(GetTime() - dropTime[i] > 5)
				{
					// Удаляем оружие
					AcceptEntityInput(i, "Kill");

					// Сбрасываем состояние дропа.
					isDropped[i] = false;
				}
			}
			// Иначе, если оружие уже удалено, выключаем состояние "выброшено".
			else isDropped[i] = false;
		}
	}
}

public Action Hook_WeaponDropPost(int client, int weapon)
{
	if(!IsValidEntity(weapon)) return Plugin_Continue;
	
	// Если игрок выбросил материю, выходим.
	if(GetEntProp(weapon, Prop_Data, "m_iHammerID") != 0) return Plugin_Continue;
	
	// Запоминаем состояние и время дропа.
	isDropped[weapon] = true;
	dropTime[weapon] = GetTime();
	
	return Plugin_Continue;
}

public Action Hook_WeaponEquipPost(int client, int weapon)
{
	// Сбрасываем состояниедропа.
	isDropped[weapon] = false;
}