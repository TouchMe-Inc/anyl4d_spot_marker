
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>


public Plugin myinfo = {
    name        = "Spot Marker",
    author      = "Mart, TouchMe",
    description = "Allow teammates to create spot markers visible only to them",
    version     = "build_0000",
    url         = "https://github.com/TouchMe-Inc/anyl4d_spot_marker"
}

/*
 * Filenames.
 */
#define TRANSLATIONS                 "spot_marker.phrases"

/*
 * Distance const.
 */
#define MIN_DIST                     100.0
#define MAX_DIST                     2000.0
#define MIN_SCALE                    0.3
#define MAX_SCALE                    2.0

/*
 * Sprite classname.
 */
#define ENTITY_MARKER_CLASS          "spot_marker"

/*
 * Teams.
 */
#define TEAM_SPECTATOR                1
#define TEAM_SURVIVOR                 2
#define TEAM_INFECTED                 3

/*
 *
 */
#define ENTITY_WORLDSPAWN             0

/*
 * Max size.
 */
#define MAXENTITIES                   2048


/* sm_spot_marker_duration */
ConVar g_cvDuration = null;
float g_fDuration = 0.0;

/* sm_spot_marker_cooldown */
ConVar g_cvCooldown = null;
float g_fCooldown = 0.0;

/* sm_spot_marker_sound */
ConVar g_cvSound;
bool g_bSound;
char g_szSound[PLATFORM_MAX_PATH];

/* sm_spot_marker_msg */
ConVar g_cvMessage;
bool g_bMessage;

/* sm_spot_marker_alive_only */
ConVar g_cvAliveOnly;
bool g_bAliveOnly;

/* sm_spot_marker_sprite_model */
ConVar g_cvSpriteModel;
char g_szSpriteModel[PLATFORM_MAX_PATH];

/* sm_spot_marker_sprite_color */
ConVar g_cvSpriteColor;
char g_szSpriteColor[12];

/* sm_spot_marker_sprite_alpha */
ConVar g_cvSpriteAlpha;
int g_iSpriteAlpha;

/* sm_spot_marker_sprite_alpha */
ConVar g_cvSpriteFadeDistance;
int g_iSpriteFadeDistance;

/* sm_spot_marker_sprite_z_axis */
ConVar g_cvSpriteZAxis;
float g_fSpriteZAxis;

/* sm_spot_marker_sprite_speed */
ConVar g_cvSpriteSpeed;
float g_fSpriteSpeed;
bool g_bSpriteSpeed;

/* sm_spot_marker_sprite_min_max */
ConVar g_cvSpriteMinMax;
float g_fSpriteMinMax;
bool g_bSpriteMinMax;


