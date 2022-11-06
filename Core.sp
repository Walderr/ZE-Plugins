#include <sdktools>
#include <cstrike>

char mapname[128];
KeyValues ardata;

bool arConfigLoaded;
bool isWaitMsg[MAXPLAYERS+1];
Float:posBackup[MAXPLAYERS+1][3];
Float:anglesBackup[MAXPLAYERS+1][3];
Float:arPosBackup[MAXPLAYERS+1][3];
Float:arAnglesBackup[MAXPLAYERS+1][3];

public Plugin:myinfo =
{
	name = "Core",
	author = "Walderr",
	description = "Ядро модулей",
	version = "1.1.3",
};

public OnPluginStart()
{
	LoadTranslations("common.phrases.txt");
	AddCommandListener(OnPlayerChatMessage, "say");
	AddCommandListener(OnPlayerChatMessage, "say_team");
	RegAdminCmd("sm_smart", Command_Smart, ADMFLAG_UNBAN);
	RegAdminCmd("sm_snoclip", Command_SetNoClip, ADMFLAG_UNBAN);
}

public OnMapStart()
{
	GetCurrentMap(mapname, sizeof(mapname));
	ardata = new KeyValues("Maps");
	arConfigLoaded = false;
	
	char mapConfig[PLATFORM_MAX_PATH];
	Format(mapConfig, sizeof(mapConfig), "cfg/sourcemod/adminrooms/%s.cfg", mapname);
	if(ardata.ImportFromFile(mapConfig))
	{
		LogMessage("Загружены AdminRooms для карты: %s.", mapname);
		arConfigLoaded = true;
	}
}

public Action OnPlayerChatMessage(int client, const char[] command, int argc)
{	
	//Если не ждем сообщения
	if(isWaitMsg[client] == false)
		return Plugin_Continue;
		
	//Если игрок ввел команду
	if(IsChatTrigger())
		return Plugin_Continue;
		
	//Берем сообщение
	char cMessage[256];
	GetCmdArgString(cMessage, sizeof(cMessage));
	StripQuotes(cMessage); 
	
	//Отмена, если строка пустая
	if(StrEqual(cMessage, "") || StrEqual(cMessage, " ")) {
		isWaitMsg[client] = false;
		PrintToChat(client, " \x10[CORE]\x08 Вы отправили пустое сообщение! Действие отменено!");
		return Plugin_Handled;
	}
	
	decl String:sCoords[3][8]; 
	if(ExplodeString(cMessage, " ", sCoords, 3, 8) > 2) {
		new Float:Coords[3];
		Coords[0] = StringToFloat(sCoords[0]);
		Coords[1] = StringToFloat(sCoords[1]); 
		Coords[2] = StringToFloat(sCoords[2]) - 44; 
		
		char log[128];
		Format(log, sizeof(log), " \x10[CORE]\x0B %N\x01 телепортировался по координатам: \x04 %s %s %s", client, sCoords[0], sCoords[1], sCoords[2]);
		ShowLog(log);
		TeleportPlayer(client, Coords);
	} 	
	else PrintToChat(client, " \x10[CORE]\x08 Введите координаты в формате\x07 x y z!");

	return Plugin_Handled;
}

public Action Command_Smart(client, args) {
	ShowSmartMenu(client);
	return Plugin_Handled;
}

public Action Command_SetNoClip(client, args) {
	SetNoClip(client);
	return Plugin_Handled;
}

ShowSmartMenu(client) {
	new Handle:smartmenu = CreateMenu(SmartCallBack);

	SetMenuTitle(smartmenu, "Smart Admin:");
	AddMenuItem(smartmenu, "Действия", "Действия");
	AddMenuItem(smartmenu, "Информация об игроках", "Информация об игроках", ITEMDRAW_DISABLED);
	AddMenuItem(smartmenu, "Управление игроками", "Управление игроками");
	AddMenuItem(smartmenu, "Параметры карты", "Параметры карты");

	SetMenuExitButton(smartmenu, true);
	DisplayMenu(smartmenu, client, 180);
}

