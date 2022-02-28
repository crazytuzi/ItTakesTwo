
UCLASS(meta=(ComposeSettingsOnto = "USingingSettings"))
class USingingSettings : UHazeComposableSettings
{
	UPROPERTY(Category = Shared)
	float SingingRange = 2000.0f;

	UPROPERTY(Category = Shared)
	float SingingRangeTargetable = 3000.0f;

	UPROPERTY(Category = Shared)
	float SingingRangeVisible = 4000.0f;

	UPROPERTY(Category = SongOfLife)
	float SongOfLifeRange = 3000.0f;
	
	UPROPERTY(Category = SongOfLife)
	float SongOfLifeDurationMaximum = 5.0f;

	// Time before SongOfLife can be activated again after being deactivated by the player.
	UPROPERTY(Category = SongOfLife)
	float SongOfLifeCooldown = 1.2f;

	// If song of life is completely depleted, this is the time you need to wait before it starts to recharge
	UPROPERTY(Category = SongOfLife)
	float SongOfLifeDepletedCooldown = 1.2f;

	UPROPERTY(Category = SongOfLife, meta = (ClampMin = 1.0))
	float SongOfLifeRechargeRate = 1.2f;

	// Wait time before recharge is started.
	UPROPERTY(Category = SongOfLife, meta = (ClampMin = 0.0))
	float SongOfLifeRechargeCooldown = 1.2f;

	UPROPERTY(Category = SongOfLife, meta = (ClampMin = 1.0))
	float SongOfLifeRechargeRateIncrement = 1.05f;

	// After Song of life has been fully depleted, in order to prevent quick activations that will deactivate right away, we can set a minimal fraction so the player must wait until a certain amount has recharged.
	UPROPERTY(Category = SongOfLife, meta = (ClampMin = 0.0, ClampMax = 1.0))
	float RequiredRechargeFractionAfterDepletion = 0.25f;

	// Time we must wait between shooting another powerful song projectile.
	UPROPERTY(Category = PowerfulSong, meta = (ClampMin = 0.0))
	float PowerfulSongCooldown = 0.85f;

	// Percent of "SongOfLifeDurationMaximum" each blast will drain
	UPROPERTY(Category = PowerfulSong, meta = (ClampMin = 0.0, ClampMax = 1.0))
	float PowerfulSongCost = 0.1f;

	UPROPERTY(Category = PowerfulSong, meta = (ClampMin = 1.0))
	float PowerfulSongMovementSpeed = 12000.0f;

	UPROPERTY(Category = Deprecated, meta = (ClampMin = 0.0, ClampMax = 180.0))
	float HorizontalAngle = 30.0f;

	UPROPERTY(Category = Deprecated, meta = (ClampMin = 0.0, ClampMax = 180.0))
	float VerticalAngle = 60.0f;

	UPROPERTY(Category = Deprecated, meta = (ClampMin = 0.0))
	float HorizontalOffset = 10.0f;

	UPROPERTY(Category = Deprecated, meta = (ClampMin = 0.0))
	float VerticalOffset = 10.0f;
}
