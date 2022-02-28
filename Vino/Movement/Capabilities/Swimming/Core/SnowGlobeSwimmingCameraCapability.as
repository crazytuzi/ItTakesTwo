import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Capabilities.CameraTags;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;

class USnowGlobeSwimmingCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	default CapabilityTags.Add(SwimmingTags::Camera);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 100;

	UCameraUserComponent CameraUser;
	AHazePlayerCharacter Player;
	USnowGlobeSwimmingComponent SwimComp; 
	UHazeMovementComponent MoveComp;

	FHazeAcceleratedFloat FOVBySpeed;
	default FOVBySpeed.SnapTo(70.f);

	FHazeAcceleratedFloat DistanceBySpeed;
	default DistanceBySpeed.SnapTo(1000.f);


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CameraUser = UCameraUserComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!SwimComp.bIsInWater)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!SwimComp.bIsInWater)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.ApplyCameraSettings(SwimComp.CameraSettings, FHazeCameraBlendSettings(3.f), this, EHazeCameraPriority::Low);			
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this, 3.f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			
		// Set FOV based on speed
		float TargetFOV = FMath::GetMappedRangeValueClamped(FVector2D(1000.f, 3200.f), FVector2D(70.f, 110.f), MoveComp.Velocity.Size());
		float CurFOV = FOVBySpeed.AccelerateTo(TargetFOV, 5.0f, DeltaTime);
		Player.ApplyFieldOfView(CurFOV, FHazeCameraBlendSettings(0.5f), this, EHazeCameraPriority::Medium);

		float TargetDistance = FMath::GetMappedRangeValueClamped(FVector2D(1000.f, 3200.f), FVector2D(1000.f, 400.f), MoveComp.Velocity.Size());
		float CurDistance = DistanceBySpeed.AccelerateTo(TargetDistance, 5.0f, DeltaTime);
		Player.ApplyIdealDistance(CurDistance, FHazeCameraBlendSettings(1.2f), this, EHazeCameraPriority::Low);
	}
}