float g_fLastTime[MAXPLAYERS + 1];
int g_iClientEntityRef[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_iEntityOwner[MAXENTITIES + 1];


public APLRes AskPluginLoad2(Handle myself, bool bLateLoad, char[] szError, int szErrorLen)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(szError, szErrorLen, "This plugin only support in \"Left 4 Dead\" and \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations(TRANSLATIONS);

    /*
     *
     */
    g_cvDuration           = CreateConVar("sm_spot_marker_duration",             "3.0",                    "Duration (seconds) of the spot marker", .hasMin = true, .min = 0.0);
    g_cvCooldown           = CreateConVar("sm_spot_marker_cooldown",             "1.0",                    "Cooldown (seconds) to use the spot marker", .hasMin = true, .min = 0.0);
    g_cvSound              = CreateConVar("sm_spot_marker_sound",                "ui/alert_clink.wav",     "Path to sound.\nEmpty = OFF");
    g_cvMessage            = CreateConVar("sm_spot_marker_message",              "1",                      "Display message.\n0 = OFF, 1 = CHAT", _, true, 0.0, true, 1.0);
    g_cvAliveOnly          = CreateConVar("sm_spot_marker_alive_only",           "1",                      "Allow the command to be used only by alive players.\n0 = OFF, 1 = ON", _, true, 0.0, true, 1.0);
    g_cvSpriteModel        = CreateConVar("sm_spot_marker_sprite_model",         "vgui/icon_download.vmt", "Sprite model");
    g_cvSpriteColor        = CreateConVar("sm_spot_marker_sprite_color",         "255 255 0",              "Sprite color.\nUse \"random\" for random colors.\nUse three values between 0-255 separated by spaces (\"<0-255> <0-255> <0-255>\")");
    g_cvSpriteAlpha        = CreateConVar("sm_spot_marker_sprite_alpha",         "255",                    "Sprite alpha transparency.\nNote: Some models don't allow to change the alpha.\n0 = Invisible, 255 = Fully Visible", _, true, 0.0, true, 255.0);
    g_cvSpriteFadeDistance = CreateConVar("sm_spot_marker_sprite_fade_distance", "-1",                     "Minimum distance that a client must be before the sprite fades.\n-1 = Always visible.", _, true, -1.0, true, 9999.0);
    g_cvSpriteZAxis        = CreateConVar("sm_spot_marker_sprite_z_axis",        "25.0",                   "Additional Z axis to the sprite", .hasMin = true, .min = 0.0);
    g_cvSpriteSpeed        = CreateConVar("sm_spot_marker_sprite_speed",         "1.0",                    "Speed that the sprite will move at the Z axis.\n0 = OFF", .hasMin = true, .min = 0.0);
    g_cvSpriteMinMax       = CreateConVar("sm_spot_marker_sprite_min_max",       "5.0",                    "Minimum/Maximum distance between the original position that the sprite should reach before inverting the vertical direction.\n0 = OFF", .hasMin = true, .min = 0.0);

    /*
     *
     */
    HookConVarChange(g_cvDuration,           OnCvChanged_Duration);
    HookConVarChange(g_cvCooldown,           OnCvChanged_Cooldown);
    HookConVarChange(g_cvSound,              OnCvChanged_Sound);
    HookConVarChange(g_cvMessage,            OnCvChanged_Message);
    HookConVarChange(g_cvAliveOnly,          OnCvChanged_AliveOnly);
    HookConVarChange(g_cvSpriteModel,        OnCvChanged_SpriteModel);
    HookConVarChange(g_cvSpriteColor,        OnCvChanged_SpriteColor);
    HookConVarChange(g_cvSpriteAlpha,        OnCvChanged_SpriteAlpha);
    HookConVarChange(g_cvSpriteFadeDistance, OnCvChanged_SpriteFadeDistance);
    HookConVarChange(g_cvSpriteZAxis,        OnCvChanged_SpriteZAxis);
    HookConVarChange(g_cvSpriteSpeed,        OnCvChanged_SpriteSpeed);
    HookConVarChange(g_cvSpriteMinMax,       OnCvChanged_SpriteMinMax);

    /*
     *
     */
    g_fDuration = GetConVarFloat(g_cvDuration);
    g_fCooldown = GetConVarFloat(g_cvCooldown);
    GetConVarString(g_cvSound, g_szSound, sizeof g_szSound);
    g_bMessage = GetConVarBool(g_cvMessage);
    g_bAliveOnly = GetConVarBool(g_cvAliveOnly);
    GetConVarString(g_cvSpriteModel, g_szSpriteModel, sizeof g_szSpriteModel);
    GetConVarString(g_cvSpriteColor, g_szSpriteColor, sizeof g_szSpriteColor);
    g_iSpriteAlpha = GetConVarInt(g_cvSpriteAlpha);
    g_iSpriteFadeDistance = GetConVarInt(g_cvSpriteFadeDistance);
    g_fSpriteZAxis = GetConVarFloat(g_cvSpriteZAxis);
    g_fSpriteSpeed = GetConVarFloat(g_cvSpriteSpeed);
    g_fSpriteMinMax = GetConVarFloat(g_cvSpriteMinMax);

    /*
     *
     */
    g_bSound = (g_szSound[0] != '\0');
    g_bSpriteSpeed = (g_fSpriteSpeed > 0.0);
    g_bSpriteMinMax = (g_fSpriteMinMax > 0.0);

    /*
     *
     */
    if (g_bSound) PrecacheSound(g_szSound, true);
    PrecacheModel(g_szSpriteModel, true);

    /*
     *
     */
    RegConsoleCmd("sm_mark", Cmd_Mark);
}

public void OnPluginEnd()
{
    char szTargetname[32];

    for (int iEntity = MaxClients + 1; iEntity < MAXENTITIES; iEntity++)
    {
        if (!IsValidEntity(iEntity)) {
            continue;
        }

        GetEntPropString(iEntity, Prop_Data, "m_iName", szTargetname, sizeof szTargetname);

        if (StrContains(szTargetname, ENTITY_MARKER_CLASS, false) == 0) {
            DestroyEntity(iEntity);
        }
    }
}

void OnCvChanged_Duration(ConVar cv, const char[] szOldValue, const char[] szNewValue) {
    g_fDuration = GetConVarFloat(cv);
}

void OnCvChanged_Cooldown(ConVar cv, const char[] szOldValue, const char[] szNewValue) {
    g_fCooldown = GetConVarFloat(cv);
}

void OnCvChanged_Sound(ConVar cv, const char[] szOldValue, const char[] szNewValue)
{
    GetConVarString(cv, g_szSound, sizeof g_szSound);

    g_bSound = g_szSound[0] != '\0';

    if (g_bSound) {
        PrecacheSound(g_szSound, true);
    }
}

void OnCvChanged_Message(ConVar cv, const char[] szOldValue, const char[] szNewValue) {
    g_bMessage = GetConVarBool(cv);
}

void OnCvChanged_AliveOnly(ConVar cv, const char[] szOldValue, const char[] szNewValue) {
    g_bAliveOnly = GetConVarBool(cv);
}

void OnCvChanged_SpriteModel(ConVar cv, const char[] szOldValue, const char[] szNewValue)
{
    GetConVarString(cv, g_szSpriteModel, sizeof g_szSpriteModel);
    PrecacheModel(g_szSpriteModel, true);
}

void OnCvChanged_SpriteColor(ConVar cv, const char[] szOldValue, const char[] szNewValue) {
    GetConVarString(cv, g_szSpriteColor, sizeof g_szSpriteColor);
}

void OnCvChanged_SpriteAlpha(ConVar cv, const char[] szOldValue, const char[] szNewValue) {
    g_iSpriteAlpha = GetConVarInt(cv);
}

void OnCvChanged_SpriteFadeDistance(ConVar cv, const char[] szOldValue, const char[] szNewValue) {
    g_iSpriteFadeDistance = GetConVarInt(cv);
}

void OnCvChanged_SpriteZAxis(ConVar cv, const char[] szOldValue, const char[] szNewValue) {
    g_fSpriteZAxis = GetConVarFloat(cv);
}

void OnCvChanged_SpriteSpeed(ConVar cv, const char[] szOldValue, const char[] szNewValue)
{
    g_fSpriteZAxis = GetConVarFloat(cv);
    g_bSpriteSpeed = (g_fSpriteSpeed > 0.0);
}

void OnCvChanged_SpriteMinMax(ConVar cv, const char[] szOldValue, const char[] szNewValue)
{
    g_fSpriteMinMax = GetConVarFloat(cv);
    g_bSpriteMinMax = (g_fSpriteMinMax > 0.0);
}

public void OnMapStart()
{
    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        g_fLastTime[iClient] = 0.0;

        for (int iTargetClient = 1; iTargetClient <= MaxClients; iTargetClient++)
        {
            g_iClientEntityRef[iClient][iTargetClient] = 0;
        }
    }
}

