// When you want to modify the behaviour of a camera, you can apply camera settings to the player using that camera.
// Most commonly this is done when you want to tweak the behaviour of the default player camera.
// You can apply settings directly as seen below or by placing a camera volume with a settings asset which will then
// apply the seting when the player is inside the volume. 
// Note that if the behaviour you want is very different from how the regular camera works, you should consider 
// activating a separate camera instead, see Example_CameraActors.as

class AExample_CameraSettingsVolume : AHazeCameraVolume
{
	UPROPERTY()
	UHazeCameraSettingsDataAsset ExampleAsset_IdealDistance = Asset("/Game/Blueprints/Cameras/CameraSettings/ExampleSettings/DA_ExampleCameraSettings_IdealDistance.DA_ExampleCameraSettings_IdealDistance");

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnVolumeActivated.AddUFunction(this, n"VolumeActivated");
		OnVolumeDeactivated.AddUFunction(this, n"VolumeDeactivated");
	}

	UFUNCTION()
	private void VolumeActivated(UHazeCameraUserComponent User)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(User.Owner);

		// In blueprint you normally apply a camera settings asset. 
		// You can also do this in angelscript as seen below.
		// When you apply a settings asset you can tweak it in runtime to achieve the results you want.
		// In addition to the settings asset parameters are: 
		// - A blend settings, which usually only describes the time it will take for your settings 
		//   to be applied. More about that later.
		// - An instigator, which is the system responsible for applying the settings, usually ´this´.
		//   It is used to clear settings so you won't mess with settings set by other systems.
		//   It also helps debugging a lot since you can see where weird behaviour comes from.
		// - A priority, which defines how important these settings are. If other settings have been or are 
		//   applied with higher priority, or at a later time with same prio those settings will override yours. 
		//   The more general a system is the lower the prio should be, so specific ones shoud have high prio.
		//   Prio order is Minimum < Low < Medium < High < Script < Cutscene < Maximum.
		Player.ApplyCameraSettings(ExampleAsset_IdealDistance, CameraBlend::Normal(3.f), this, EHazeCameraPriority::Low);
	
		// You'd normally just use the CameraBlend::Normal() function to set blend time, but you can also do this:
		FHazeCameraBlendSettings BlendSlow;
		BlendSlow.BlendTime = 10.f;
		// ...or this:
		FHazeCameraBlendSettings BlendFast(1.f); // ...which is the same as 'BlendFast = FHazeCameraBlendSettings(1.f)' or 'BlendFast = CameraBlend::Normal(1.f)'

		// You can also apply specific settings using some helper functions such as:
		Player.ApplyFieldOfView(30, BlendSlow, this, EHazeCameraPriority::Medium); // This will reduce field of view
		Player.ApplyPivotOffset(FVector(0.f, 0.f, 400.f), BlendFast, this, EHazeCameraPriority::Medium); // This will move the point the camera rotates around upwards
		// Player.ApplyPivotLagSpeed(...)
		// Player.ApplyPivotLagMax(...)
		// Player.ApplyCameraOffset(...)
		// Player.ApplyCameraOffsetOwnerSpace(...)
		// Player.ApplyIdealDistance(...)

		// Only the most common settings have specific functions like the ones above.
		// If you want full control you can use the more cumbersome way such as:
		FHazeCameraSpringArmSettings SpringArmSettings;
		SpringArmSettings.bUseCameraOffset = true; 					// This lets the settings manager know we want to set Camera Offset but do not care about any other settings
		SpringArmSettings.CameraOffset = FVector(0.f, 200.f, 0.f); 	// This will move the camera to the right in camera space
		Player.ApplyCameraSpringArmSettings(SpringArmSettings, BlendSlow, this, EHazeCameraPriority::Low);

		FHazeCameraClampSettings ClampSettings;
		ClampSettings.bUseClampPitchUp = true;
		ClampSettings.ClampPitchUp = 0.f; 	// This will stop the player from looking upwards
		ClampSettings.bUseClampPitchDown = true;
		ClampSettings.ClampPitchDown = 85.f; 	// This will allow the player to look almost straight downwards
		Player.ApplyCameraClampSettings(ClampSettings, BlendSlow, this, EHazeCameraPriority::Low);

		// Player.ApplyCameraKeepInViewSettings(...)

		// This would widen FOV and set springarm pivot offset, but note that there are other functions changing those
		// settings with higher priority, so this will not do anything until those settings are cleared.
		FHazeCameraSettings CamSettings;
		CamSettings.bUseFOV = true;
		CamSettings.FOV = 120.f; 
		FHazeCameraSpringArmSettings OtherSpringArmSettings;
		OtherSpringArmSettings.bUsePivotOffset = true;
		OtherSpringArmSettings.PivotOffset.Z = 100.f;
		Player.ApplySpecificCameraSettings(CamSettings, FHazeCameraClampSettings(), OtherSpringArmSettings, BlendFast, this, EHazeCameraPriority::Low);

		// As you may have noticed from testing this actor you can make separate settings blend in over different times.
		// The above will for example change the field of view slowly but the pivot offset slowly.
		// If you however want to change some setting but do not care about how fast they are changed and just want it
		// to match the blend time of other lower prio settings, then you can use this blend type:
		FHazeCameraBlendSettings BlendMatchPrevious = CameraBlend::MatchPrevious();

		// In some cases you just want your settings to change underlying settings rather than overwriting them.
		// For this, use the Additive blend type like this:
		Player.ApplyIdealDistance(500.f, CameraBlend::Additive(3.f), this, EHazeCameraPriority::High);

		// When tweaking some settings in run time continuously, you might want them to initially blend in,  
		// then keep up without blending. To do this, use the ManualFraction blend type:
		float FractionThatYouShouldControlManually = 0.f;
		float InitialBlendTime = 2.f;
		FHazeCameraBlendSettings BlendManualFraction = CameraBlend::ManualFraction(FractionThatYouShouldControlManually, InitialBlendTime);

		// An example of ManualFraction blending can be found in this capability below
		Player.AddCapability(n"Example_CameraSettingsCapability");
	}

	UFUNCTION()
	private void VolumeDeactivated(UHazeCameraUserComponent User)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(User.Owner);

		// Normally, a system would want to clean up any settings it is responsible for when "done":
		// The parameters for this is the instigating object (usually 'this') and an optional override blend time.
		// If no blend time is given the default behaviour is to inherit the blend time from the lower prio settings
		// we fall back to when clearing our settings. This is nice when we don't care about precise blend time.
		// If you do set a blend time, as in the example below, all our settings will blend out using that time.
		Player.ClearCameraSettingsByInstigator(this, 5.f);

		// Alternatively you can clear particular settings only, though you really need to ensure that all settings get cleared eventually.
		Player.ClearFieldOfViewByInstigator(this, 2.f); // This will have no effect since we've already cleared all settings above
		Player.ClearCameraClampSettingsByInstigator(this); // Would clear all clamps settings with inherited blend time (but no effect now) 
		// Player.ClearIdealDistanceByInstigator(...)
		// ...

		// Finally, if you want to clear some particular settings which there are no specific function for 
		// you would have to set the use flags for the settings you want to clear to true.
		FHazeCameraSettings ClearCamSettings;
		ClearCamSettings.bUseFOV = true;	// Clear FOV...
		FHazeCameraSpringArmSettings ClearSpringArmSettings;
		ClearSpringArmSettings.bUseIdealDistance = true; // ...and Ideal Distance
		Player.ClearSpecificCameraSettings(ClearCamSettings, FHazeCameraClampSettings(), ClearSpringArmSettings, this, 12.f); // This won't affect Clamps Settings since default use flags is false.

		// See the capability below for further examples of clearing specific settings
	}
}