public SmartCallBack(Handle:smartmenu, MenuAction:action, client, option) {
	if(action == MenuAction_Select) 
	{
		//char log[128];
		decl String:item[64];
		GetMenuItem(smartmenu, option, item, sizeof(item));
		if(StrEqual(item, "Действия")) {
			ShowActionMenu(client);
			//Format(log, sizeof(log), " \x10[CORE]\x0B %N\x01 открыл\x04 Меню действий", client);
		}
		if(StrEqual(item, "Информация об игроках")) {
			ShowInfoMenu(client);
			//Format(log, sizeof(log), " \x10[CORE]\x0B %N\x01 открыл\x04 Меню информации об игроках", client);
		}
		if(StrEqual(item, "Управление игроками")) {
			ShowPlayerControlMenu(client);
			//Format(log, sizeof(log), " \x10[CORE]\x0B %N\x01 открыл\x04 Меню управления игроками", client);
		}
		if(StrEqual(item, "Параметры карты")) {
			ShowMapMenu(client);
			//Format(log, sizeof(log), " \x10[CORE]\x0B %N\x01 открыл\x04 Меню управления картой", client);
		}
		//ShowLog(log);
	}
	if(action == MenuAction_End) 
	{
		CloseHandle(smartmenu); 
	}
}

ShowActionMenu(client) {
	new Handle:actionmenu = CreateMenu(ActionCallBack);

	SetMenuTitle(actionmenu, "Меню действий:");
	AddMenuItem(actionmenu, "Silent NoClip", "Silent NoClip");
	AddMenuItem(actionmenu, "Ghost", "Ghost Mode");
	AddMenuItem(actionmenu, "Intangible", "Intangible Mode");
	AddMenuItem(actionmenu, "Режим Полёта", "Режим Полёта");
	AddMenuItem(actionmenu, "Телепорт по координатам", "Телепорт по координатам");
	AddMenuItem(actionmenu, "Модуль Cheats", "Модуль Cheats");
	
	SetMenuExitBackButton(actionmenu, true);
	SetMenuExitButton(actionmenu, true);
	DisplayMenu(actionmenu, client, 180);
}

public ActionCallBack(Handle:actionmenu, MenuAction:action, client, option) {
	if(action == MenuAction_Select)
	{
		decl String:item[64];
		GetMenuItem(actionmenu, option, item, sizeof(item));
		if(StrEqual(item, "Silent NoClip")) {
			SetNoClip(client);
			ShowActionMenu(client);
		}
		else if(StrEqual(item, "Режим Полёта")) {
			SetFlyMode(client);
			ShowActionMenu(client);
		}
		else if(StrEqual(item, "Телепорт по координатам")) {
			PrepareToTeleport(client);
		}
		else if(StrEqual(item, "Модуль Cheats")) {
			ShowCheatsMenu(client);
		}
		else if(StrEqual(item, "Ghost")) {
			ShowGhostMenu(client);
		}
		else if(StrEqual(item, "Intangible")) {
			ShowIntangibleMenu(client);
		}
	}
	if(option == MenuCancel_ExitBack)
	{
		ShowSmartMenu(client);
	}
	if(action == MenuAction_End) 
	{
		CloseHandle(actionmenu); 
	}
}

ShowInfoMenu(client) {
	new Handle:infomenu = CreateMenu(InfoCallBack);

	SetMenuTitle(infomenu, "Выберите игрока:");
	
	char item[128];
	char index[4];
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i))
		{
			Format(index, sizeof(index), "%i", i);
			Format(item, sizeof(item), "%N", i);
			AddMenuItem(infomenu, index, item);
		}
	}
	
	SetMenuExitBackButton(infomenu, true);
	SetMenuExitButton(infomenu, true);
	DisplayMenu(infomenu, client, 180);
}

public InfoCallBack(Handle:infomenu, MenuAction:action, client, option) {
	if(action == MenuAction_Select) 
	{
		decl String:item[64];
		GetMenuItem(infomenu, option, item, sizeof(item));

	}
	if(option == MenuCancel_ExitBack)
	{
		ShowSmartMenu(client);
	}
	if(action == MenuAction_End) 
	{
		CloseHandle(infomenu); 
	}
}

