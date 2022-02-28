import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeActor;
import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeAnimNotifies;

class UTrapezeMarbleCatchCapability : UHazeCapability
{
	default CapabilityTags.Add(TrapezeTags::Trapeze);
	default CapabilityTags.Add(TrapezeTags::MarbleCatch);

	AHazePlayerCharacter PlayerOwner;
	USkeletalMeshComponent PlayerMesh;
	UPlayerPickupComponent PickupComponent;
	UTrapezeComponent TrapezeComponent;

	ATrapezeMarbleActor Marble;
	ATrapezeActor Trapeze;

	// Lerping marble to catch socket stuff
	// Lerp time is oddly small to compensate for time dilation
	FVector LerpOrigin, LerpDestination;
	float LerpAlpha;
	float LerpTime = 0.01f;

	float PreviousDistanceToMarble;

	bool bAnimationDone;
	bool bMarbleIsLerpingToPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PlayerMesh = USkeletalMeshComponent::Get(Owner);
		PickupComponent = UPlayerPickupComponent::Get(Owner);

		TrapezeComponent = UTrapezeComponent::Get(Owner);
		Trapeze = Cast<ATrapezeActor>(TrapezeComponent.GetTrapezeActor());
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!TrapezeComponent.bStartCatching)
			return EHazeNetworkActivation::DontActivate;

		if(TrapezeComponent.OtherPlayerIsSwinging())
			return EHazeNetworkActivation::ActivateFromControl;

		// Use remote validation if other player is not on trapeze, otherwise he
		// could try to grab from platform while this player swings
		return EHazeNetworkActivation::ActivateFromControlWithValidation;
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		if(PlayerOwner.OtherPlayer.IsAnyCapabilityActive(PickupTags::PickupCapability))
			return false;

		if(!Trapeze.Marble.IsReadyForPickUp())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BlockCapabilities();

		TrapezeComponent.bStartCatching = false;

		// Synch caught marble
		Marble = Cast<ATrapezeMarbleActor>(Trapeze.Marble);

		// Set control side
		Marble.SetControlSide(this);

		// Get initial distance to marble
		PreviousDistanceToMarble = GetDistanceToMarble();

		Trapeze.AnimationDataComponent.bIsReaching = true;

		PlayerOwner.BindAnimNotifyDelegate(UAnimNotify_TrapezeMarbleCaught::StaticClass(), FHazeAnimNotifyDelegate(this, n"OnMarbleCaught"));
		LerpAlpha = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		// Start lerping to player only when marble is at its closest point
		if(bMarbleIsLerpingToPlayer)
		{
			LerpAlpha += FMath::Sqrt(DeltaTime / LerpTime);
			if(LerpAlpha >= 1.f)
			{
				bMarbleIsLerpingToPlayer = false;
				NetCatchMarble(Marble);

				return;
			}

			LerpDestination = PlayerMesh.GetSocketLocation(Trapeze.CatchSocketName);
			Marble.SetActorLocation(FMath::Lerp(LerpOrigin, LerpDestination, LerpAlpha));
		}
		else
		{
			if(MarbleIsMovingFurtherAway() && LerpAlpha == 0)
			{
				bMarbleIsLerpingToPlayer = true;
				LerpOrigin = Marble.ActorLocation;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bAnimationDone)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UnblockCapabilities();

		Marble = nullptr;
		bAnimationDone = false;
	
		Trapeze.AnimationDataComponent.bIsReaching = false;
		Trapeze.AnimationDataComponent.bIsCatching = false;
	}

	UFUNCTION(NetFunction)
	void NetCatchMarble(ATrapezeMarbleActor NetMarble)
	{
		// Net safety ftw
		Marble = NetMarble;

		// Set locomotion sm flag
		Trapeze.AnimationDataComponent.bIsCatching = true;

		// Gotta deactivate marble's trajectory follower
		bool bWasMarbleAirborne = Marble.IsAirborne();
		Marble.ProjectileAlongCurveComponent.Stop();

		// Pick that shit up!
		UStaticMeshComponent MarbleMesh = UStaticMeshComponent::Get(Marble);
		MarbleMesh.SetSimulatePhysics(false);
		UPlayerPickupComponent::Get(PlayerOwner).ForcePickUp(Marble, false, false, Trapeze.CatchSocketName);

		// Clear over-damping set by other player
		Trapeze.ResetSwingLinearDamping();

		// Turn on marble timer
		TrapezeComponent.bJustCaughtMarble = true;
		System::SetTimer(this, n"OnCooldown", 1.f, false);

		// Fire event!
		if(bWasMarbleAirborne && Trapeze.bIsCatchingEnd)
			Trapeze.OnMarbleCaughtEvent.Broadcast();
	}

	UFUNCTION(NotBlueprintCallable)
	void OnMarbleCaught(AHazeActor PlayerActor, UHazeSkeletalMeshComponentBase PlayerMesh, UAnimNotify AnimNotify)
	{
		bAnimationDone = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnCooldown()
	{
		if(TrapezeComponent != nullptr)
			TrapezeComponent.bJustCaughtMarble = false;
	}

	bool MarbleIsMovingFurtherAway()
	{
		float CurrentDistanceToMarble = GetDistanceToMarble();
		if(PreviousDistanceToMarble < CurrentDistanceToMarble)
			return true;

		PreviousDistanceToMarble = CurrentDistanceToMarble;
		return false;
	}

	float GetDistanceToMarble()
	{
 		return PlayerMesh.GetSocketLocation(Trapeze.CatchSocketName).Distance(Marble.GetActorLocation());
	}

	void BlockCapabilities()
	{
		PlayerOwner.BlockCapabilities(n"TrapezeMarbleThrow", this);
		PlayerOwner.BlockCapabilities(n"TrapezeMarbleWidgetDisplay", this);
	}

	void UnblockCapabilities()
	{
		PlayerOwner.UnblockCapabilities(n"TrapezeMarbleThrow", this);
		PlayerOwner.UnblockCapabilities(n"TrapezeMarbleWidgetDisplay", this);
	}
}