Action Cmd_Mark(int iClient, int iArgs)
{
    if (iClient == 0) {
        return Plugin_Handled;
    }

    if (g_fLastTime[iClient] != 0.0 && GetGameTime() - g_fLastTime[iClient] < g_fCooldown) {
        return Plugin_Handled;
    }

    if (g_bAliveOnly && !IsPlayerAlive(iClient)) {
        return Plugin_Handled;
    }

    float vEndPos[3];

    if (!TraceEyeRay(iClient, vEndPos)) {
        return Plugin_Handled;
    }

    int iClientTeam = GetClientTeam(iClient);

    float vSpritePos[3];
    vSpritePos = vEndPos;
    vSpritePos[2] += g_fSpriteZAxis;

    float vTargetClientPos[3];

    for (int iTargetClient = 1; iTargetClient <= MaxClients; iTargetClient++)
    {
        if (
            !IsClientInGame(iTargetClient) ||
            IsFakeClient(iTargetClient) ||
            iClientTeam != GetClientTeam(iTargetClient)
        )  {
            continue;
        }

        int iEnt = INVALID_ENT_REFERENCE;
        int iEntRef = g_iClientEntityRef[iClient][iTargetClient];

        if (iEntRef != 0 && ((iEnt = EntRefToEntIndex(iEntRef)) != INVALID_ENT_REFERENCE)) {
            DestroySpotMarker(iEnt);
        }

        if (g_bSound) {
            EmitSoundToClient(iTargetClient, g_szSound, .volume = 0.1);
        }

        if (g_bMessage) {
            CPrintToChatEx(iTargetClient, iClient, "%T%T", "TAG", iTargetClient, "SPOT_MARKED", iTargetClient, iClient);
        }

        GetClientEyePosition(iTargetClient, vTargetClientPos);

        int iEntSprite = DrawSpotMarker(iClient, iTargetClient, vSpritePos, g_fDuration, GetScaleByDistance(GetVectorDistance(vTargetClientPos, vSpritePos)));
        int iEntSpriteRef = EntIndexToEntRef(iEntSprite);

        DataPack pack;
        CreateDataTimer(0.1, Timer_UpdateMarker, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        pack.WriteCell(iEntSpriteRef);
        pack.WriteFloatArray(vSpritePos, sizeof vSpritePos);
        pack.WriteCell(false);

        g_iEntityOwner[iEntSprite] = GetClientUserId(iTargetClient);
        g_iClientEntityRef[iClient][iTargetClient] = iEntSpriteRef;
    }

    g_fLastTime[iClient] = GetGameTime();

    return Plugin_Handled;
}

Action Timer_UpdateMarker(Handle timer, DataPack pack)
{
    pack.Reset();

    int iEntSpriteRef = pack.ReadCell();
    float vSpritePos[3]; pack.ReadFloatArray(vSpritePos, sizeof(vSpritePos));
    bool bMoveUp = pack.ReadCell();

    int iEntSprite = EntRefToEntIndex(iEntSpriteRef);

    if (iEntSprite == INVALID_ENT_REFERENCE) {
        return Plugin_Stop;
    }

    int iTargetClient = GetClientOfUserId(g_iEntityOwner[iEntSprite]);

    if (iTargetClient == 0) {
        return Plugin_Stop;
    }

    float vTargetClientPos[3];
    GetClientEyePosition(iTargetClient, vTargetClientPos);

    SetVariantFloat(GetScaleByDistance(GetVectorDistance(vTargetClientPos, vSpritePos)));
    AcceptEntityInput(iEntSprite, "SetScale");

    float vPos[3];
    GetEntPropVector(iEntSprite, Prop_Data, "m_vecOrigin", vPos); // Don't use m_vecAbsOrigin cause is parented

    if (g_bSpriteSpeed && g_bSpriteMinMax)
    {
        if (bMoveUp)
        {
            vPos[2] += g_fSpriteSpeed;

            if (vPos[2] >= g_fSpriteMinMax) {
                bMoveUp = false;
            }
        }
        else
        {
            vPos[2] -= g_fSpriteSpeed;

            if (vPos[2] <= -g_fSpriteMinMax) {
                bMoveUp = true;
            } 
        }
    }

    TeleportEntity(iEntSprite, vPos, NULL_VECTOR, NULL_VECTOR);

    pack.Reset();
    pack.WriteCell(iEntSpriteRef);
    pack.WriteFloatArray(vSpritePos, sizeof vSpritePos);
    pack.WriteCell(bMoveUp);

    return Plugin_Continue;
}

int DrawSpotMarker(int iClient, int iTargetClient, const float vPos[3], float fDuration, float fScale)
{
    char szTargetname[32];
    FormatEx(szTargetname, sizeof szTargetname, "%s-%02i-%02i", ENTITY_MARKER_CLASS, iClient, iTargetClient);

    char szKillInput[32];
    FormatEx(szKillInput, sizeof szKillInput, "OnUser1 !self:Kill::%.1f:-1", fDuration);

    // --- info_target ---
    int iEntInfoTarget = CreateEntityByName("info_target");
    DispatchKeyValue(iEntInfoTarget, "targetname", szTargetname);
    DispatchKeyValueVector(iEntInfoTarget, "origin", vPos);
    DispatchSpawn(iEntInfoTarget);

    SetEntPropEnt(iEntInfoTarget, Prop_Send, "m_hOwnerEntity", iClient);

    SetVariantString(szKillInput);
    AcceptEntityInput(iEntInfoTarget, "AddOutput");
    AcceptEntityInput(iEntInfoTarget, "FireUser1");

    // --- env_sprite ---
    int iEntSprite = CreateEntityByName("env_sprite");
    if (iEntSprite == -1) return 0;

    DispatchKeyValue(iEntSprite, "targetname", szTargetname);
    DispatchKeyValue(iEntSprite, "spawnflags", "1");
    DispatchKeyValue(iEntSprite, "model", g_szSpriteModel);
    DispatchKeyValue(iEntSprite, "rendercolor", g_szSpriteColor);
    DispatchKeyValueInt(iEntSprite, "renderamt", g_iSpriteAlpha);
    DispatchKeyValueInt(iEntSprite, "fademindist", g_iSpriteFadeDistance);
    DispatchKeyValueVector(iEntSprite, "origin", vPos);
    DispatchKeyValueFloat(iEntSprite, "scale", fScale);

    SDKHook(iEntSprite, SDKHook_SetTransmit, OnSetTransmit);
    DispatchSpawn(iEntSprite);

    SetVariantString("!activator");
    AcceptEntityInput(iEntSprite, "SetParent", iEntInfoTarget);

    SetEntPropEnt(iEntSprite, Prop_Send, "m_hOwnerEntity", iEntInfoTarget);
    AcceptEntityInput(iEntSprite, "ShowSprite");

    SetVariantString(szKillInput);
    AcceptEntityInput(iEntSprite, "AddOutput");
    AcceptEntityInput(iEntSprite, "FireUser1");

    // --- output ---
    return iEntSprite;
}

void DestroySpotMarker(int iEnt)
{
    int iEntInfoTarget = GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity");

    DestroyEntity(iEnt);
    DestroyEntity(iEntInfoTarget);
}

Action OnSetTransmit(int iEntSprite, int iClient)
{
    if (IsFakeClient(iClient)) {
        return Plugin_Handled;
    }

    if (g_iEntityOwner[iEntSprite] != GetClientUserId(iClient)) {
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

float GetScaleByDistance(float distance)
{
    distance = ClampFloat(distance, MIN_DIST, MAX_DIST);

    float t = (distance - MIN_DIST) / (MAX_DIST - MIN_DIST);
    return MIN_SCALE + t * (MAX_SCALE - MIN_SCALE);
}

bool TraceEyeRay(int iClient, float vEndPos[3])
{
    float vPos[3];
    GetClientEyePosition(iClient, vPos);

    float vAng[3];
    GetClientEyeAngles(iClient, vAng);

    bool bTraceHit = false;

    Handle hTrace = TR_TraceRayFilterEx(vPos, vAng, MASK_VISIBLE, RayType_Infinite, TraceFilter, iClient);

    if (TR_DidHit(hTrace))
    {
        bTraceHit = true;
        TR_GetEndPosition(vEndPos, hTrace);
    }

    delete hTrace;

    if (!bTraceHit) {
        return false;
    }

    return true;
}

bool TraceFilter(int iEnt, int contentsMask, int iClient)
{
    if (iEnt == iClient) {
        return false;
    }

    if (iEnt == ENTITY_WORLDSPAWN) {
        return true;
    }

    if (iEnt > MaxClients)
    {
        char szClassname[2];
        GetEntityClassname(iEnt, szClassname, sizeof szClassname);

        return szClassname[0] == 'p';
    }

    return false;
}

void DestroyEntity(int iEnt) {
    AcceptEntityInput(iEnt, "Kill");
}

float ClampFloat(float value, float min, float max)
{
    if (value < min) return min;
    if (value > max) return max;
    return value;
}
