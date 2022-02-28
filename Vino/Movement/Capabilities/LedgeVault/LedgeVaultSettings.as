
struct FLedgeVaultSettings
{
	// The players input direction doted with the walls direction has to be higher or equal to this value to activate the vault.
	float InputActivationTreshold = 0.9f;	

	// How far in time to anticipate in time for starting the vault.
	float TimeAnticipation = 0.1f;

	// Bonus speed you gain at the end of the vault.
	float BonusSpeed = 0.f;
};

UCLASS(Meta = (ComposeSettingsOnto = "ULedgeVaultDynamicSettings"))
class ULedgeVaultDynamicSettings : UHazeComposableSettings
{	
	// How high the we will go from the impact point when tracing down the get the top.
	UPROPERTY()
	float FindTopHeight = 350.f;

	// How horizontally far we will trace when looking for the top.
	UPROPERTY()
	float FindTopDepth = 35.f;

	// how much we remove from the capsule height when predicting if we should enter a vault.
	UPROPERTY()
	float PredictionTraceOffset = 50.f;

	// The character has to be within this range to the top to active the vault.
	float MaxiumDistanceToTop = 195.f;

	// How long it takes to finish the vault.
	UPROPERTY()
	float LerpTime = 0.2f;
}
