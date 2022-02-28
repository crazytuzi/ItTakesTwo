import Vino.PlayerHealth.PlayerDeathEffect;
import Vino.PlayerHealth.PlayerDamageEffect;
import Vino.PlayerHealth.PlayerRespawnEffect;
import Vino.PlayerHealth.PlayerGameOverEffect;

enum EPlayerHealthDisplayPosition
{
	Default,
	TopTogether,
};

UCLASS(Meta = (ComposeSettingsOnto = "UPlayerHealthSettings"))
class UPlayerHealthSettings : UHazeComposableSettings
{
	// If set, players are able to go game over if both are dead at the same time
	UPROPERTY(Category = "Game Over")
	bool bCanGameOver = false;

	// If set, the health will be displayed on the screen
	UPROPERTY(Category = "Health")
	bool bDisplayHealth = false;

	// The position on screen that the health HUD should be shown at right now
	UPROPERTY(Category = "Health")
	EPlayerHealthDisplayPosition HealthPosition = EPlayerHealthDisplayPosition::Default;

	// How many chunks to display the health in
	UPROPERTY(Category = "Regeneration", meta = (ClampMin = "1", UIMin = "1"))
	int HealthChunks = 1;

	// Whether to regenerate to the nearest chunk if we haven't taken damage for a while
	UPROPERTY(Category = "Regeneration")
	bool bRegenerateToHealthChunk = false;

	// Delay until regeneration kicks in
	UPROPERTY(Category = "Regeneration")
	float RegenerationDelay = 5.f;

	// If set, players will need to wait a specific amount of time before respawning
	UPROPERTY(Category = "Respawn")
	float RespawnTimer = 0.f;

	// How many times pre second we should mash to reach the fastest respawn rate
	UPROPERTY(Category = "Respawn")
	float RespawnMashTargetRate = 3.f;

	// If the player is not mashing at all, how slow should the respawn be as a percentage of the respawn timer
	UPROPERTY(Category = "Respawn")
	float RespawnMashSlowestPct = 1.f;

	// If the player is mashing the whole time, percentage of the respawn timer that they will reach
	UPROPERTY(Category = "Respawn")
	float RespawnMashFastestPct = 0.45f;

	// Default effect to use when the player dies
	UPROPERTY(Category = "Effects")
	TSubclassOf<UPlayerDeathEffect> DefaultDeathEffect;

	// Default effect to use when the player takes damage
	UPROPERTY(Category = "Effects")
	TSubclassOf<UPlayerDamageEffect> DefaultDamageEffect;

	// Default effect to use when the player dies due to a death volume
	UPROPERTY(Category = "Effects")
	TSubclassOf<UPlayerDeathEffect> DefaultDeathVolumeEffect;

	// Default effect to use when the player respawns
	UPROPERTY(Category = "Effects")
	TSubclassOf<UPlayerRespawnEffect> DefaultRespawnEffect;

	// Default effect to use when the players are game over
	UPROPERTY(Category = "Effects")
	TSubclassOf<UPlayerGameOverEffect> DefaultGameOverEffect;
};