import Vino.PlayerHealth.PlayerHealthStatics;

delegate void FOnRespawnPrevented(AHazePlayerCharacter Player);
delegate void FOnRespawnedAfterDelay(AHazePlayerCharacter Player);

/* Prevent a player from respawning temporarily. The delegate is called when a player dies and tries to respawn but is prevented. */
UFUNCTION(Category = "Player Health", meta=(DeprecatedFunction, DeprecationMessage = "Block the 'Respawn' capability tag instead."))
void DEPRECATED_PreventPlayerRespawn(AHazePlayerCharacter Player, FOnRespawnPrevented OnRespawnPrevented)
{
	devEnsure(false, "PreventPlayerRespawn is deprecated. Block the 'Respawn' capability tag instead.");
	Player.BlockCapabilities(n"Respawn", Player);
}

/* Allow a player to respawn again. The delegate is called if a player is currently dead and its respawn is triggered right now. */
UFUNCTION(Category = "Player Health", meta=(DeprecatedFunction, DeprecationMessage = "Unblock the 'Respawn' capability tag instead."))
void DEPRECATED_AllowPlayerRespawn(AHazePlayerCharacter Player, FOnRespawnedAfterDelay OnRespawnedAfterDelay)
{
	devEnsure(false, "AllowPlayerRespawn is deprecated. Unblock the 'Respawn' capability tag instead.");
	Player.UnblockCapabilities(n"Respawn", Player);
}

UFUNCTION(Category = "Player Health", meta=(DeprecatedFunction, DeprecationMessage = "Use AddPlayerInvulnerability with an instigator instead."))
void DEPRECATED_SetPlayerInvulnerable(AHazePlayerCharacter Player, bool bInvulnerable)
{
	devEnsure(false, "SetPlayerInvulnerable is deprecated. Use AddPlayerInvulnerability with an instigator instead.");
	if (bInvulnerable)
		AddPlayerInvulnerability(Player, Player);
	else
		RemovePlayerInvulnerability(Player, Player);
}

UFUNCTION(Category = "Player Health", meta=(DeprecatedFunction, DeprecationMessage = "Lives are no longer a thing."))
int DEPRECATED_GetPlayerCurrentLives()
{
	return 1;
}

UFUNCTION(Category = "Player Health", meta=(DeprecatedFunction, DeprecationMessage = "Lives are no longer a thing."))
int DEPRECATED_GetPlayerMaxLives()
{
	return 1;
}

UFUNCTION(Category = "Player Health", meta=(DeprecatedFunction, DeprecationMessage = "Lives are no longer a thing."))
float DEPRECATED_GetPlayerFractionalLifeDamage()
{
	return 0.f;
}

UFUNCTION(Category = "Player Health", meta=(DeprecatedFunction, DeprecationMessage = "Lives are no longer a thing."))
void DEPRECATED_SetPlayerCurrentLives(int NewLivesCount, bool bResetFractionalDamage = true)
{
}

UFUNCTION(Category = "Player Health", meta=(DeprecatedFunction, DeprecationMessage = "Lives are no longer a thing."))
void DEPRECATED_AddPlayerLives(int AddLivesCount)
{
}

UFUNCTION(Category = "Player Health", meta=(DeprecatedFunction, DeprecationMessage = "Use ApplySettings with a HealthSettings data asset instead."))
void DEPRECATED_SetPlayerDeathSettings(UObject DeathSettings)
{
	devEnsure(false, "SetPlayerDeathSettings is deprecated. Use ApplySettings with a HealthSettings data asset instead.");
}

UFUNCTION(Category = "Player Health", meta=(DeprecatedFunction, DeprecationMessage = "Use ApplySettings with a HealthSettings data asset instead."))
void DEPRECATED_ResetPlayerDeathSettings(UObject DeathSettings)
{
}

UFUNCTION(Category = "Player Health", meta=(DeprecatedFunction, DeprecationMessage = "Use ApplySettings with a HealthSettings data asset instead."))
UObject DEPRECATED_GetPlayerDeathSettings()
{
	return nullptr;
}

UFUNCTION(Category = "Player Health", meta=(DeprecatedFunction, DeprecationMessage = "Manually triggering game over events is deprecated."))
void DEPRECATED_TriggerGameOver()
{
	devEnsure(false, "TriggerGameOver is deprecated.");
}

UFUNCTION(Category = "Player Health", meta=(DeprecatedFunction, DeprecationMessage = "Manually triggering respawn is deprecated."))
void DEPRECATED_RespawnAtAvailableCheckpoint(AHazePlayerCharacter Player)
{
	devEnsure(false, "RespawnAtAvailableCheckpoint is deprecated.");
}

class UDEPRECATED_DeathSettings : UDataAsset
{
};

class UDEPRECATED_DeathComponent : UActorComponent
{
};