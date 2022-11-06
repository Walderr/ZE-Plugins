
// Функция, завершает таймер.
// Принимает: handle таймера.

SZE_EndTimer(Handle timer)
{
	// Если таймер запущен, завершаем его.
	if(timer != INVALID_HANDLE) KillTimer(timer);
}

// Функция, определяет количество подходящих для заражения игроков.
// Возвращает: int количество подходящих игроков.

SZE_GetEligiblePlayers()
{
	int eligiblePlayers = 0;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		// Если игрок в игре и человек, добавить +1 к количеству подходящих.
		if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT) eligiblePlayers++;
	}
	return eligiblePlayers;
}

// Bool Функция, проверяет все ли игроки заражены.
// Возвращает: true если людей в команде нет, false если есть.

bool SZE_AllHumansInfected()
{
	int aliveHumans = 0;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT && IsPlayerAlive(i)) aliveHumans++;
	}
	
	if(aliveHumans > 0) return false;
	else return true;
}

// Функция, заражает случайного игрока.
// Принимает: int здоровье зомби.
// Возвращает: index выбранного игрока.

SZE_InfectRandomPlayer(bool firstInfect = false)
{
	int eligiblePlayers = 0, index[MAXPLAYERS+1];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT)
		{
			if(firstInfect)
			{
				if(!g_bDoubleInfectProtect[i])
				{
					eligiblePlayers++;
					index[eligiblePlayers] = i;
				}
			}
			else
			{
				eligiblePlayers++;
				index[eligiblePlayers] = i;
			}
		}
	}
	
	if(eligiblePlayers > 0)
	{
		int choosenPlayer = index[GetRandomInt(1, eligiblePlayers)];
		
		SZE_InfectPlayer(choosenPlayer);
		
		// Запоминаем что игрок уже заражен.
		g_b_TempDoubleInfectProtect[choosenPlayer] = true;
		
		return choosenPlayer;
	}
	
	return -1;
}

// Функция, заражает игрока.
// Принимает: index игрока, int здоровье зомби.

SZE_InfectPlayer(int client)
{
	// Переносим в команду зомби.
	CS_SwitchTeam(client, CS_TEAM_T);
	
	// Возрождаем игрока если мёртв.
	if(!IsPlayerAlive(client)) CS_RespawnPlayer(client);
	
	// Устанавливаем количество здоровья.
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1) SetEntityHealth(client, vipZombieHealth);
	else SetEntityHealth(client, zombieHealth);
	
	// Переменные для хранения путей модели и рук.
	char modelPath[128];
	char armsPath[128];
	
	// Выбираем случайную модель зомби и рук.
	int random = GetRandomInt(1, 2);
	
	if(random == 1)
	{
		Format(modelPath, 128, "models/player/mapeadores/morell/ghoul/ghoulfix.mdl");
		Format(armsPath, 128, "models/player/colateam/zombie1/arms.mdl");
	}
	/*else if(random == 2)
	{
		Format(modelPath, 128, "models/player/custom/hunter/hunter.mdl");
		Format(armsPath, 128, "models/player/colateam/zombie1/arms.mdl");
	}*/
	else
	{
		Format(modelPath, 128, "models/player/custom_player/kuristaja/walker/walkerv2.mdl");
		Format(armsPath, 128, "models/player/custom_player/kuristaja/walker/walker_arms.mdl");
	}
	
	// Изменяем модель.
	SetEntityModel(client, modelPath);
	
	// Изменяем модель рук.
	SetEntPropString(client, Prop_Send, "m_szArmsModel", armsPath);
	
	// Проигрываем звук.
	SZE_EmitSoundToAll("zr/fz_scream1.mp3", client, 3)
	
	// Трясём экран.
	Handle hShake = StartMessageOne("Shake", client);

	PbSetInt(hShake, "command", 0);
	PbSetFloat(hShake, "local_amplitude", 15.0); // амплитуда
	PbSetFloat(hShake, "frequency", 1.0); // частота
	PbSetFloat(hShake, "duration", 5.0); // время
	
	EndMessage();
	
	// Выбрасываем все оружие.
	int weaponSlot = 0;
	
	do {
		int weapon = GetPlayerWeaponSlot(client, weaponSlot);
		
		if(weapon != -1)
		{
			if(GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity") != client)
			{
				weaponSlot++;
				continue;
			}
			
			CS_DropWeapon(client, weapon, true);
			if(weaponSlot == 2) AcceptEntityInput(weapon, "Kill");
		}
		
		else weaponSlot++;
		
	} while( weaponSlot < 5 );
	
	// Выдаём нож.
	GivePlayerItem(client, "weapon_knife");
	
	// Забираем шлем и броню.
	SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
	SetEntProp(client, Prop_Send, "m_ArmorValue", 0);
}

// Функция, переносит игрока к людям.
// Принимает: index игрока, int здоровье человека.

SZE_MoveToHumans(int client)
{
	// Переносим в команду людей.
	CS_SwitchTeam(client, CS_TEAM_CT);
	
	// Возрождаем игрока если мёртв.
	if(!IsPlayerAlive(client)) CS_RespawnPlayer(client);
	
	// Устанавливаем количество здоровья.
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1) SetEntityHealth(client, vipHumanHealth);
	else SetEntityHealth(client, humanHealth);
	
	char playerModel[256], playerArms[256];
	Handle h_ModelCookie = FindClientCookie("ModelPath");
	Handle h_ArmsCookie = FindClientCookie("ArmsPath");
	GetClientCookie(client, h_ModelCookie, playerModel, sizeof(playerModel));
	GetClientCookie(client, h_ArmsCookie, playerArms, sizeof(playerArms));
	
	// Изменяем модель.
	if(!StrEqual(playerModel, "")) SetEntityModel(client, playerModel);
	else SetEntityModel(client, "models/player/custom_player/kuristaja/re6/chris/chrisv4.mdl");
	
	// Изменяем модель рук.
	if(!StrEqual(playerArms, "")) SetEntPropString(client, Prop_Send, "m_szArmsModel", playerArms);
	else SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/kuristaja/re6/chris/chris_arms.mdl");
}

// Функция, показывает оверлей всем игрокам.
// Принимает: char путь до оверлея.

SZE_ShowOverlayToAll(const char[] path)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		// Если игрок на сервере, показать ему оверлей.
		if(IsClientInGame(i)) ClientCommand(i, "r_screenoverlay \"%s\"", path);
	}
}

// Функция, воспроизводит всем звук.
// Принимает: char путь до звука, int источник звука, int тип звука.
SZE_EmitSoundToAll(char[] sample, int entity, int soundType)
{
	if(soundType == 1) // звук урона.
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i)) EmitSoundToClient(i, sample, entity, _, SNDLEVEL_NORMAL, _, hurtVolume[i]);
		}
	}
	else if(soundType == 2) // звук смерти.
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i)) EmitSoundToClient(i, sample, entity, _, SNDLEVEL_NORMAL, _, deathVolume[i]);
		}
	}
	else if(soundType == 3) // звук заражения.
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i)) EmitSoundToClient(i, sample, entity, _, SNDLEVEL_NORMAL, _, infectVolume[i]);
		}
	}
}

