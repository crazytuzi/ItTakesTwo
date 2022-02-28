UCLASS(Meta = (ComposeSettingsOnto = "UFocusTargetSettings"))
class UFocusTargetSettings : UHazeComposableSettings
{
	UPROPERTY()
	USceneComponent Component = nullptr;

	UPROPERTY()
	float CapsuleHeightOffset = 0.95f;
};
