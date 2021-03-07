#pragma semicolon 1
#include <sourcemod>

#include <sdkhooks>
#include <timers>

#pragma newdecls required

#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf_custom_attributes>
#include <tf_cattr_lunch_effect>

#include <stocksoup/var_strings>
#include <custom_status_hud>

float g_flBuffEndTime[MAXPLAYERS + 1];


public void OnMapStart() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client) {
	g_flBuffEndTime[client] = 0.0;
}

void OnCustomDrinkHandlerAvailable() {
	TF2CustomAttrDrink_Register("stealth effect", ApplyStealthEffect);
}

public void ApplyStealthEffect(int owner, int weapon, const char[] effectName) {
	if (!IsValidEntity(weapon)) {
		return;
	}
	
	char attr[256];
	TF2CustAttr_GetString(weapon, "stealth effect drink properties", attr, sizeof(attr));
	
	float flStealthDuration = ReadFloatVar(attr, "stealth_duration", 0.0);
	float flMark = ReadFloatVar(attr, "mark", 0.0);
	float flSpeedDuration = ReadFloatVar(attr, "speed_duration", 0.0);
	
	TF2_AddCondition(owner, TFCond:64, flStealthDuration);
	
	if(flMark != 0.0){
		TF2_AddCondition(owner, TFCond:48, flStealthDuration);
	}
	
	DataPack pack;
	CreateDataTimer(flStealthDuration, ApplySpeedEffect, pack);
	pack.WriteCell(owner);
	pack.WriteFloat(flSpeedDuration);
	
}

public Action ApplySpeedEffect(Handle timer, DataPack pack) {

	pack.Reset();
	int owner = pack.ReadCell();
	float flSpeedDuration = pack.ReadFloat();
	TF2_AddCondition(owner, TFCond:32, flSpeedDuration);

}

public void OnLibraryAdded(const char[] name) {
	if (StrEqual(name, "cattr-custom-drink")) {
		OnCustomDrinkHandlerAvailable();
	}
}

public Action OnCustomStatusHUDUpdate(int client, StringMap entries) {
	if (g_flBuffEndTime[client] > GetGameTime()) {
		char buffer[64];
		Format(buffer, sizeof(buffer), "Stealth: %.0fs",
				g_flBuffEndTime[client] - GetGameTime());
		
		entries.SetString("mod_stealth_effect", buffer);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
