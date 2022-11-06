#include <sdktools>
#include <cstrike>

int primary = 0;
int secondary = 1;

int heOffset = 14;
int molotovOffset = 17;

public Plugin:myinfo =
{
    name = "Zbuy",
    author = "Walderr, sExtr1m",
    description = "Позволяет покупать оружие по командам",
    version = "1.2"
};

public OnPluginStart()
{
	// Пистолеты
	RegConsoleCmd("sm_glock", buy_glock);
	RegConsoleCmd("sm_p2000", buy_hkp2000);
	RegConsoleCmd("sm_hkp2000", buy_hkp2000);
	RegConsoleCmd("sm_usp", buy_usp_silencer);
	RegConsoleCmd("sm_usp-s", buy_usp_silencer);
	RegConsoleCmd("sm_usp_silencer", buy_usp_silencer);
	RegConsoleCmd("sm_elite", buy_elite);
	RegConsoleCmd("sm_p250", buy_p250);
	RegConsoleCmd("sm_cz75", buy_cz75a);
	RegConsoleCmd("sm_cz75a", buy_cz75a);
	RegConsoleCmd("sm_tec9", buy_tec9);
	RegConsoleCmd("sm_fiveseven", buy_fiveseven);
	RegConsoleCmd("sm_deagle", buy_deagle);
	RegConsoleCmd("sm_revolver", buy_revolver);
	RegConsoleCmd("sm_r8", buy_revolver);
	
	// Тяжелое оружие
	RegConsoleCmd("sm_nova", buy_nova);
	RegConsoleCmd("sm_xm1014", buy_xm1014);
	RegConsoleCmd("sm_sawedoff", buy_sawedoff);
	RegConsoleCmd("sm_mag7", buy_mag7);
	RegConsoleCmd("sm_m249", buy_m249);
	RegConsoleCmd("sm_negev", buy_negev);
	
	// Скорострельное оружие
	RegConsoleCmd("sm_mac10", buy_mac10);
	RegConsoleCmd("sm_mp9", buy_mp9);
	RegConsoleCmd("sm_mp5", buy_mp5sd);
	RegConsoleCmd("sm_mp5sd", buy_mp5sd);
	RegConsoleCmd("sm_mp7", buy_mp7);
	RegConsoleCmd("sm_ump45", buy_ump45);
	RegConsoleCmd("sm_p90", buy_p90);
	RegConsoleCmd("sm_bizon", buy_bizon);
	
	// Винтовки
	RegConsoleCmd("sm_galil", buy_galilar);
	RegConsoleCmd("sm_galilar", buy_galilar);
	RegConsoleCmd("sm_famas", buy_famas);
	RegConsoleCmd("sm_ak47", buy_ak47);
	RegConsoleCmd("sm_m4a1", buy_m4a1_silencer);
	RegConsoleCmd("sm_m4a1s", buy_m4a1_silencer);
	RegConsoleCmd("sm_m4a1-s", buy_m4a1_silencer);
	RegConsoleCmd("sm_m4a1_silencer", buy_m4a1_silencer);
	RegConsoleCmd("sm_m4a4", buy_m4a4);
	RegConsoleCmd("sm_ssg08", buy_ssg08);
	RegConsoleCmd("sm_sg553", buy_sg556);
	RegConsoleCmd("sm_sg556", buy_sg556);
	RegConsoleCmd("sm_aug", buy_aug);
	RegConsoleCmd("sm_awp", buy_awp);
	RegConsoleCmd("sm_g3sg1", buy_g3sg1);
	RegConsoleCmd("sm_scar", buy_scar20);
	RegConsoleCmd("sm_scar20", buy_scar20);
	
	// Броня
	RegConsoleCmd("sm_kevlar", buy_kevlar);
	
	// Гранаты
	RegConsoleCmd("sm_he", buy_hegrenade);
	RegConsoleCmd("sm_mol", buy_molotov);
	RegConsoleCmd("sm_molotov", buy_molotov);
	
	// ZBuy
	RegConsoleCmd("sm_zbuy", ZBuyMenu);
	RegConsoleCmd("sm_zmarket", ZBuyMenu);
	RegConsoleCmd("zmarket", ZBuyMenu);
	
	LoadTranslations("zbuy.phrases");
}

