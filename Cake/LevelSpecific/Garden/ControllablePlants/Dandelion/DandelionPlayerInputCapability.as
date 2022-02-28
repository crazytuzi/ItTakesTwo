import Cake.LevelSpecific.Garden.ControllablePlants.Dandelion.Dandelion;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Vino.Tutorial.TutorialStatics;

class UDandelionPlayerInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);

	UControllablePlantsComponent PlantsComp;
	ADandelion Dandelion;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		PlantsComp = UControllablePlantsComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(PlantsComp.CurrentPlant == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!PlantsComp.CurrentPlant.IsA(ADandelion::StaticClass()))
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Dandelion = Cast<ADandelion>(PlantsComp.CurrentPlant);
		Player.ShowCancelPrompt(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.RemoveCancelPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector PlayerInput = GetAttributeVector(AttributeVectorNames::MovementDirection);
		Dandelion.UpdateInput(PlayerInput, WasActionStarted(ActionNames::Cancel));
	}
}
