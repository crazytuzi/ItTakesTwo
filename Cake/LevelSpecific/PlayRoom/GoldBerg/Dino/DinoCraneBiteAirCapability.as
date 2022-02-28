import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCrane;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCraneRidingComponent;

class UDinoCraneBiteAirCapability : UHazeCapability
{
    default CapabilityTags.Add(n"DinoCrane");

    default TickGroup = ECapabilityTickGroups::ActionMovement;

    UHazeBaseMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	AHazePlayerCharacter Player;
	ADinoCrane DinoCrane;
	bool bWasBiting = false;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        MoveComp = UHazeBaseMovementComponent::Get(Owner);
		DinoCrane = Cast<ADinoCrane>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if (DinoCrane.RidingPlayer == nullptr)
			return EHazeNetworkActivation::DontActivate; 
		if (DinoCrane.GrabbedPlatform != nullptr)
			return EHazeNetworkActivation::DontActivate; 
		auto RideComp = GetDinoRidingComponent(DinoCrane);
		if (RideComp.bIsBiting)
			return EHazeNetworkActivation::ActivateFromControl; 
        return EHazeNetworkActivation::DontActivate; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if (DinoCrane.RidingPlayer == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal; 
		if (DinoCrane.GrabbedPlatform != nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal; 

		auto RideComp = GetDinoRidingComponent(DinoCrane);
		if (!RideComp.bIsBiting && ActiveDuration > 1.f)
			return EHazeNetworkDeactivation::DeactivateFromControl; 
        return EHazeNetworkDeactivation::DontDeactivate; 
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		bWasBiting = false;
		Player = DinoCrane.RidingPlayer;
		if (Player != nullptr)
			Player.BlockCapabilities(n"Interaction", this);
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if (!bWasBiting)
		{
			DinoCrane.SetAnimBoolParam(n"DinoCraneBiting", true);
			bWasBiting = true;
		}
		else
		{
			DinoCrane.SetAnimBoolParam(n"DinoCraneBiting", false);
		}
	}

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		if (Player != nullptr)
			Player.UnblockCapabilities(n"Interaction", this);
		DinoCrane.SetAnimBoolParam(n"DinoCraneBiting", false);
	}
};