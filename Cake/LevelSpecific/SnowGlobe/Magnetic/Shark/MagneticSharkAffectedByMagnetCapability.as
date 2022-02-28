// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Shark.MagneticSharkActor;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticSharkComponent;

// class UMagneticSharkAffectedByMagnetCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(n"MagnetCapability");
// 	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
// 	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

// 	AMagneticSharkActor Shark; 
// 	UMagneticSharkComponent MagnetComponent;

	
// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
//         MagnetComponent = UMagneticSharkComponent::Get(Owner);
//         Shark = Cast<AMagneticSharkActor>(Owner);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if(Shark.bAffectedByMagnet)
// 			return EHazeNetworkActivation::ActivateFromControl;

//         else
//             return EHazeNetworkActivation::DontActivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if (Shark.bAffectedByMagnet)
//             return EHazeNetworkDeactivation::DontDeactivate;
//         else
//             return EHazeNetworkDeactivation::DeactivateFromControl;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		Print("Activated", 1.f);
// 	}


// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
		
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{

// 		for(AHazePlayerCharacter Player : MagnetComponent.UsingPlayers)
// 		{
// 			int PlayerIndex = MagnetComponent.UsingPlayers.FindIndex(Player);
// 			if(MagnetComponent.bOpposite[PlayerIndex])
// 			{
// 				//IF OPPOSUITE
// 				Print("OPPOSUITE");
// 			}
			
// 			if(!MagnetComponent.bOpposite[PlayerIndex])
// 			{
// 				//IF SAME
// 				Print("SAME");
// 				Shark.CurrentState = EMagneticSharkState::Searching;
// 			}
// 		} 
// 	}
// }