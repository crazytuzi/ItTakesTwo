UCLASS(Meta = (ComposeSettingsOnto = "UCameraPointOfInterestBehaviourSettings"))
class UCameraPointOfInterestBehaviourSettings : UHazeComposableSettings
{
	// What fraction of full input we have to drop below before we count as giving no input
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraPointOfInterestBehaviour")
	float NoInputThreshold = 0.01f;

	// What fraction of full input be have to give before we can consider clearing point of interest
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraPointOfInterestBehaviour")
	float InputClearThreshold = 0.1f;

	// If POI should be cleared when giving input, we also need to be within this angle of POI before clearing
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraPointOfInterestBehaviour")
	float InputClearAngleThreshold = 5.f;

	// After matching POI rotation we will not be able to clear POI until after this delay (if allowed to clear POI due to input) 
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraPointOfInterestBehaviour")
	float InputClearWithinAngleDelay = 0.5f;

	// We need to give input for this duration for POI to clear (if allowed to clear POI due to input) 
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraPointOfInterestBehaviour")
	float InputClearDuration = 0.25f;

	// Input sensitivity blend down to zero over this time when a normal POI which can be cleared by input is activated.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraPointOfInterestBehaviour")
	float InputClearSensitivityRemoveDuration = 1.f;

	// Input sensitivity is gradually restored over this time when a POI has been cleared by input.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraPointOfInterestBehaviour")
	float InputClearSensitivityRestoreDuration = 3.f;
}