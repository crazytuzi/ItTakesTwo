import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.Sprint.CharacterSprintSettings;
import Vino.Camera.Capabilities.CameraTags;
import Effects.PostProcess.PostProcessing;
import Peanuts.SpeedEffect.SpeedEffectStatics;

class UCharacterSprintCameraCapability : UHazeCapability
{
	default RespondToEvent(n"SprintActive");

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Sprint);
	default CapabilityTags.Add(n"SprintCamera");
	default CapabilityTags.Add(CameraTags::Camera);

    default CapabilityDebugCategory = CameraTags::Camera;

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 100;

	UCameraUserComponent CameraUser;
	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UPostProcessingComponent PostProcessComp;
	UPostProcessingComponent PostProcessingComp;

	UPROPERTY()
	UCameraLazyChaseSettings ChaseSettings;
	USprintSettings SprintSettings;

	FHazeAcceleratedFloat AcceleratedFOV;
	FHazeAcceleratedFloat AcceleratedDistance;
	FHazeAcceleratedFloat AcceleratedShimmer;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CameraUser = UCameraUserComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		SprintSettings = USprintSettings::GetSettings(Owner);	
		PostProcessComp = UPostProcessingComponent::Get(Owner);
		PostProcessingComp = UPostProcessingComponent::Get(Player);

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!Owner.IsAnyCapabilityActive(n"SprintMovement"))
       		return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Owner.IsAnyCapabilityActive(n"SprintMovement"))
       		return EHazeNetworkDeactivation::DontDeactivate;

		// if (Owner.IsAnyCapabilityActive(n"DashJump"))
       	// 	return EHazeNetworkDeactivation::DontDeactivate;

		// if (Owner.IsAnyCapabilityActive(n"AirMovement"))
       	// 	return EHazeNetworkDeactivation::DontDeactivate;

		if (Owner.IsAnyCapabilityActive(n"Dash"))
       		return EHazeNetworkDeactivation::DontDeactivate;

		// if (Owner.IsAnyCapabilityActive(n"Jump"))
       	// 	return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
//		if (ChaseSettings != nullptr)
//			Player.ApplySettings(ChaseSettings, this);

		AcceleratedFOV.SnapTo(0.f);
		AcceleratedDistance.SnapTo(0.f);
	}


	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
//		if (ChaseSettings != nullptr)
//			Player.ClearSettingsWithAsset(ChaseSettings, this);

		Player.ClearFieldOfViewByInstigator(this, 0.8f);
		Player.ClearIdealDistanceByInstigator(this, 0.8f);

		//if (FMath::IsNearlyEqual(MoveComp.Velocity.Size(), MoveComp.MoveSpeed))
		// PostProcessingComp.SpeedShimmer = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			
		UpdateCamera(DeltaTime);
	}

	void UpdateCamera(float DeltaTime)
	{			
		FHazeCameraBlendSettings BlendSettings = FHazeCameraBlendSettings(0.2f);
		BlendSettings.Type = EHazeCameraBlendType::Additive;

		if (SceneView::IsFullScreen())
			Player.ClearFieldOfViewByInstigator(this, 0.8f);
		else
		{
			float TargetFOV = FMath::GetMappedRangeValueClamped(FVector2D(MoveComp.MoveSpeed, SprintSettings.MoveSpeed), FVector2D(0.f, 15.f), MoveComp.Velocity.Size());
			float NewFOV = AcceleratedFOV.AccelerateTo(TargetFOV, 0.8f, DeltaTime);
			Player.ApplyFieldOfView(NewFOV, BlendSettings, this, EHazeCameraPriority::Medium);
		}

		float TargetDistance = FMath::GetMappedRangeValueClamped(FVector2D(MoveComp.MoveSpeed, SprintSettings.MoveSpeed), FVector2D(0.f, -200.f), MoveComp.Velocity.Size());
		float NewDistance = AcceleratedDistance.AccelerateTo(TargetDistance, 2.5f, DeltaTime);
		Player.ApplyIdealDistance(NewDistance, BlendSettings, this, EHazeCameraPriority::Medium);
		
		float TargetShimmer = FMath::GetMappedRangeValueClamped(FVector2D(MoveComp.MoveSpeed, SprintSettings.MoveSpeed), FVector2D(0.f, 0.8f), MoveComp.Velocity.Size());
		//float NewShimmer = AcceleratedShimmer.AccelerateTo(TargetShimmer, 4.f, DeltaTime);
		SpeedEffect::RequestSpeedEffect(Player, FSpeedEffectRequest(TargetShimmer, this));
		//PostProcessingComp.SpeedShimmer = NewShimmer;
	}
}