ShowPlayerControlMenu(client) {
	new Handle:playercontrolmenu = CreateMenu(PlayerControlCallBack);

	SetMenuTitle(playercontrolmenu, "Управление игроками:");
	AddMenuItem(playercontrolmenu, "Написать в чат от имени", "Написать в чат от имени");
	AddMenuItem(playercontrolmenu, "Шлёпнуть без уведомления", "Шлёпнуть без уведомления");


	SetMenuExitBackButton(playercontrolmenu, true);
	SetMenuExitButton(playercontrolmenu, true);
	DisplayMenu(playercontrolmenu, client, 180);
}

public PlayerControlCallBack(Handle:playercontrolmenu, MenuAction:action, client, option) {
	if(action == MenuAction_Select) 
	{
		decl String:item[64];
		GetMenuItem(playercontrolmenu, option, item, sizeof(item));
		if(StrEqual(item, "Написать в чат от имени")) {
		
			PrintToChat(client, " \x10[CORE]\x01 чтобы написать в чат за игрока, введите /sayfor\x07 игрок\x0B текст");
			ShowPlayerControlMenu(client);
		}
		if(StrEqual(item, "Шлёпнуть без уведомления")) {
		
			ShowSilentSlapMenu(client);
		}

	}
	if(option == MenuCancel_ExitBack)
	{
		ShowSmartMenu(client);
	}
	if(action == MenuAction_End) 
	{
		CloseHandle(playercontrolmenu); 
	}
}

ShowMapMenu(client) {
	new Handle:mapmenu = CreateMenu(MapCallBack);

	SetMenuTitle(mapmenu, "Параметры карты:");
	AddMenuItem(mapmenu, "Показать список счётчиков", "Показать список счётчиков");
	
	if(arConfigLoaded) {
		AddMenuItem(mapmenu, "Перейти в AdminRoom", "Перейти в AdminRoom");
		AddMenuItem(mapmenu, "Smart AdminRoom", "Smart AdminRoom");
	}
	else {
		AddMenuItem(mapmenu, "Перейти в AdminRoom", "Перейти в AdminRoom", ITEMDRAW_DISABLED);
		AddMenuItem(mapmenu, "Smart AdminRoom", "Smart AdminRoom", ITEMDRAW_DISABLED);
	}
	
	AddMenuItem(mapmenu, "Завершить раунд", "Завершить раунд");
	
	SetMenuExitBackButton(mapmenu, true);
	SetMenuExitButton(mapmenu, true);
	DisplayMenu(mapmenu, client, 180);
}

public MapCallBack(Handle:mapmenu, MenuAction:action, client, option) {
	if(action == MenuAction_Select) 
	{
		decl String:item[64];
		GetMenuItem(mapmenu, option, item, sizeof(item));
		if(StrEqual(item, "Показать список счётчиков")) {
			FakeClientCommand(client, "sm_counters");
			ShowMapMenu(client);
		}
		if(StrEqual(item, "Перейти в AdminRoom")) {
			GoToAdminRoom(client);
		}
		if(StrEqual(item, "Smart AdminRoom")) {
			OpenSmartAdminRoom(client);
			//char log[128];
			//Format(log, sizeof(log), " \x10[CORE]\x0B %N\x01 открыл\x04 Smart AdminRoom", client);
			//ShowLog(log);
		}
		if(StrEqual(item, "Завершить раунд")) {
			TerminateRound(client);
		}
	}
	if(option == MenuCancel_ExitBack)
	{
		ShowSmartMenu(client);
	}
	if(action == MenuAction_End) 
	{
		CloseHandle(mapmenu); 
	}
}

ShowCheatsMenu(client) {
	new Handle:cheatsmenu = CreateMenu(CheatsCallBack);

	SetMenuTitle(cheatsmenu, "Модуль Cheats:");
	AddMenuItem(cheatsmenu, "Запросить sv_cheats", "Запросить sv_cheats");
	AddMenuItem(cheatsmenu, "Вывести список команд", "Вывести список команд");
	
	SetMenuExitBackButton(cheatsmenu, true);
	SetMenuExitButton(cheatsmenu, true);
	DisplayMenu(cheatsmenu, client, 180);
}

