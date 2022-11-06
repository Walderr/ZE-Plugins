#include <cstrike>

bool alreadyWon[MAXPLAYERS+1];

public void OnPluginStart()
{
	RegAdminCmd("sm_random", Command_Random, ADMFLAG_BAN);
	RegAdminCmd("sm_testrandom", Command_TestRandom, ADMFLAG_BAN);
}

public void OnMapStart()
{
	for(int i = 1; i <= MaxClients; i++) alreadyWon[i] = false;
}

public Action Command_Random(int client, int args)
{
	CreateTimer(0.1, Timer_PrintCalculation);
	CreateTimer(1.5, Timer_PrintWinner);
	
	return Plugin_Handled;
}

public Action Timer_PrintCalculation(Handle timer)
{
	PrintToChatAll(" \x03[Random] \x0BCalculation...");
}

public Action Timer_PrintWinner(Handle timer)
{
	int players = 0, index[MAXPLAYERS+1];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && !alreadyWon[i] && CS_GetClientContributionScore(i) > 10)
		{
			players++;
			index[players] = i;
		}
	}
	
	if(!players)
	{
		PrintToChatAll(" \x03[Random] \x0BNo matching players!");
		return;
	}
	
	int winner = index[GetRandomInt(1, players)];

	alreadyWon[winner] = true;
	
	PrintToChatAll(" \x03[Random] \x0BThe winner is \x09%N", winner);
	
	return;
}

//============================================================

public Action Command_TestRandom(int client, int args)
{
	int players = 0, index[MAXPLAYERS+1];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && !alreadyWon[i] && CS_GetClientContributionScore(i) > 10)
		{
			players++;
			index[players] = i;
		}
	}
	
	if(!players)
	{
		PrintToChat(client, " \x03[Random Test] \x0BНет подходящих игроков!");
		return Plugin_Handled;
	}
	
	int winner = index[GetRandomInt(1, players)];

	PrintToChat(client, " \x03[Random Test] \x0BПобедителем бы стал \x09%N", winner);
	
	return Plugin_Handled;
}
