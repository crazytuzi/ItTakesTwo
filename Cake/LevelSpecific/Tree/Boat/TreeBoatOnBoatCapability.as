import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Tree.Boat.TreeBoatComponent;

class UTreeBoatOnBoatCapability : UHazeCapability
{
	default CapabilityTags.Add(n"TreeBoat");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UTreeBoatComponent TreeBoatComponent;

	ATreeBoat TreeBoat;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		TreeBoatComponent = UTreeBoatComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!System::IsValid(TreeBoat))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(WasActionStarted(ActionNames::MovementJump))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!System::IsValid(TreeBoatComponent.ActiveTreeBoat))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"TreeBoat", TreeBoat);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TreeBoat = Cast<ATreeBoat>(ActivationParams.GetObject(n"TreeBoat"));
		TreeBoatComponent.BindTreeBoat(TreeBoat);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		TreeBoatComponent.UnbindTreeBoat();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (HasControl())
			TreeBoat = Cast<ATreeBoat>(MoveComp.GetDownHit().Actor);
	}

}