public CheatsCallBack(Handle:cheatsmenu, MenuAction:action, client, option) {
	if(action == MenuAction_Select) 
	{
		//char log[128];
		decl String:item[64];
		GetMenuItem(cheatsmenu, option, item, sizeof(item));

		if(StrEqual(item, "Запросить sv_cheats")) {
			SendConVarValue(client, FindConVar("sv_cheats"), "1");
			//Format(log, sizeof(log), " \x02[CHEATS]\x0B %N\x01 запросил\x02 sv_cheats", client);
			//ShowLog(log);
			PrintToChat(client, " \x02[CHEATS]\x01 Теперь вы можете выполнять команды, требующие sv_cheats");
			ShowCheatsMenu(client);
		}
		if(StrEqual(item, "Вывести список команд")) {
			PrintToConsole(client, "----------------------------------------------------------------------------------------------");
			PrintToConsole(client, "Список команд:");
			PrintToConsole(client, "mat_wireframe 0 1 2 3 4		|	ESP карты");
			PrintToConsole(client, "r_drawothermodels 0 1 2		|	Отрисовка игроков и оружия");
			PrintToConsole(client, "snd_show 0 1			|	Дебаг звуков");
			PrintToConsole(client, "snd_visualize 0 1			|	Визуализация звуков");
			PrintToConsole(client, "mat_fillrate 0 1			|	Asus Walls");
			PrintToConsole(client, "mat_proxy 0 1 2			|	Asus Walls (мигающий)");
			PrintToConsole(client, "r_drawbrushmodels 0 1 2		|	Выделение брашей");
			PrintToConsole(client, "r_showenvcubemap 0 1		|	Падение теней");
			PrintToConsole(client, "mat_fullbright 0 1 2		|	Яркость/цвет");
			PrintToConsole(client, "r_drawparticles 0 1			|	Отрисовка частиц");
			PrintToConsole(client, "r_partition_level -1 1		|	Полный ESP карты (лагает) (на 0 не ставить)");
			PrintToConsole(client, "cl_leveloverview 0 1		|	Арт режим");
			PrintToConsole(client, "r_visualizetraces 0 1		|	Трассеры");
			PrintToConsole(client, "cl_particles_show_bbox 0 1	|	Обрисовка частиц");
			PrintToConsole(client, "r_drawrenderboxes 0 1 2 3	|	Отрисовка боксов игроков");
			PrintToConsole(client, "r_drawlights 0 1			|	Отображение света");
			PrintToConsole(client, "vcollide_wireframe 0 1		|	Отрисовка коллизий");
			PrintToConsole(client, "mat_luxels 0 1			|	Обрисовка стен сеткой");
			PrintToConsole(client, "mat_showlowresimage 0 1	|	Низкое разрешение текстур");
			PrintToConsole(client, "r_drawportals 0 1			|	Отрисовка порталов");
			PrintToConsole(client, "r_drawdisp 0 1			|	Отрисовка поверхности");
			PrintToConsole(client, "r_drawallrenderables 0 1		|	Отрисовка всего что рендерится");
			PrintToConsole(client, "r_drawclipbrushes 0 1 2		|	Отрисовка клипбрашей");
			PrintToConsole(client, "r_drawdecals 0 1			|	Отрисовка декалей/следов");
			PrintToConsole(client, "r_drawentities 0 1 3		|	Отрисовка энтити");
			PrintToConsole(client, "r_drawlightcache 0 1		|	Отображение глобального света");
			PrintToConsole(client, "r_drawfuncdetail 0 1		|	Отрисовка деталей на карте");
			PrintToConsole(client, "r_drawstaticprops 0 1 2		|	Отрисовка пропов");
			PrintToConsole(client, "----------------------------------------------------------------------------------------------");
			PrintToChat(client, " \x02[CHEATS]\x01 Проверьте консоль!");
			ShowCheatsMenu(client);
		}
	}
	if(option == MenuCancel_ExitBack)
	{
		ShowActionMenu(client);
	}
	if(action == MenuAction_End) 
	{
		CloseHandle(cheatsmenu); 
	}
}

