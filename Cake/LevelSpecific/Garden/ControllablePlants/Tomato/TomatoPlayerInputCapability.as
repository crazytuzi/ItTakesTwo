import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoTags;
import Peanuts.Fades.FadeStatics;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.Tomato;

class UTomatoPlayerInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	FVector TomatoLocationWhenCanceled;
	UControllablePlantsComponent PlantsComp;
	ATomato CurrentTomato;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlantsComp = UControllablePlantsComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;
		
		if (PlantsComp.CurrentPlant == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!PlantsComp.CurrentPlant.IsA(ATomato::StaticClass()))
			return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentTomato = Cast<ATomato>(PlantsComp.CurrentPlant);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(PlantsComp.CurrentPlant == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		TomatoLocationWhenCanceled = CurrentTomato.ActorLocation;
		CurrentTomato.UpdatePlayerInput(FVector::ZeroVector, false, false, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector PlayerInput = GetAttributeVector(AttributeVectorNames::MovementDirection);
		const bool bWantsToDash = WasActionStarted(ActionNames::TomatoDash);
		CurrentTomato.UpdatePlayerInput(PlayerInput, WasActionStarted(ActionNames::MovementJump), IsActioning(ActionNames::MovementJump), bWantsToDash);
	}
}
