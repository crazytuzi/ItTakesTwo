UCLASS(Meta = (ComposeSettingsOnto = "UCameraUserSettings"))
class UCameraUserSettings : UHazeComposableSettings
{
	UPROPERTY()
	bool bApplyRollToDesiredRotation = false;
}