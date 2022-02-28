import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeActor;

class UTrapezeFullscreenCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(TrapezeTags::Trapeze);
	default CapabilityTags.Add(TrapezeTags::CameraFullscreen);

	default CapabilityTags.Add(CapabilityTags::Camera);

	default CapabilityDebugCategory = TrapezeTags::Trapeze;

	AHazePlayerCharacter PlayerOwner;
	AHazeCameraActor TrapezeCameraActor;
	ATrapezeActor Trapeze;

	UTrapezeComponent TrapezeComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		TrapezeComponent = UTrapezeComponent::Get(Owner);
		Trapeze = Cast<ATrapezeActor>(UTrapezeComponent::Get(PlayerOwner).GetTrapezeActor());
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!TrapezeComponent.BothPlayersAreSwinging())
			return EHazeNetworkActivation::DontActivate;

		if(Trapeze.Marble.IsFlyingTowardsDispenser())
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ATrapezeActor TrapezeActor = Cast<ATrapezeActor>(UTrapezeComponent::Get(PlayerOwner).GetTrapezeActor());
		if(TrapezeActor == nullptr)
		{
			Warning("You are trying to enable trapeze camera capability without even swingin'!");
			return;
		}

		TrapezeCameraActor = TrapezeActor.TrapezeCameraActor;

		if(HasControl())
			ActivateTrapezeCamera();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!TrapezeComponent.BothPlayersAreSwinging())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Trapeze.Marble.IsFlyingTowardsDispenser())
			return EHazeNetworkDeactivation::DeactivateLocal;

        return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(HasControl())
			DeactivateTrapezeCamera();
	}

	void ActivateTrapezeCamera()
	{
		PlayerOwner.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, Priority = EHazeViewPointPriority::Medium);

		FHazeCameraBlendSettings CameraBlendSettings;
		CameraBlendSettings.BlendTime = 1.f;
		TrapezeCameraActor.ActivateCamera(PlayerOwner, CameraBlendSettings, this);
	}

	void DeactivateTrapezeCamera()
	{
		PlayerOwner.ClearViewSizeOverride(this);
		TrapezeCameraActor.DeactivateCamera(PlayerOwner, 1.f);
	}
}