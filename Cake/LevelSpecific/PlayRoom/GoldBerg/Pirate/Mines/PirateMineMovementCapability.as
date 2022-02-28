// import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.Mines.PirateMovingMineActor;

// class UPirateMineMovementCapability : UHazeCapability
// {
//     default CapabilityTags.Add(n"PirateEnemy");

// 	APirateMovingMineActor Mine;

//     UFUNCTION(BlueprintOverride)
//     void Setup(FCapabilitySetupParams Params)
//     {
// 		Mine = Cast<APirateMovingMineActor>(Owner);	
//     }

//     UFUNCTION(BlueprintOverride)
//     EHazeNetworkActivation ShouldActivate() const
//     {
//         if(!Mine.bOnSurface)
// 			return EHazeNetworkActivation::DontActivate;

//         return EHazeNetworkActivation::ActivateLocal; 
//     }

//     UFUNCTION(BlueprintOverride)
//     EHazeNetworkDeactivation ShouldDeactivate() const
//     {
//          if(!Mine.bOnSurface)
// 			return EHazeNetworkDeactivation::DeactivateLocal;
				
//         return EHazeNetworkDeactivation::DontDeactivate; 
//     }

//     UFUNCTION(BlueprintOverride)
//     void OnActivated(FCapabilityActivationParams ActivationParams)
//     {
//     }

//     UFUNCTION(BlueprintOverride)
//     void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
//     {
//     }

//     UFUNCTION(BlueprintOverride)
//     void TickActive(float DeltaTime)
//     {


//     }
// };