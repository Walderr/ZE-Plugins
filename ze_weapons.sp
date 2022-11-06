#include <sdktools>
#include <sdkhooks>
#include <cstrike>

float knockbackValue;
float knockbackInAirValue;
float napalmTime;

ConVar Convar_KnockBackMultiplier;
ConVar Convar_KnockBackMultiplierInAir;
ConVar Convar_NapalmTime;

int g_vecVelocity;

int heColor[4] = {255,75,75,255};

int BeamSprite, g_beamsprite, g_halosprite;

public Plugin myinfo =
{
	name = "Weapons Manager",
	author = "Walderr",
	description = "Weapon stuff for Simple Zombie Escape Mod",
	version = "0.2.1",
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	HookEvent("hegrenade_detonate", Event_Hegrenade_Detonate);
	HookEvent("player_hurt", Event_PlayerHurt);
	
	g_vecVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	//Конвары
	Convar_KnockBackMultiplier = CreateConVar("ze_knockback_multiplier", "4", "Сила отброса зомби");
	Convar_KnockBackMultiplierInAir = CreateConVar("ze_knockback_multiplier_air", "1.2", "Сила отброса зомби в воздухе");
	Convar_NapalmTime = CreateConVar("ze_napalm_time", "6", "Время горения зомби");
	
	HookConVarChange(Convar_KnockBackMultiplier, OnCvarChanged);
	HookConVarChange(Convar_KnockBackMultiplierInAir, OnCvarChanged);
	HookConVarChange(Convar_NapalmTime, OnCvarChanged);
}

public OnMapStart() 
{
	BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_beamsprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_halosprite = PrecacheModel("materials/sprites/halo.vmt");
}

public void OnCvarChanged(Handle cvar, const char[] oldValue, const char[] newValue)
{
	if(cvar == Convar_KnockBackMultiplier) knockbackValue = StringToFloat(newValue);
	else if(cvar == Convar_KnockBackMultiplierInAir) knockbackInAirValue = StringToFloat(newValue);
	else if(cvar == Convar_NapalmTime) napalmTime = StringToFloat(newValue);
}

public void OnConfigsExecuted()
{
	knockbackValue = GetConVarFloat(Convar_KnockBackMultiplier);
	knockbackInAirValue = GetConVarFloat(Convar_KnockBackMultiplierInAir);
	napalmTime = GetConVarFloat(Convar_NapalmTime);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if(StrEqual(classname, "game_player_equip")) SDKHook(entity, SDKHook_Spawn, Spawn_GamePlayerEquip);
	else if(StrContains(classname, "_projectile") != -1) SDKHook(entity, SDKHook_SpawnPost, SpawnPost_Projectile);
}

public Action Spawn_GamePlayerEquip(int entity)
{
	char targetname[MAX_NAME_LENGTH];
	GetEntPropString(entity, Prop_Send, "m_iName", targetname, sizeof(targetname));
	
	if(StrEqual(targetname, ""))
	{
		SetEntProp(entity, Prop_Data, "m_spawnflags", 1); // Если установить на 1, энтити не будет вызываться в событии round start. 0 - все игроки получат оружие в событии round start от этой entity, но их оружие не будет удалено (если у игрока было оружие, оно выпадет).
		PrintToServer("[game_player_equip] %i : Disable", entity);
	}
	else PrintToServer("[game_player_equip] %i - %s : Skip", entity, targetname);
	
	SDKUnhook(entity, SDKHook_Spawn, Spawn_GamePlayerEquip);
}

