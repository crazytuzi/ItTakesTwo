UCLASS(hideCategories = "Activation Collision Cooking BrushSettings Actor HLOD Mobile Replication LOD AssetUserData Lighting Physics Rendering Debug Input VirtualTexture")
class ASpringArmCameraVolume : AHazeCameraVolume
{
	UPROPERTY(DefaultComponent, Category = "CameraSettings", ShowOnActor)
	USpringArmCameraSettingsComponent SpringArmSettings;
}

class USpringArmCameraSettingsComponent : UActorComponent
{
	UPROPERTY(Category = "SpringArmSettings", meta = (ShowOnlyInnerProperties))
	FHazeCameraSpringArmSettings SpringArmSettings;

	UPROPERTY(Category = "SpringArmSettings", meta = (ShowOnlyInnerProperties))
	FHazeCameraSettings CameraSettings;

	UPROPERTY(Category = "SpringArmSettings", meta = (ShowOnlyInnerProperties))
	FHazeCameraClampSettings ClampSettings;

	UHazeCameraSettingsComponent CamSettingsComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CamSettingsComp = UHazeCameraSettingsComponent::Get(Owner);
		if (!ensure(CamSettingsComp != nullptr))
			return; // No point in giving this comp to something which doesn't have a UHazeCameraSettingsComponent component

		CamSettingsComp.OnSettingsApplied.AddUFunction(this, n"OnApplySettings");	
	}

	UFUNCTION(NotBlueprintCallable)
	void OnApplySettings(UHazeCameraUserComponent User)
	{
		AHazePlayerCharacter PlayerUser = Cast<AHazePlayerCharacter>(User.Owner);
		if (PlayerUser == nullptr)
			return;

		// Use camsettingscomp as instigator, so it'll clear settings appropriately
		PlayerUser.ApplySpecificCameraSettings(CameraSettings, ClampSettings, SpringArmSettings, CamSettingsComp.Blend, CamSettingsComp, CamSettingsComp.Priority);
	}
}