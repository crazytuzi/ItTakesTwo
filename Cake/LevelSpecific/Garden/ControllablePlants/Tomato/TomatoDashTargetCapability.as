import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.Tomato;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoTargetComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;

class UTomatoDashTargetCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"LevelSpecific";
	default CapabilityTags.Add(n"LevelSpecific");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	
	UTomatoTargetComponent TargetComp;
	UControllablePlantsComponent PlantsComp;
	AHazePlayerCharacter Player;
	UTomatoSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlantsComp = UControllablePlantsComponent::Get(Owner);
		TargetComp = UTomatoTargetComponent::Get(Owner);
		devEnsure(TargetComp != nullptr, "No TargetComponent");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(PlantsComp.CurrentPlant == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Settings = UTomatoSettings::GetSettings(PlantsComp.CurrentPlant);
		TargetComp.SetTomatoSettings(Settings);
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
		TargetComp.ClearTargets();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			//TargetComp.UpdateForwardVector(GetAttributeVector(AttributeVectorNames::MovementDirection).GetSafeNormal());
			TargetComp.UpdateTargets();
		}
		else
		{
			TargetComp.ClearNullTargets();
		}
	}
}
