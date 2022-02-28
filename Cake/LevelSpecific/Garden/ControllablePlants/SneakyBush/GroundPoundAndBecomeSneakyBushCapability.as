import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.MoleStealth.MoleStealthSystem;
import Cake.LevelSpecific.Garden.ControllablePlants.SneakyBush.SneakyBush;


class UGroundPoundAndBecomeSneakyBushCapability : UHazeCapability
{
	AHazePlayerCharacter PlayerOwner;
	UCharacterGroundPoundComponent GroundPoundComponent;
	UControllablePlantsComponent PlantsComponent;
	UMoleStealthPlayerComponent ManagerComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		GroundPoundComponent = UCharacterGroundPoundComponent::Get(Owner);
		PlantsComponent = UControllablePlantsComponent::Get(Owner);
		ManagerComponent = UMoleStealthPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!GroundPoundComponent.IsCurrentState(EGroundPoundState::Landing))
			return EHazeNetworkActivation::DontActivate;

		if(!CanGroundPoundIntoSneakyBush(PlayerOwner))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(GroundPoundComponent.IsCurrentState(EGroundPoundState::Landing))
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"LinkedSoil", PlantsComponent.LinkedActivatingSoil);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		auto LinkedActivatingSoil = Cast<USubmersibleSoilComponent>(ActivationParams.GetObject(n"LinkedSoil"));
		ActivateSubmersibleSoilComponent(LinkedActivatingSoil, PlayerOwner);
	}
}
