import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeActor;
import Peanuts.Network.MeshPhysicsReplicationComponent;
import Vino.Pickups.PickupActor;

// Handle player-positioning in swing in a different capability;
// TrapezeSwingPostPhysicsCapability takes care of this
class UTrapezeSwingCapability : UHazeCapability
{
	default CapabilityTags.Add(TrapezeTags::Trapeze);
    default CapabilityTags.Add(TrapezeTags::Swing);

    default TickGroup = ECapabilityTickGroups::ActionMovement;

	default CapabilityDebugCategory = TrapezeTags::Trapeze;

    AHazePlayerCharacter PlayerOwner;
	UTrapezeComponent TrapezeComponent;

	ATrapezeActor Trapeze;
	UMeshPhysicsReplicationComponent MeshPhysicsReplicationcomponent;
	UHazeSmoothSyncFloatComponent SwingForceMagnitudeSyncComponent;

	const FVector Gravity = FVector(0.f, 0.f, -9800.f);
	const float SwingStepMultiplier = 50.f;

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		TrapezeComponent = UTrapezeComponent::Get(PlayerOwner);

        Trapeze =  Cast<ATrapezeActor>(TrapezeComponent.GetTrapezeActor());
		SwingForceMagnitudeSyncComponent = UHazeSmoothSyncFloatComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if(!TrapezeComponent.PlayerIsOnSwing())
            return EHazeNetworkActivation::DontActivate;

		if(TrapezeComponent.PlayerWantsOut())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Don't crumbify movement, use trapeze mesh replication insteads
		if(Network::IsNetworked())
		{
			// Trapeze swing system handles its own network movement synch,
			// movement synching unblocks in TrapezeUnmountCapability::OnDeactivated()
			PlayerOwner.BlockMovementSyncronization(PlayerOwner);

			MeshPhysicsReplicationcomponent = UMeshPhysicsReplicationComponent::GetOrCreate(Trapeze);
			MeshPhysicsReplicationcomponent.AttachToComponent(Trapeze.SwingMesh);
			MeshPhysicsReplicationcomponent.StartReplication(HasControl(), 0.1f, 0.1f);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Get player's system input's magnitude
		if(HasControl())
			SwingForceMagnitudeSyncComponent.Value = GetNormalCameraTrapezeInput();

		// Request locomotion
		TrapezeComponent.RequestTrapezeLocomotion(Trapeze.AnimationDataComponent, GetBlendSpaceValue());

		// Control side will control trapeze's physics, remote will just replicate
		if(Trapeze.SwingMesh.IsSimulatingPhysics() && HasControl())
		{
			// Get time step multiplier; lower in network to help with latency
			float StepMultiplier = DeltaTime * SwingStepMultiplier;

			// Compensate fps because unreal physics constraint component can suck it
			float FrameRateMultiplier = (1.f / DeltaTime) / 60.f;
			StepMultiplier *= FrameRateMultiplier * (FrameRateMultiplier > 1.f ? FrameRateMultiplier * 0.95f : 1.f);

			// Apply duplicated gravity force for tastier result
			FVector GravityJuice = Gravity * 3.f * StepMultiplier;

			// Calculate how far we are from the bob's resting point
			FVector BobToPivot = (Trapeze.GetActorLocation() - Trapeze.SwingMesh.GetWorldLocation()).GetSafeNormal();
			float SwingMagnitude = -BobToPivot.DotProduct(Gravity);

			// Get force from direction and multiplier
			FVector SwingForce = PlayerOwner.GetActorForwardVector() * FMath::Square(SwingForceMagnitudeSyncComponent.Value) * FMath::Sign(SwingForceMagnitudeSyncComponent.Value);
			SwingForce *= SwingMagnitude * StepMultiplier;

			// Apply more drag the higher the trapeze is
			float LaResistance = 1.f + BobToPivot.DotProduct(Gravity.GetSafeNormal());
			LaResistance = FMath::Pow(LaResistance, 2.f);

			// Only apply drag when going up the positive side of the period
			FVector Drag = FVector::ZeroVector;
			if(ShouldAddInputResistance())
				Drag = -SwingForce * LaResistance * StepMultiplier * 10.f;

			// Go  go go!
			Trapeze.SwingMesh.AddForce(SwingForce + GravityJuice + Drag);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if(WasActionStarted(ActionNames::Cancel))
		    return EHazeNetworkDeactivation::DeactivateFromControl;

		if(WasActionStarted(ActionNames::MovementJump))
		    return EHazeNetworkDeactivation::DeactivateFromControl;

		// Ends swing when players complete section and only when they're above the platform
		if(Trapeze.bTrapezeSectionCleared && Trapeze.GetAbsoluteAmplitude() < 10.f)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Get down, stop screwing around!
		TrapezeComponent.SetPlayerWantsOut(true);

		// Stop trapeze ABP
		PlayerOwner.ClearLocomotionAssetByInstigator(Trapeze);

		// Stop trapeze network mesh replicaton
		if(Network::IsNetworked())
		{
			MeshPhysicsReplicationcomponent.StopReplication();
			MeshPhysicsReplicationcomponent.DetachFromComponent();
			MeshPhysicsReplicationcomponent = nullptr;
		}
	}

	float GetBlendSpaceValue()
	{
		if(TrapezeComponent.ShouldReachForMarble(Trapeze.Marble, Trapeze.bIsCatchingEnd))
		{
			// Trapeze.AnimationDataComponent.bIsReaching = true;

			FVector PlayerToMarble = (Trapeze.Marble.ActorLocation - PlayerOwner.Mesh.GetSocketLocation(n"RightAttach")).GetSafeNormal();
			return FMath::Max(-0.8f, PlayerToMarble.DotProduct(PlayerOwner.Mesh.ForwardVector) * 1.2f);
		}
		else
		{
			// Trapeze.AnimationDataComponent.bIsReaching = false;
			return SwingForceMagnitudeSyncComponent.Value;
		}
	}

	float GetNormalCameraTrapezeInput()
	{
		FVector2D LeftStickInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		float Direction = FMath::Sign(PlayerOwner.GetActorForwardVector().DotProduct(PlayerOwner.CurrentlyUsedCamera.RightVector));

		// Invert value depending on side
		float NormalInput = LeftStickInput.X * Direction;

		// Arbitrary multiplier to increase speed
		return NormalInput * 1.5f;
	}

	bool ShouldAddInputResistance() const
	{
		float TrapezeForwardDot = Trapeze.ActorForwardVector.DotProduct(Trapeze.SwingMesh.ComponentVelocity.GetSafeNormal());

		if(Trapeze.GetCurrentAmplitude() > 0)
		{
			if(SwingForceMagnitudeSyncComponent.Value > 0 && TrapezeForwardDot > 0)
				return true;
		}
		else
		{
			if(SwingForceMagnitudeSyncComponent.Value < 0 && TrapezeForwardDot < 0)
				return true;
		}

		return false;
	}
}