import Peanuts.Outlines.Outlines;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Vino.Movement.MovementSystemTags;

class UEnterSoilCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 12;

	AHazePlayerCharacter Player;
	UControllablePlantsComponent PlantsComp;
	USubmersibleSoilComponent ActivatingSoil;

	float Elapsed = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlantsComp = UControllablePlantsComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!PlantsComp.bEnterSoil)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Elapsed > 0.0f)
			return EHazeNetworkDeactivation::DontDeactivate;
		
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"ActivatingSoil", PlantsComp.ActivatingSoil);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlantsComp.ActivatingSoil = ActivatingSoil = Cast<USubmersibleSoilComponent>(ActivationParams.GetObject(n"ActivatingSoil"));
		Niagara::SpawnSystemAtLocation(PlantsComp.EnterSoilVFX, Player.ActorLocation);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(n"Vine", this);
		Player.OtherPlayer.DisableOutlineByInstigator(PlantsComp);

		Elapsed = PlantsComp.EnterSoilAnim.SequenceLength;
		PlantsComp.PlayEnterSoilAnimation();
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
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(n"Vine", this);
		PlantsComp.ActivatePlant(ActivatingSoil.PlantClass);
		PlantsComp.bEnterSoil = false;
	}
}
