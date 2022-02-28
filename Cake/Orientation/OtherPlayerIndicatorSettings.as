UCLASS(Meta = (ComposeSettingsOnto = "UOtherPlayerIndicatorSettings"))
class UOtherPlayerIndicatorSettings : UHazeComposableSettings
{
	// If true, indicator is detached from player and moved to OverrideLocation
	UPROPERTY()
	bool bOverridePlayerLocation = false;

	// Location of indicator when bOverrideLocation is true
	UPROPERTY()
	FVector OverrideLocation = FVector::ZeroVector;

	// Offset of indicator when attached to player, scaled by actor scale.
	UPROPERTY()
	FVector PlayerOffset = FVector(0.f, 0.f, 0.f);

	// How many seconds indicator takes to move to/from override location. 0 means snap.
	UPROPERTY()
	float OverrideBlendDuration = 0.5f;
};