public Action buy_glock(int client, int args){ BuyWeapon(client, "weapon_glock", 200, secondary); }
public Action buy_hkp2000(int client, int args){ BuyWeapon(client, "weapon_hkp2000", 200, secondary); }
public Action buy_usp_silencer(int client, int args){ BuyWeapon(client, "weapon_usp_silencer", 200, secondary); }
public Action buy_elite(int client, int args){ BuyWeapon(client, "weapon_elite", 400, secondary); }
public Action buy_p250(int client, int args){ BuyWeapon(client, "weapon_p250", 300, secondary); }
public Action buy_cz75a(int client, int args){ BuyWeapon(client, "weapon_cz75a", 500, secondary); }
public Action buy_tec9(int client, int args){ BuyWeapon(client, "weapon_tec9", 500, secondary); }
public Action buy_fiveseven(int client, int args){ BuyWeapon(client, "weapon_fiveseven", 500, secondary); }
public Action buy_deagle(int client, int args){ BuyWeapon(client, "weapon_deagle", 700, secondary); }
public Action buy_revolver(int client, int args){ BuyWeapon(client, "weapon_revolver", 600, secondary); }

public Action buy_nova(int client, int args){ BuyWeapon(client, "weapon_nova", 1200, primary); }
public Action buy_xm1014(int client, int args){ BuyWeapon(client, "weapon_xm1014", 2000, primary); }
public Action buy_sawedoff(int client, int args){ BuyWeapon(client, "weapon_sawedoff", 1200, primary); }
public Action buy_mag7(int client, int args){ BuyWeapon(client, "weapon_mag7", 1800, primary); }
public Action buy_m249(int client, int args){ BuyWeapon(client, "weapon_m249", 5200, primary); }
public Action buy_negev(int client, int args){ BuyWeapon(client, "weapon_negev", 3400, primary); }

public Action buy_mac10(int client, int args){ BuyWeapon(client, "weapon_mac10", 1050, primary); }
public Action buy_mp9(int client, int args){ BuyWeapon(client, "weapon_mp9", 1250, primary); }
public Action buy_mp5sd(int client, int args){ BuyWeapon(client, "weapon_mp5sd", 1500, primary); }
public Action buy_mp7(int client, int args){ BuyWeapon(client, "weapon_mp7", 1500, primary); }
public Action buy_ump45(int client, int args){ BuyWeapon(client, "weapon_ump45", 1200, primary); }
public Action buy_p90(int client, int args){ BuyWeapon(client, "weapon_p90", 2350, primary); }
public Action buy_bizon(int client, int args){ BuyWeapon(client, "weapon_bizon", 1400, primary); }

public Action buy_galilar(int client, int args){ BuyWeapon(client, "weapon_galilar", 2000, primary); }
public Action buy_famas(int client, int args){ BuyWeapon(client, "weapon_famas", 2250, primary); }
public Action buy_ak47(int client, int args){ BuyWeapon(client, "weapon_ak47", 2700, primary); }
public Action buy_m4a1_silencer(int client, int args){ BuyWeapon(client, "weapon_m4a1_silencer", 3100, primary); }
public Action buy_m4a4(int client, int args){ BuyWeapon(client, "weapon_m4a4", 3100, primary); }
public Action buy_ssg08(int client, int args){ BuyWeapon(client, "weapon_ssg08", 1700, primary); }
public Action buy_sg556(int client, int args){ BuyWeapon(client, "weapon_sg556", 2750, primary); }
public Action buy_aug(int client, int args){ BuyWeapon(client, "weapon_aug", 3150, primary); }
public Action buy_awp(int client, int args){ BuyWeapon(client, "weapon_awp", 4750, primary); }
public Action buy_g3sg1(int client, int args){ BuyWeapon(client, "weapon_g3sg1", 5000, primary); }
public Action buy_scar20(int client, int args){ BuyWeapon(client, "weapon_scar20", 5000, primary); }

public Action buy_kevlar(int client, int args){ BuyKevlar(client, 600); }

public Action buy_hegrenade(int client, int args){ BuyGrenade(client, "weapon_hegrenade", 5000); }
public Action buy_molotov(int client, int args){ BuyGrenade(client, "weapon_molotov", 6000); }

public Action ZBuyMenu(int client, int args) { Display_ZBuyMenu(client); }

Display_ZBuyMenu(client) 
{
	if(!IsClientInGame(client)) return;
	
	Menu hMenu = CreateMenu(MenuHandle_ZBuyMenu, MENU_ACTIONS_DEFAULT | MenuAction_DisplayItem);
	
	int money = GetEntProp(client, Prop_Send, "m_iAccount");
	SetMenuTitle(hMenu, "%T", "Menu_MainTitle", client, money);
	
	hMenu.AddItem("PrimaryWeapons", "Primary Weapons");
	hMenu.AddItem("SecondaryWeapons", "Secondary Weapons");
	hMenu.AddItem("", "", ITEMDRAW_SPACER);
	hMenu.AddItem("Equipment", "Equipment");
	
	hMenu.ExitButton = true;

	hMenu.Display(client, 90);
}

