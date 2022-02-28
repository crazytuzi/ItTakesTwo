import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Vino.Movement.MovementSystemTags;

UCLASS(Deprecated)
class UExitSoilCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"ExitSoil");
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 15;

	AHazePlayerCharacter Player;
	UControllablePlantsComponent PlantsComp;

	float Elapsed = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlantsComp = UControllablePlantsComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!PlantsComp.bCanExitSoil)
			return EHazeNetworkActivation::DontActivate;

		if(WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Elapsed > 0)
			return EHazeNetworkDeactivation::DontDeactivate;
		
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{		
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);

		Elapsed = PlantsComp.ExitSoilAnim.SequenceLength;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Elapsed -= DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.OtherPlayer.EnableOutlineByInstigator(PlantsComp);
	}
}