ShowTpMenu(client) {
	new Handle:tpmenu = CreateMenu(TpCallBack);

	SetMenuTitle(tpmenu, "Телепорт:");
	AddMenuItem(tpmenu, "Вернуться обратно", "Вернуться обратно");
	AddMenuItem(tpmenu, "", "", ITEMDRAW_SPACER);
	AddMenuItem(tpmenu, "Выход", "Выход");
	
	SetMenuExitButton(tpmenu, false);
	DisplayMenu(tpmenu, client, 180);
}

public TpCallBack(Handle:tpmenu, MenuAction:action, client, option) {
	if(action == MenuAction_Select) 
	{
		decl String:item[64];
		GetMenuItem(tpmenu, option, item, sizeof(item));
		if(StrEqual(item, "Вернуться обратно")) {
			TeleportEntity(client, posBackup[client], anglesBackup[client], NULL_VECTOR);
			
			//char log[128];
			//Format(log, sizeof(log), " \x10[CORE]\x0B %N\x01 вернулся обратно", client);
			//ShowLog(log);
		}
	}
	if(action == MenuAction_End) 
	{
		CloseHandle(tpmenu); 
	}
}

PrepareToTeleport(client) {
	PrintToChat(client, " \x10[CORE]\x01 Введите координаты:\x06 x y z\x01. Для отмены отправьте\x0F пустое\x01 сообщение!");
	isWaitMsg[client] = true;
}

TeleportPlayer(client, Float:Coords[3]) {

	new Float:posToBackup[3]; 
	GetClientAbsOrigin(client, posToBackup); 
	posBackup[client][0] = posToBackup[0];
	posBackup[client][1] = posToBackup[1];
	posBackup[client][2] = posToBackup[2];
	
	new Float:anglesToBackup[3]; 
	GetClientEyeAngles(client, anglesToBackup);
	anglesBackup[client][0] = anglesToBackup[0];
	anglesBackup[client][1] = anglesToBackup[1];
	anglesBackup[client][2] = anglesToBackup[2];
	
	isWaitMsg[client] = false;
	TeleportEntity(client, Coords, NULL_VECTOR, NULL_VECTOR);
	
	ShowTpMenu(client);
}

SetNoClip(client) {
	//char log[128];
	
	MoveType movetype = GetEntityMoveType(client);
	if (movetype != MOVETYPE_NOCLIP)
	{
		SetEntityMoveType(client, MOVETYPE_NOCLIP);
		//Format(log, sizeof(log), " \x10[CORE]\x0B %N\x01 включил\x04 Silent NoClip", client);
	}
	else
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		//Format(log, sizeof(log), " \x10[CORE]\x0B %N\x01 выключил\x04 Silent NoClip", client);
	}
	//ShowLog(log);
}

SetFlyMode(client) {
	//char log[128];
	
	MoveType movetype = GetEntityMoveType(client);
	if (movetype != MOVETYPE_FLY)
	{
		SetEntityMoveType(client, MOVETYPE_FLY);
		//Format(log, sizeof(log), " \x10[CORE]\x0B %N\x01 включил\x04 Режим Полёта", client);
	}
	else
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		//Format(log, sizeof(log), " \x10[CORE]\x0B %N\x01 выключил\x04 Режим Полёта", client);
	}
	//ShowLog(log);
}