public MenuHandle_ZBuyMenu(Handle:hMenu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select) 
	{		
		switch (option)
		{
			case 0: Display_PrimaryWeaponMenu(client);
			case 1: Display_SecondaryWeaponMenu(client);
			case 3: Display_EquipmentMenu(client);
		}
	}
	else if(action == MenuAction_DisplayItem)
	{
		char sBuffer[128];
		switch (option)
		{
			case 0:FormatEx(sBuffer, sizeof(sBuffer), "%T", "Menu_PrimaryWeapons", client);
			case 1:FormatEx(sBuffer, sizeof(sBuffer), "%T", "Menu_SecondaryWeapons", client);
			case 3:FormatEx(sBuffer, sizeof(sBuffer), "%T", "Menu_Equipment", client);
		}
		return RedrawMenuItem(sBuffer);
	}
	else if (action == MenuAction_End) {
		CloseHandle(hMenu);
	}
	
	return 0;
}

Display_PrimaryWeaponMenu(client) 
{
	Menu hMenu = CreateMenu(MenuHandle_PrimaryWeaponMenu, MENU_ACTIONS_DEFAULT);
	
	int money = GetEntProp(client, Prop_Send, "m_iAccount");
	SetMenuTitle(hMenu, "%T", "Menu_PrimaryTitle", client, money);
	
	// Сортировка по популярности.
	hMenu.AddItem("sm_bizon", "!bizon [$1400]");
	hMenu.AddItem("sm_negev", "!negev [$3400]");
	hMenu.AddItem("sm_m249", "!m249 [$5200]");
	hMenu.AddItem("sm_p90", "!p90 [$2350]");
	hMenu.AddItem("sm_ak47", "!ak47 [$2700]");
	hMenu.AddItem("sm_m4a1", "!m4a1 [$3100]");
	
	hMenu.AddItem("sm_mac10", "!mac10 [$1050]");
	hMenu.AddItem("sm_mp9", "!mp9 [$1250]");
	hMenu.AddItem("sm_mp5sd", "!mp5sd [$1500]");
	hMenu.AddItem("sm_mp7", "!mp7 [1500]");
	hMenu.AddItem("sm_ump45", "!ump45 [$1200]");
	hMenu.AddItem("sm_m4a4", "!m4a4 [$3100]");
	
	hMenu.AddItem("sm_galilar", "!galilar [$2000]");
	hMenu.AddItem("sm_famas", "!famas [$2250]");
	hMenu.AddItem("sm_sg553", "!sg553 [$2750]");
	hMenu.AddItem("sm_aug", "!aug [$3150]");
	hMenu.AddItem("sm_nova", "!nova [$1200]");
	hMenu.AddItem("sm_xm1014", "!xm1014 [$2000]");
	
	hMenu.AddItem("sm_sawedoff", "!sawedoff [$1200]");
	hMenu.AddItem("sm_mag7", "!mag7 [$1800]");
	hMenu.AddItem("sm_ssg08", "!ssg08 [$1700]");
	hMenu.AddItem("sm_awp", "!awp [$4750]");
	hMenu.AddItem("sm_g3sg1", "!g3sg1 [$5000]");
	hMenu.AddItem("sm_scar20", "!scar20 [$5000]");
	
	hMenu.ExitBackButton = true;

	hMenu.Display(client, 90);
}

public MenuHandle_PrimaryWeaponMenu(Handle:hMenu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select) 
	{
		char weapon[64];
		GetMenuItem(hMenu, option, weapon, sizeof(weapon));
		FakeClientCommand(client, weapon);
	}
	else if(option == MenuCancel_ExitBack)
	{
		Display_ZBuyMenu(client);
	}
	else if(action == MenuAction_End) {
		CloseHandle(hMenu);
	}
}  

Display_SecondaryWeaponMenu(client) 
{
	Menu hMenu = CreateMenu(MenuHandle_SecondaryWeaponMenu, MENU_ACTIONS_DEFAULT);
	
	int money = GetEntProp(client, Prop_Send, "m_iAccount");
	SetMenuTitle(hMenu, "%T", "Menu_SecondaryTitle", client, money);
	
	// Сортировка по популярности.
	hMenu.AddItem("sm_elite", "!elite [$400]");
	hMenu.AddItem("sm_tec9", "!tec9 [$500]");
	hMenu.AddItem("sm_deagle", "!deagle [$700]");
	hMenu.AddItem("sm_fiveseven", "!fiveseven [$500]");
	hMenu.AddItem("sm_p250", "!p250 [$300]");
	hMenu.AddItem("sm_p2000", "!p2000 [$200]");
	
	hMenu.AddItem("sm_glock", "!glock [$200]");
	hMenu.AddItem("sm_revolver", "!revolver [$600]");
	hMenu.AddItem("sm_usp", "!usp [$200]");
	hMenu.AddItem("sm_cz75", "!cz75 [$500]");
	
	hMenu.ExitBackButton = true;

	hMenu.Display(client, 90);
}

