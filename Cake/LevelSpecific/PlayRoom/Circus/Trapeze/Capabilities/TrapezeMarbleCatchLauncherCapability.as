import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeActor;

class UTrapezeMarbleCatchLauncherCapability : UHazeCapability
{
	default CapabilityTags.Add(TrapezeTags::Trapeze);
	default CapabilityTags.Add(TrapezeTags::MarbleCatchLauncher);

	default TickGroup = ECapabilityTickGroups::ActionMovement;

	default CapabilityDebugCategory = TrapezeTags::Trapeze;

	AHazePlayerCharacter PlayerOwner;
	UTrapezeComponent TrapezeComponent;

	ATrapezeActor Trapeze;
	ATrapezeMarbleActor Marble;

	const float CapabilityDuration = 0.8f;
	float ElapsedTime;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		TrapezeComponent = UTrapezeComponent::Get(Owner);
		Trapeze = Cast<ATrapezeActor>(TrapezeComponent.GetTrapezeActor());
		Marble = Trapeze.Marble;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!WasActionStarted(ActionNames::InteractionTrigger))
			return EHazeNetworkActivation::DontActivate;

		if(PlayerOwner.IsAnyCapabilityActive(TrapezeTags::MarbleCatch))
			return EHazeNetworkActivation::DontActivate;

		if(!TrapezeComponent.IsSwinging())
			return EHazeNetworkActivation::DontActivate;

		if(TrapezeComponent.PlayerHasMarble())
			return EHazeNetworkActivation::DontActivate;

		if(Marble.IsPickedUp())
			return EHazeNetworkActivation::DontActivate;

		if(Marble.IsAnyCapabilityActive(PickupTags::PickupSystem))
			return EHazeNetworkActivation::DontActivate;

		if(TrapezeComponent.OtherPlayerTrapezeComponent.PlayerHasMarble())
			return EHazeNetworkActivation::DontActivate;

		if(TrapezeComponent.bJustCaughtMarble)
			return EHazeNetworkActivation::DontActivate;
		
		if(TrapezeComponent.bJustThrewMarble)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!TrapezeComponent.IsSwinging())
			return;

		if(!Trapeze.bIsCatchingEnd)
			return;

		if(Trapeze.Marble.IsMarbleWithinReach(PlayerOwner))
			Marble.bWasWithinReachOfCatcherSide = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Restart counter if button is pressed again
		if(WasActionStarted(ActionNames::InteractionTrigger))
			ElapsedTime = 0.f;

		ElapsedTime += DeltaTime;

		// Check if marble is nearby and can be picked up
		if(TrapezeComponent.IsMarbleWithinReach() && TrapezeComponent.PlayerCanCatchMarble())
			TrapezeComponent.bStartCatching = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ElapsedTime >= CapabilityDuration)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(TrapezeComponent.bStartCatching)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(!TrapezeComponent.IsSwinging())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(TrapezeComponent.PlayerHasMarble())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(TrapezeComponent.OtherPlayerTrapezeComponent.PlayerHasMarble())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		TrapezeComponent.bStartCatching = false;
		ElapsedTime = 0.f;
	}
}