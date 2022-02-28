// import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.BossControllablePlantCatapult;

// class UBossControllablePlantChargeAndLaunchCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
// 	default CapabilityDebugCategory = n"LevelSpecific";
	
// 	default TickGroup = ECapabilityTickGroups::BeforeMovement;
// 	default TickGroupOrder = 10;

// 	ABossControllablePlantCatapult Plant;


// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		Plant = Cast<ABossControllablePlantCatapult>(Owner);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if(!Plant.bBeingControlled)
// 		{
// 			return EHazeNetworkActivation::DontActivate; 
// 		}
        	
//         return EHazeNetworkActivation::ActivateLocal;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{		
// 		if(!Plant.bBeingControlled)
// 		{
// 			return EHazeNetworkDeactivation::DeactivateLocal; 
// 		}

// 		return EHazeNetworkDeactivation::DontDeactivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 			// Plant.CurrentMashProgress
// 	}


// }