public MenuHandle_SecondaryWeaponMenu(Handle:hMenu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select) 
	{		
		char weapon[64];
		GetMenuItem(hMenu, option, weapon, sizeof(weapon));
		FakeClientCommand(client, weapon);
	}
	else if(option == MenuCancel_ExitBack)
	{
		Display_ZBuyMenu(client);
	}
	else if (action == MenuAction_End) {
		CloseHandle(hMenu);
	}
}

Display_EquipmentMenu(client) 
{
	Menu hMenu = CreateMenu(MenuHandle_EquipmentMenu, MENU_ACTIONS_DEFAULT);
	
	int money = GetEntProp(client, Prop_Send, "m_iAccount");
	SetMenuTitle(hMenu, "%T", "Menu_EquipmentTitle", client, money); // "ZBuy Menu - Equpment\nMoney: $%i\n"
	
	hMenu.AddItem("sm_kevlar", "!kevlar [$600]");
	hMenu.AddItem("sm_he", "!he [$5000]");
	hMenu.AddItem("sm_molotov", "!molotov [$6000]");

	hMenu.ExitBackButton = true;

	hMenu.Display(client, 90);
}

public MenuHandle_EquipmentMenu(Handle:hMenu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select) 
	{		
		char weapon[64];
		GetMenuItem(hMenu, option, weapon, sizeof(weapon));
		FakeClientCommand(client, weapon);
	}
	else if(option == MenuCancel_ExitBack)
	{
		Display_ZBuyMenu(client);
	}
	else if (action == MenuAction_End) {
		CloseHandle(hMenu);
	}
}

BuyWeapon(int client, const char[] weapon, int price, int type)
{
	if(!IsClientInGame(client)) return;
	
	else if(GetClientTeam(client) != CS_TEAM_CT) {
		PrintToChat(client, "%t", "CantBuyWeapon"); // Вы не можете покупать оружие
		return;
	}
	else if(!IsPlayerAlive(client)) {
		PrintToChat(client, "%t", "MustBeAlive"); // Вы должны быть живы
		return;
	}

	int money = GetEntProp(client, Prop_Send, "m_iAccount");
	
	if(money < price) {
		PrintToChat(client, "%t", "NotEnoughMoney"); // У вас недостаточно денег
		return;
	}
	
	int slot = GetPlayerWeaponSlot(client, type);
	if(slot != -1) CS_DropWeapon(client, slot, false);
	
	SetEntProp(client, Prop_Send, "m_iAccount", money - price);
	GivePlayerItem(client, weapon);
}

BuyKevlar(int client, int price)
{
	if(!IsClientInGame(client)) return;
	
	if(GetClientTeam(client) != CS_TEAM_CT) {
		PrintToChat(client, "%t", "CantBuyArmor"); // Вы не можете покупать броню
		return;
	}
	if(!IsPlayerAlive(client)) {
		PrintToChat(client, "%t", "MustBeAlive"); // Вы должны быть живы
		return;
	}
	
	int money = GetEntProp(client, Prop_Send, "m_iAccount");
	
	if(money < price) {
		PrintToChat(client, "%t", "NotEnoughMoney"); // У вас недостаточно денег
		return;
	}

	if(GetClientArmor(client) < 100)
	{
		SetEntProp(client, Prop_Send, "m_iAccount", money - price);
		
		SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
		
		if(GetEntProp(client, Prop_Send, "m_bHasHelmet") == 0)
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
	}
	else PrintToChat(client, "%t", "MaxArmor"); // У вас максимальное количество брони
}

BuyGrenade(int client, const char[] weapon, int price)
{
	if(!IsClientInGame(client)) return;
	
	else if(GetClientTeam(client) != CS_TEAM_CT) {
		PrintToChat(client, "%t", "CantBuyGrenade"); // Вы не можете покупать гранаты
		return;
	}
	else if(!IsPlayerAlive(client)) {
		PrintToChat(client, "%t", "MustBeAlive"); // Вы должны быть живы
		return;
	}

	int money = GetEntProp(client, Prop_Send, "m_iAccount");
	
	if(money < price) {
		PrintToChat(client, "%t", "NotEnoughMoney"); // У вас недостаточно денег
		return;
	}
	
	int grenadeCount;
	
	if(StrEqual(weapon, "weapon_hegrenade")) grenadeCount = GetEntProp(client, Prop_Send, "m_iAmmo", _, heOffset);
	else if(StrEqual(weapon, "weapon_molotov")) grenadeCount = GetEntProp(client, Prop_Send, "m_iAmmo", _, molotovOffset);
		
	if(grenadeCount > 0)
	{
		PrintToChat(client, "%t", "AlreadyHaveGrenade"); // У вас уже есть эта граната
		return;
	}
	
	SetEntProp(client, Prop_Send, "m_iAccount", money - price);
	GivePlayerItem(client, weapon);
}