class UExample_CameraSettingsCapability : UHazeCapability
{
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.ApplyCameraOffset(FVector(0.f, 100.f, 0.f), CameraBlend::MatchPrevious(), this, EHazeCameraPriority::High);		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Blending the setting by manual fraction can be nice when you want to control how strongly some settings
		// are applied on top of base settings. 
		// Here we widen the FOV by how fast you move, but since we blend it in as a fraction we do not need to know
		// or care about what the base FOV is.
		float Fraction = FMath::GetMappedRangeValueClamped(FVector2D(1.f, 1000.f), FVector2D(0.f, 1.f), Player.GetActualVelocity().Size());
		Player.ApplyFieldOfView(160.f, CameraBlend::ManualFraction(Fraction, 5.f), this, EHazeCameraPriority::High);

		// This will apply/clear a specific setting without affecting any others
		if (IsActioning(ActionNames::MovementJump))
			Player.ApplyIdealDistance(2000.f, CameraBlend::MatchPrevious(), this, EHazeCameraPriority::High);
		else
			Player.ClearIdealDistanceByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// As usual, you should clear all settings instigated by this system when done
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// Activate when pressing interaction
		if (!IsActioning(ActionNames::InteractionTrigger))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// Deactivate when pressing weapon fire
		if (!IsActioning(ActionNames::WeaponFire))
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}
}