GoToAdminRoom(client){
	ardata.JumpToKey("AdminRooms");
	char cPosition[128], cAngles[128];
	ardata.GetString("position", cPosition, sizeof(cPosition));
	ardata.GetString("angles", cAngles, sizeof(cAngles));

	decl String:sCoords[3][8]; 
	ExplodeString(cPosition, " ", sCoords, 3, 8);
	new Float:Coords[3];
	Coords[0] = StringToFloat(sCoords[0]);
	Coords[1] = StringToFloat(sCoords[1]); 
	Coords[2] = StringToFloat(sCoords[2]) - 44;
		
	decl String:sAngles[2][8]; 
	ExplodeString(cAngles, " ", sAngles, 2, 8);
	new Float:Angles[3];
	Angles[0] = StringToFloat(sAngles[0]);
	Angles[1] = StringToFloat(sAngles[1]);
	
	new Float:posToBackup[3]; 
	GetClientAbsOrigin(client, posToBackup); 
	arPosBackup[client][0] = posToBackup[0];
	arPosBackup[client][1] = posToBackup[1];
	arPosBackup[client][2] = posToBackup[2];
	
	new Float:anglesToBackup[3]; 
	GetClientEyeAngles(client, anglesToBackup);
	arAnglesBackup[client][0] = anglesToBackup[0];
	arAnglesBackup[client][1] = anglesToBackup[1];
	arAnglesBackup[client][2] = anglesToBackup[2];

	TeleportEntity(client, Coords, Angles, NULL_VECTOR);
	
	ardata.Rewind();
	
	ShowAdminRoomMenu(client);
	
	char log[128];
	Format(log, sizeof(log), " \x10[CORE]\x0B %N\x01 перешел в\x04 AdminRoom", client);
	ShowLog(log);
}

ShowAdminRoomMenu(client) {
	new Handle:armenu = CreateMenu(AdminRoomCallBack);

	SetMenuTitle(armenu, "AdminRoom:");
	AddMenuItem(armenu, "Вернуться обратно", "Вернуться обратно");
	AddMenuItem(armenu, "", "", ITEMDRAW_SPACER);
	AddMenuItem(armenu, "Закрыть", "Закрыть");
	
	SetMenuExitButton(armenu, false);
	DisplayMenu(armenu, client, 180);
}

public AdminRoomCallBack(Handle:armenu, MenuAction:action, client, option) {
	if(action == MenuAction_Select) 
	{
		decl String:item[64];
		GetMenuItem(armenu, option, item, sizeof(item));
		if(StrEqual(item, "Вернуться обратно")) {
			TeleportEntity(client, arPosBackup[client], arAnglesBackup[client], NULL_VECTOR);
			
			char log[128];
			Format(log, sizeof(log), " \x10[CORE]\x0B %N\x01 вернулся из\x04 AdminRoom", client);
			ShowLog(log);
		}
	}
	if(action == MenuAction_End) 
	{
		CloseHandle(armenu); 
	}
}

OpenSmartAdminRoom(client){
	new Handle:smartarmenu = CreateMenu(SmartAdminRoomCallBack);
	SetMenuTitle(smartarmenu, "Smart AdminRoom:");
	
	new i = 0;
	new String:sIndex[4];
	
	while(i <= 16)
	{
		IntToString(i, sIndex, sizeof(sIndex));
		ardata.JumpToKey("AdminRooms");
		if(ardata.JumpToKey(sIndex))
		{
			char buttonName[128];
			ardata.GetString("name", buttonName, sizeof(buttonName));
			char buttonHid[128];
			ardata.GetString("hammerID", buttonHid, sizeof(buttonHid));
			AddMenuItem(smartarmenu, buttonHid, buttonName);
		}
		i++;
		ardata.Rewind();
	}
	AddMenuItem(smartarmenu, "Завершить раунд", "Завершить раунд");
	
	SetMenuExitBackButton(smartarmenu, true);
	SetMenuExitButton(smartarmenu, true);
	DisplayMenu(smartarmenu, client, 180);
}

public SmartAdminRoomCallBack(Handle:smartarmenu, MenuAction:action, client, option) {
	if(action == MenuAction_Select) 
	{
		decl String:item[32];
		GetMenuItem(smartarmenu, option, item, sizeof(item));
		
		if(StrEqual(item, "Завершить раунд")) {
			CS_TerminateRound(4.0, CSRoundEnd_Draw);
			char log[128];
			Format(log, sizeof(log), " \x10[CORE]\x0B %N\x04 завершил раунд", client);
			ShowLog(log);
		}
		else {
			int savedHID = StringToInt(item);
			new index;
			
			while((index = FindEntityByClassname(index, "func_button")) != -1) 
			{
				int newHID = GetEntProp(index, Prop_Data, "m_iHammerID");
			
				if(savedHID == newHID) AcceptEntityInput(index, "Press", client);
			}
		}
		OpenSmartAdminRoom(client);
	}
	if(option == MenuCancel_ExitBack)
	{
		ShowMapMenu(client);
	}
	if(action == MenuAction_End) 
	{
		CloseHandle(smartarmenu); 
	}
}

