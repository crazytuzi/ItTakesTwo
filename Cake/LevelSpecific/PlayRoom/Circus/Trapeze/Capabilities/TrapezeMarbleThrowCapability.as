import Vino.Pickups.Throw.PickupThrowComponent;
import Vino.Pickups.PickupActor;
import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeActor;
import Peanuts.Network.MeshPhysicsReplicationComponent;
import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeAnimNotifies;

class UTrapezeMarbleThrowCapability : UHazeCapability
{
	default CapabilityTags.Add(TrapezeTags::Trapeze);
	default CapabilityTags.Add(TrapezeTags::MarbleThrow);

	default TickGroupOrder = 101;

	default CapabilityDebugCategory = TrapezeTags::Trapeze;

	AHazePlayerCharacter PlayerOwner;
	UPlayerPickupComponent PlayerPickupComponent;
	UTrapezeComponent TrapezeInteractionComponent;

	ATrapezeMarbleActor MarbleActor;
	ATrapezeActor TrapezeActor;

	FThrownActorReachedTarget MarbleReachedTrajectoryEnd;
	FTimerHandle CooldownTimer;

	const float ThrowSimulationBaseSpeed = 2.f;
	const float ThrowMagnitude = 1400.f;

	bool bCooldownDone;

	bool bMarbleThrown;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PlayerPickupComponent = UPlayerPickupComponent::Get(Owner);

		TrapezeInteractionComponent = UTrapezeComponent::Get(Owner);
		TrapezeActor = Cast<ATrapezeActor>(TrapezeInteractionComponent.GetTrapezeActor());