public Action SpawnPost_Projectile(int entity)
{
	if(!GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")) return;

	char classname[64];
	GetEdictClassname(entity, classname, sizeof(classname));
	
	if(StrEqual(classname, "hegrenade_projectile"))
	{
		TE_SetupBeamFollow(entity, BeamSprite,	0, 1.0, 10.0, 10.0, 5, heColor);
		TE_SendToAll();	
	}
}

public Action Event_Hegrenade_Detonate(Handle event, const char[] name, bool dontBroadcast)
{
	float origin[3];
	origin[0] = GetEventFloat(event, "x"); origin[1] = GetEventFloat(event, "y"); origin[2] = GetEventFloat(event, "z");
	
	TE_SetupBeamRingPoint(origin, 10.0, 400.0, g_beamsprite, g_halosprite, 1, 1, 0.2, 100.0, 1.0, heColor, 0, 0);
	TE_SendToAll();
}

public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	// Получаем index жертвы.
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Если урон получил не зомби, выходим.
	if(GetClientTeam(victim) != CS_TEAM_T) return;
	
	// Получаем название оружия.
	char weaponName[32] = "";
	GetEventString(event, "weapon", weaponName, sizeof(weaponName));
	
	// Если урон получен от осколочной гранаты
	if(StrEqual(weaponName, "hegrenade"))
	{
		// Тушим игрока если уже горит.
		ExtinguishEntity(victim);
		
		// Поджигаем игрока.
		IgniteEntity(victim, napalmTime);
		
		// Выходим так как от гранаты отброс не нужен.
		return;
	}
	// Или если урон получен от молотова/inc, выходим.
	else if(StrEqual(weaponName, "inferno")) return;
	
	// Получаем index атакующего.
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	// Если урон нанёс не игрок, выходим (0 возвращается если userid атакующего не найден).
	if(attacker == 0) return;
	
	// Если игрок нанёс урон сам себе, выходим.
	if(victim == attacker) return;
	
	// Показываем маркер попадания атакующему.
	if(GetClientTeam(attacker) == CS_TEAM_CT)
	{
		SetHudTextParams(-1.0, -1.0, 0.1, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0);
		ShowHudText(attacker, 2, "∷");
	}
	
	// Берём позицию глаз атакующего и местоположение жертвы.
	float victimLocation[3];
	float attackerLocation[3];
	GetClientAbsOrigin(victim, victimLocation);
	GetClientEyePosition(attacker, attackerLocation);
	
	// Берём точку, в которую смотрит атакующий.
	float attackerEyeAngles[3];
	GetClientEyeAngles(attacker, attackerEyeAngles);
	
	// Рассчитываем направление отброса.
	TR_TraceRayFilter(attackerLocation, attackerEyeAngles, MASK_ALL, RayType_Infinite, KnockbackTRFilter);
	TR_GetEndPosition(victimLocation);
	
	// Получаем стандартное значение отброса.
	float knockback = knockbackValue;
	
	//=============================================

	// Отброс для оружия.
	if(StrEqual(weaponName, "bizon")) knockback *= 1.2;
	else if(StrEqual(weaponName, "awp")) knockback *= 0.3;
	else if(StrEqual(weaponName, "scar20")) knockback *= 0.3;
	else if(StrEqual(weaponName, "g3sg1")) knockback *= 0.3;
	else if(StrEqual(weaponName, "ssg08")) knockback *= 0.3;
	else if(StrEqual(weaponName, "negev")) knockback *= 0.7;
	else if(StrEqual(weaponName, "m249")) knockback *= 0.8;
	else if(StrEqual(weaponName, "deagle")) knockback *= 0.7;
	else if(StrEqual(weaponName, "nova")) knockback *= 0.2;
	else if(StrEqual(weaponName, "xm1014")) knockback *= 0.3;
	else if(StrEqual(weaponName, "mag7")) knockback *= 0.2;
	else if(StrEqual(weaponName, "sawedoff")) knockback *= 0.2;

	// Отброс в голову.
	if(GetEventInt(event, "hitgroup") == 1) knockback *= 0.8;

	//=============================================
	
	// Множитель отброса от урона.
	int damage = GetEventInt(event, "dmg_health");
	knockback *= float(damage);
	
	// Множитель отброса, если игрок в воздухе.
	if(GetEntPropEnt(victim, Prop_Send, "m_hGroundEntity") == -1) knockback *= knockbackInAirValue;
	
	// Создаем вектор из полученных начальной и конечной точек.
	float vector[3];
	MakeVectorFromPoints(attackerLocation, victimLocation, vector);
	
	// Нормализуем вектор.
	NormalizeVector(vector, vector);
	
	// Применяем магнитуду умножая каждый компонент вектора.
	ScaleVector(vector, knockback);
	
	// Получаем скорость жертвы.
	float vecClientVelocity[3];
	
	// x = компонент вектора.
	for (new x = 0; x < 3; x++)
	{
		vecClientVelocity[x] = GetEntDataFloat(victim, g_vecVelocity + (x*4));
	}
	
	AddVectors(vecClientVelocity, vector, vector);
	
	// Добавляем игроку ускорение для отброса.
	TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vector);
}

public bool KnockbackTRFilter(entity, contentsMask)
{
	// Если энтити - игрок, закончить трассировку.
	if(entity > 0 && entity < MAXPLAYERS) return false;
	
	// Искать дальше
	return true;
}