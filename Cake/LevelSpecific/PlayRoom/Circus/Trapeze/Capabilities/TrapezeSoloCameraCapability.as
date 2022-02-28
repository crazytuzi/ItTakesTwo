import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeActor;

class UTrapezeSoloCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(TrapezeTags::Trapeze);
	default CapabilityTags.Add(TrapezeTags::CameraSolo);

	default CapabilityTags.Add(CapabilityTags::Camera);

	default CapabilityDebugCategory = TrapezeTags::Trapeze;

	AHazePlayerCharacter PlayerOwner;
	ATrapezeActor Trapeze;

	UTrapezeComponent TrapezeComponent;

	const FVector DefaultCameraOffset = FVector(0.f, 0.f, -100.f);
	const FVector CatcherThrowCameraOffset = FVector(-100.f, -800.f, 100.f);
	FHazePointOfInterest PointOfInterest;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		TrapezeComponent = UTrapezeComponent::Get(Owner);

		// Initialize point of interest structure
		PointOfInterest.Blend = 1.5f;
		PointOfInterest.Duration = -1.f;
		PointOfInterest.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!TrapezeComponent.IsSwinging())
			return EHazeNetworkActivation::DontActivate;

		if(TrapezeComponent.BothPlayersAreSwinging())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Trapeze = Cast<ATrapezeActor>(TrapezeComponent.GetTrapezeActor());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Update point of interest location
		PointOfInterest.FocusTarget.WorldOffset = GetLocationOfInterest(DeltaTime);
		PlayerOwner.ApplyPointOfInterest(PointOfInterest, this);

		// Update camera offset
		PlayerOwner.ApplyCameraOffsetOwnerSpace(GetCameraOffset(), 1.f, this);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!TrapezeComponent.IsSwinging())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(TrapezeComponent.BothPlayersAreSwinging())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Clear shit
		PlayerOwner.ClearPointOfInterestByInstigator(this);
		PlayerOwner.ClearCameraOffsetOwnerSpaceByInstigator(this);

		Trapeze = nullptr;
	}

	FVector GetLocationOfInterest(float DeltaTime)
	{
		FVector CatcherOffset = ShouldUseCatcherThrowParams() ? 
			-Trapeze.ActorForwardVector * 1200.f :
			FVector::ZeroVector;

		return Trapeze.SwingMesh.WorldLocation + Trapeze.TrapezeCameraActor.ActorForwardVector * 1000.f + CatcherOffset + Trapeze.SwingMesh.GetPhysicsLinearVelocity() * DeltaTime * 20.f;
	}

	FVector GetCameraOffset()
	{
		return ShouldUseCatcherThrowParams() ?
			CatcherThrowCameraOffset :
			DefaultCameraOffset;
	}

	bool ShouldUseCatcherThrowParams()
	{
		return Trapeze.bIsCatchingEnd && TrapezeComponent.PlayerHasMarble();
	}
}