		MarbleReachedTrajectoryEnd.AddUFunction(this, n"OnMarbleReachedTrajectoryEnd");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!WasActionStarted(ActionNames::WeaponFire))
			return EHazeNetworkActivation::DontActivate;

		if(!TrapezeInteractionComponent.IsSwinging())
			return EHazeNetworkActivation::DontActivate;

		if(!TrapezeInteractionComponent.PlayerCanThrowMarble())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{
		if(Network::IsNetworked())
			UMeshPhysicsReplicationComponent::Get(TrapezeActor).RequestInstantReplicationForFrame();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BlockCapabilities();

		// Get marble
		MarbleActor = Cast<ATrapezeMarbleActor>(PlayerPickupComponent.CurrentPickup);

		// Set animation sm flag
		TrapezeActor.AnimationDataComponent.bIsThrowing = true;

		// Wait for animation to release das marble!
		if(HasControl())
			PlayerOwner.BindOneShotAnimNotifyDelegate(UAnimNotify_TrapezeMarbleThrow::StaticClass(), FHazeAnimNotifyDelegate(this, n"OnPlayerReleasedMarble"));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return bMarbleThrown ? EHazeNetworkDeactivation::DeactivateLocal : EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UnblockCapabilities();
		TrapezeActor.AnimationDataComponent.bIsThrowing = false;

		MarbleActor = nullptr;
		bCooldownDone = false;
		bMarbleThrown = false;
	}

	// Returns air travel time
	float ThrowMarble(ATrapezeMarbleActor Marble)
	{
		UStaticMeshComponent MarbleMesh = UStaticMeshComponent::Get(Marble);
		UPickupThrowComponent ThrowComponent = UPickupThrowComponent::GetOrCreate(PlayerOwner);
		UHazeMovementComponent MovementComponent = UHazeMovementComponent::Get(Owner);

		FVector ForwardVector = TrapezeActor.ActorForwardVector;

		// Get forward vector and raise pitch a bit
		FVector ThrowVector = ForwardVector.RotateAngleAxis(-30.f, PlayerOwner.ActorRightVector) * ThrowMagnitude;

		// Add trapeze momentum
		if(TrapezeActor.ActorForwardVector.DotProduct(TrapezeActor.SwingMesh.GetPhysicsLinearVelocity().GetSafeNormal()) > 0.f)
			ThrowVector += TrapezeActor.SwingMesh.GetPhysicsLinearVelocity().ConstrainToDirection(ForwardVector);

		// Adjust marble speed to network latency and shit
		float ThrowSpeed = 1.8f;
		if(IsNetworked() && HasControl() && TrapezeInteractionComponent.BothPlayersAreSwinging())
			ThrowSpeed += Network::GetPingRoundtripSeconds() * 1.8f;

		TArray<AActor> ThrowIgnores;
		ThrowIgnores.Add(TrapezeActor);
		ThrowIgnores.Add(TrapezeActor.OtherTrapeze);

		// Switch control side on marble to the other player to ease catching
		Marble.SetControlSide(PlayerOwner.OtherPlayer);

		// Cast away -use MoveProjectileAlongCurve component replication
		ThrowComponent.Throw_Legacy(Marble, Marble.GetActorLocation(), ThrowVector * Marble.MeshMass, Marble.MeshMass, ThrowSpeed, MarbleReachedTrajectoryEnd, Marble.HasControl(), false, ThrowIgnores);

		// Fire events
		Cast<ATrapezeMarbleActor>(Marble).OnMarbleThrownEvent.Broadcast(PlayerOwner, false);
		if(IsShitThrow())
			TrapezeActor.OnMarbleShitThrowEvent.Broadcast(PlayerOwner, TrapezeActor);

		bMarbleThrown = true;

		return ThrowSpeed;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerReleasedMarble(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkeletalMeshComponent, UAnimNotify AnimNotify)
	{
		if(!HasControl())
			return;

		NetThrowMarble(MarbleActor, MarbleActor.ActorLocation);
	}

	UFUNCTION(NetFunction)
	void NetThrowMarble(ATrapezeMarbleActor NetMarble, FVector StartLocation)
	{
		PlayerOwner.RemoveCapabilitySheet(NetMarble.CarryCapabilitySheet, PlayerOwner);

		PlayerPickupComponent.ThrowRelease();
		float MarbleFlightTime = ThrowMarble(NetMarble);

		// Unblock catching capability after a small delay (if capability finished normally)
		TrapezeInteractionComponent.bJustThrewMarble = true;
		CooldownTimer = System::SetTimer(this, n"OnCooldown", MarbleFlightTime, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnMarbleReachedTrajectoryEnd(AActor ProjectileActor, FVector LastTracedVelocity, FHitResult HitResult, bool bIsControlThrow)
	{
		ATrapezeMarbleActor TrapezeMarble = Cast<ATrapezeMarbleActor>(ProjectileActor);
		TrapezeMarble.LandMarbleAfterThrow();
	}

	UFUNCTION(NotBlueprintCallable)
	void OnCooldown()
	{
		bCooldownDone = true;
		TrapezeInteractionComponent.bJustThrewMarble = false;
		System::ClearAndInvalidateTimerHandle(CooldownTimer);
	}

	bool GetOtherPlayersTrapeze(ATrapezeActor& OutOtherPlayersTrapeze)
	{
		UTrapezeComponent OtherPlayerTrapezeInteraction = UTrapezeComponent::Get(PlayerOwner.GetOtherPlayer());
		if(OtherPlayerTrapezeInteraction == nullptr)
			return false;

		AActor OtherTrapezeActor = OtherPlayerTrapezeInteraction.GetTrapezeActor();
		if(OtherTrapezeActor == nullptr)
			return false;

		OutOtherPlayersTrapeze = Cast<ATrapezeActor>(OtherTrapezeActor);
		return true;
	}

	bool IsShitThrow() const
	{
		if(TrapezeActor.bIsCatchingEnd)
			return false;

		// Arbitrary rule, good enough
		return TrapezeActor.GetCurrentAmplitude() < 35.f;
	}

	void BlockCapabilities()
	{
		PlayerOwner.BlockCapabilities(n"TrapezeMarbleReach", this);
		PlayerOwner.BlockCapabilities(n"TrapezeMarbleCatchTimeDilationEnter", this);
		PlayerOwner.BlockCapabilities(n"TrapezeMarbleWidgetDisplay", this);
	}

	void UnblockCapabilities()
	{
		PlayerOwner.UnblockCapabilities(n"TrapezeMarbleReach", this);
		PlayerOwner.UnblockCapabilities(n"TrapezeMarbleCatchTimeDilationEnter", this);
		PlayerOwner.UnblockCapabilities(n"TrapezeMarbleWidgetDisplay", this);
	}
}