TerminateRound(client) {
	new Handle:termmenu = CreateMenu(TerminateCallBack);

	SetMenuTitle(termmenu, "Завершить раунд:");
	AddMenuItem(termmenu, "CSRoundEnd_CTWin", "Победа людей");
	AddMenuItem(termmenu, "CSRoundEnd_TerroristWin", "Победа зомби");
	AddMenuItem(termmenu, "CSRoundEnd_Draw", "Ничья");

	SetMenuExitBackButton(termmenu, true);
	SetMenuExitButton(termmenu, true);
	DisplayMenu(termmenu, client, 180);
}

public TerminateCallBack(Handle:termmenu, MenuAction:action, client, option) {
	if(action == MenuAction_Select) 
	{
		if(option == 0)
		{
			CS_TerminateRound(4.0, CSRoundEnd_CTWin);
			
			int teamscore = GetTeamScore(CS_TEAM_CT) + 1;
			SetTeamScore(CS_TEAM_CT, teamscore);
			CS_SetTeamScore(CS_TEAM_CT, teamscore);
		}
		if(option == 1) CS_TerminateRound(4.0, CSRoundEnd_TerroristWin);
		if(option == 2) CS_TerminateRound(4.0, CSRoundEnd_Draw);
		
		char log[128];
		Format(log, sizeof(log), " \x10[CORE]\x0B %N\x04 завершил раунд", client);
		ShowLog(log);

	}
	if(option == MenuCancel_ExitBack)
	{
		ShowMapMenu(client);
	}
	if(action == MenuAction_End) 
	{
		CloseHandle(termmenu); 
	}
}

ShowGhostMenu(client) {
	new Handle:ghostmenu = CreateMenu(GhostCallBack);

	SetMenuTitle(ghostmenu, "Ghost Mode:");
	
	if(GetEntProp(client, Prop_Data, "m_CollisionGroup") == 1)
		AddMenuItem(ghostmenu, "Выключить Ghost", "Выключить Ghost");
	else
		AddMenuItem(ghostmenu, "Включить Ghost", "Включить Ghost");

	AddMenuItem(ghostmenu, "", "", ITEMDRAW_SPACER);
	AddMenuItem(ghostmenu, "", "", ITEMDRAW_SPACER);
	AddMenuItem(ghostmenu, "", "В режиме Ghost вы будете невидимым для карты", ITEMDRAW_DISABLED);
	AddMenuItem(ghostmenu, "", "Триггеры не будут на вас срабатывать", ITEMDRAW_DISABLED);
	AddMenuItem(ghostmenu, "", "Вы не сможете получать урон и телепортироваться", ITEMDRAW_DISABLED);
	
	SetMenuExitBackButton(ghostmenu, true);
	SetMenuExitButton(ghostmenu, true);
	DisplayMenu(ghostmenu, client, 180);
}

public GhostCallBack(Handle:ghostmenu, MenuAction:action, client, option) {
	if(action == MenuAction_Select) 
	{
		char log[128];
		if(GetEntProp(client, Prop_Data, "m_CollisionGroup") == 1)
		{
			SetEntProp(client, Prop_Data, "m_CollisionGroup", 5);
			//PrintToChat(client, " \x10[CORE]\x08 Ghost\x01 режим\x07 выключен");
			Format(log, sizeof(log), " \x10[CORE]\x0B %N\x07 выключил\x08 Ghost\x01 режим", client);
			ShowGhostMenu(client);
		}
		else
		{
			SetEntProp(client, Prop_Data, "m_CollisionGroup", 1);
			//PrintToChat(client, " \x10[CORE]\x08 Ghost\x01 режим\x06 включен");
			Format(log, sizeof(log), " \x10[CORE]\x0B %N\x06 включил\x08 Ghost\x01 режим", client);
			ShowGhostMenu(client);
		}
		ShowLog(log);
	}
	if(option == MenuCancel_ExitBack)
	{
		ShowActionMenu(client);
	}
	if(action == MenuAction_End) 
	{
		CloseHandle(ghostmenu); 
	}
}

