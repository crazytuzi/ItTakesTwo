import Cake.LevelSpecific.Garden.Sickle.Player.Sickle;
import Cake.LevelSpecific.Garden.Sickle.Player.SickleComponent;
import Cake.LevelSpecific.Garden.Sickle.SickleTags;

class USickleAttackPickComboCapability : UHazeCapability
{
	default CapabilityTags.Add(GardenSickle::Sickle);
	default CapabilityTags.Add(GardenSickle::SickleAttack);
	default CapabilityTags.Add(GardenSickle::SickleComboPicker);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	USickleComponent SickleComp;
	float TimeLeftToDeactivate;
	//bool bHasPendingData = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SickleComp = USickleComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{	
		if (!WasActionStarted(ActionNames::WeaponMelee))
			return EHazeNetworkActivation::DontActivate;
			
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(TimeLeftToDeactivate > 0)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TimeLeftToDeactivate = 0.26f;
		SetMutuallyExclusive(GardenSickle::SickleComboPicker, true);
		Owner.SetCapabilityActionState(GardenSickle::SickleAttack, EHazeActionState::Active);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		TimeLeftToDeactivate = 0;
		Owner.SetCapabilityActionState(GardenSickle::SickleAttack, EHazeActionState::Inactive);
		SetMutuallyExclusive(GardenSickle::SickleComboPicker, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TimeLeftToDeactivate = FMath::Max(TimeLeftToDeactivate - DeltaTime, 0.f);
	}
}

// This is needed so you can pick a combo the frame the last combo was deactivated
class USickleAttackPickNextComboCapability : USickleAttackPickComboCapability
{
	default TickGroupOrder = 101;
}