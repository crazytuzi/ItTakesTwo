import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCraneRidingComponent;

class UDinoCranePlayerRideCapability : UHazeCapability
{
	default CapabilityTags.Add(n"DinoCrane");
	default TickGroup = ECapabilityTickGroups::ActionMovement;

	AHazePlayerCharacter Player;
	UDinoCraneRidingComponent RideComp;

	ADinoCrane DinoCrane;
	FVector InitialCapsuleOffset;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams& Params)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		RideComp = UDinoCraneRidingComponent::GetOrCreate(Owner);
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (RideComp.DinoCrane == nullptr)
            return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (RideComp.DinoCrane == nullptr)
            return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

    UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		DinoCrane = RideComp.DinoCrane;
		OutParams.AddObject(n"DinoCrane", DinoCrane);
	}

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		DinoCrane = Cast<ADinoCrane>(ActivationParams.GetObject(n"DinoCrane"));

		Player.AttachToComponent(DinoCrane.RideInteraction);
		InitialCapsuleOffset = Player.CapsuleComponent.RelativeLocation;
		Player.CapsuleComponent.AttachToComponent(DinoCrane.Mesh, n"Head");
		Player.DisableOutlineByInstigator(this);
		Player.OtherPlayer.DisableOutlineByInstigator(this);
	}

    UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		Player.DetachRootComponentFromParent();
		Player.TriggerMovementTransition(this);

		Player.CapsuleComponent.AttachToComponent(Player.RootComponent);
		Player.CapsuleComponent.RelativeLocation = InitialCapsuleOffset;

		// Perform a jumpto back to a jump off point so we're not stuck in the lever
		if ((DeactivationParams.DeactivationReason == ECapabilityStatusChangeReason::Natural
			|| DeactivationParams.DeactivationReason == ECapabilityStatusChangeReason::Removed)
			&& DinoCrane != nullptr)
		{
			FHazeJumpToData JumpToData;
			JumpToData.TargetComponent = DinoCrane.RideJumpOffPoint;
			JumpTo::ActivateJumpTo(
				Player,
				JumpToData
			);
		}

		if (DinoCrane != nullptr)
			Player.RemoveCapabilitySheet(DinoCrane.RideSheet, DinoCrane);
		Player.EnableOutlineByInstigator(this);
		Player.OtherPlayer.EnableOutlineByInstigator(this);

		DinoCrane = nullptr;
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
    }
};