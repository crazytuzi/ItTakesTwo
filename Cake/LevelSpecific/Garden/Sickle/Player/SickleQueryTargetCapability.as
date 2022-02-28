import Cake.LevelSpecific.Garden.Sickle.Player.SickleComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;
import Cake.LevelSpecific.Garden.Sickle.SickleTags;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseComponent;

class USickleQueryTargetCapability : UHazeCapability
{
	default CapabilityTags.Add(GardenSickle::Sickle);
	default CapabilityTags.Add(GardenSickle::SickleQuery);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 50;

  	AHazePlayerCharacter Player;
	USickleComponent SickleComp;
	UWaterHoseComponent WaterHoseComp;
	bool bMadeAlerted = false;

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SickleComp = USickleComponent::Get(Player);
		WaterHoseComp = UWaterHoseComponent::Get(Player);
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {	
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		TArray<FHazeQueriedActivationPoint> Querries;

		// We make the active point, the only point if we have one.
		FHazeQueriedActivationPoint ActivePoint;
		if(Player.GetActivePoint(USickleCuttableComponent::StaticClass(), ActivePoint))
			Player.UpdateActivationPointWidget(ActivePoint);
		else if(!WaterHoseComp.bWaterHoseActive)
			Player.UpdateActivationPointAndWidgets(USickleCuttableComponent::StaticClass());
		
		// Make alerted
		if(!bMadeAlerted && Querries.Num() > 0)
		{		
			bMadeAlerted = true;
			SickleComp.EnableCombatStance(true);	
		}
		else if(bMadeAlerted && Querries.Num() <= 0)
		{
			// Back to relaxed
			bMadeAlerted = false;
			SickleComp.DisableCombatStance();
		}
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
      
	}  
}