ShowIntangibleMenu(client) {
	new Handle:godmenu = CreateMenu(IntangibleCallBack);

	SetMenuTitle(godmenu, "Intangible Mode:");
	
	if(GetEntProp(client, Prop_Data, "m_nSolidType") == 5)
		AddMenuItem(godmenu, "", "Выключить Intangible");
	else
		AddMenuItem(godmenu, "", "Включить Intangible");

	AddMenuItem(godmenu, "", "", ITEMDRAW_SPACER);
	AddMenuItem(godmenu, "", "", ITEMDRAW_SPACER);
	AddMenuItem(godmenu, "", "В режиме Intangible вас не смогут заразить", ITEMDRAW_DISABLED);
	AddMenuItem(godmenu, "", "Пули будут пролетать сквозь вас", ITEMDRAW_DISABLED);
	
	SetMenuExitBackButton(godmenu, true);
	SetMenuExitButton(godmenu, true);
	DisplayMenu(godmenu, client, 180);
}

public IntangibleCallBack(Handle:godmenu, MenuAction:action, client, option) {
	if(action == MenuAction_Select) 
	{
		char log[128];
		if(GetEntProp(client, Prop_Data, "m_nSolidType") == 5)
		{
			SetEntProp(client, Prop_Data, "m_nSolidType", 2);
			//PrintToChat(client, " \x10[CORE]\x08 Ghost\x01 режим\x07 выключен");
			Format(log, sizeof(log), " \x10[CORE]\x0B %N\x07 выключил\x08 Intangible\x01 режим", client);
			ShowIntangibleMenu(client);
		}
		else
		{
			SetEntProp(client, Prop_Data, "m_nSolidType", 5);
			//PrintToChat(client, " \x10[CORE]\x08 Ghost\x01 режим\x06 включен");
			Format(log, sizeof(log), " \x10[CORE]\x0B %N\x06 включил\x08 Intangible\x01 режим", client);
			ShowIntangibleMenu(client);
		}
		ShowLog(log);
	}
	if(option == MenuCancel_ExitBack)
	{
		ShowActionMenu(client);
	}
	if(action == MenuAction_End) 
	{
		CloseHandle(godmenu); 
	}
}

//================================================================================================

ShowSilentSlapMenu(client)
{
	new Handle:silentslapmenu = CreateMenu(SilentSlapCallBack);

	SetMenuTitle(silentslapmenu, "Шлёпнуть игрока:");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			char Name[64] = "", index[8] = "";
			
			Format(Name, 64, "%N", i);
			Format(index, 64, "%i", i);
			
			AddMenuItem(silentslapmenu, index, Name);
		}
	}
	
	SetMenuExitButton(silentslapmenu, true);
	DisplayMenu(silentslapmenu, client, 180);
}

public SilentSlapCallBack(Handle:silentslapmenu, MenuAction:action, client, option) {
	if(action == MenuAction_Select) 
	{
		decl String:item[64];
		GetMenuItem(silentslapmenu, option, item, sizeof(item));
		
		int target = StringToInt(item);
		
		if(IsClientInGame(target) && IsPlayerAlive(target)) SlapPlayer(target, 0);
		
		char log[128];
		Format(log, sizeof(log), " \x10[CORE]\x0B %N\x06 тихо шлёпнул игрока\x0B %N", client, target);
		ShowLogRoot(log);
		
		ShowSilentSlapMenu(client);
	}
	if(option == MenuCancel_ExitBack) ShowPlayerControlMenu(client);
	if(action == MenuAction_End) CloseHandle(silentslapmenu); 
}

ShowLog(String:log[]) {
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && CheckCommandAccess(i, "", ADMFLAG_UNBAN, true))
		{
			PrintToChat(i, "%s", log);
		}
	}
}

ShowLogRoot(String:log[]) {
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && CheckCommandAccess(i, "", ADMFLAG_ROOT, true))
		{
			PrintToChat(i, "%s", log);
		}
	}
}