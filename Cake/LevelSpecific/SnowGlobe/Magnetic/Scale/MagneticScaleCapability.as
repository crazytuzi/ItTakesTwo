// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Scale.MagneticScaleActor;

// class UMagneticScaleCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(n"MagnetCapability");
// 	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
// 	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

//     AMagneticScaleActor MagneticScaleActor;

// 	//float LeftTotalAdded = 0.0f;
// 	float RightTotalAdded = 0.0f;

// 	// float LeftPercentage;
// 	float RightPercentage;

// 	float TotalCurrentSpeed = 0.0f;

// 	bool bActivatedFinish = false;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		MagneticScaleActor = Cast<AMagneticScaleActor>(Owner);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
//         if (MagneticScaleActor.bActivated)
// 			return EHazeNetworkActivation::ActivateFromControl;
        
//         else
//             return EHazeNetworkActivation::DontActivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if (MagneticScaleActor.bActivated)
//             return EHazeNetworkDeactivation::DontDeactivate;
// 		// if (!FMath::IsNearlyZero(LeftTotalAdded, 0.1f))
//         //     return EHazeNetworkDeactivation::DontDeactivate;
// 		if (!FMath::IsNearlyZero(RightTotalAdded, 0.1f))
//             return EHazeNetworkDeactivation::DontDeactivate;
//         else
//             return EHazeNetworkDeactivation::DeactivateFromControl;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		if(!MagneticScaleActor.bOnlyActivateWhenFinished)
// 			MagneticScaleActor.OnMagneticScaleStateChanged.Broadcast(true);
// 	}


// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		MagneticScaleActor.OnMagneticScaleStateChanged.Broadcast(false);
// 		MagneticScaleActor.TotalCurrentSpeed = 0.0f;
// 		bActivatedFinish = false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		TotalCurrentSpeed = 0.0f;

// 		if(MagneticScaleActor.MagneticComponent.bActivated)
// 		{
// 			if(RightTotalAdded != MagneticScaleActor.HowFarDownToPull)
// 				MoveComponentWithMagneticForce(MagneticScaleActor.MagneticComponent, MagneticScaleActor.Base, DeltaTime);
// 		}
// 		else
// 		{
// 			if(RightTotalAdded != 0.0f)
// 				MoveComponentToOriginalState(MagneticScaleActor.MagneticComponent, MagneticScaleActor.Base, DeltaTime);
// 		}

// 		// if(MagneticScaleActor.LeftMagnetComponent.bActivated)
// 		// {
// 		// 	if(LeftTotalAdded != MagneticScaleActor.HowFarDownToPull)
// 		// 		MoveComponentWithMagneticForce(MagneticScaleActor.LeftMagnetComponent, MagneticScaleActor.LeftBase, DeltaTime, false);
// 		// }
// 		// else
// 		// {
// 		// 	if(LeftTotalAdded != 0.0f)
// 		// 		MoveComponentToOriginalState(MagneticScaleActor.LeftMagnetComponent, MagneticScaleActor.LeftBase, DeltaTime, false);
// 		// }

// 		RightPercentage = RightTotalAdded / MagneticScaleActor.HowFarDownToPull;

// 		float TotalPercentage = RightPercentage;
// 		//float TotalPercentage = (RightPercentage + LeftPercentage) / 2.0f;
// 		TotalPercentage = FMath::Clamp(TotalPercentage, 0.0f, 1.0f);
// 		MagneticScaleActor.TotalPercentage = TotalPercentage;

// 		MagneticScaleActor.TotalCurrentSpeed = TotalCurrentSpeed;

// 		if(MagneticScaleActor.bOnlyActivateWhenFinished && !bActivatedFinish)
// 		{
// 			if(MagneticScaleActor.bActivateWhenHalfOfScaleIsFinished && TotalPercentage >= 0.5f)
// 			{
// 				MagneticScaleActor.OnMagneticScaleStateChanged.Broadcast(true);
// 				bActivatedFinish = true;
// 			}
// 			else if(TotalPercentage >= 1.0f)
// 			{
// 				MagneticScaleActor.OnMagneticScaleStateChanged.Broadcast(true);
// 				bActivatedFinish = true;
// 			}
// 		}
// 	}

// 	UFUNCTION()
// 	void MoveComponentWithMagneticForce(UMagneticScaleComponent MagneticComponent, USceneComponent ComponentToMove, float DeltaTime)
// 	{
// 		float TotalAdded;		
// 		TotalAdded = RightTotalAdded;

// 		float ZMovement = 0.0f;
// 		for(AHazePlayerCharacter Player : MagneticComponent.UsingPlayers)
// 		{
// 			float ForceMovement;
// 			ForceMovement = MagneticScaleActor.PullDownSpeed * DeltaTime;

// 			int Index = MagneticComponent.UsingPlayers.FindIndex(Player);
// 			if(!MagneticComponent.bOpposite[Index])
// 			{
// 				ForceMovement *= -1.0f;
// 			}

// 			ZMovement += ForceMovement;
// 		}
		
// 		if(TotalAdded + ZMovement > MagneticScaleActor.HowFarDownToPull)
// 			ZMovement = MagneticScaleActor.HowFarDownToPull - TotalAdded;
// 		else if(TotalAdded + ZMovement < MagneticScaleActor.HowFarUpToPush)
// 			ZMovement = MagneticScaleActor.HowFarUpToPush - TotalAdded;				

// 		FVector DeltaMovement = FVector(0, 0, ZMovement);
// 		ComponentToMove.AddLocalOffset(-DeltaMovement);
		
// 		TotalAdded += ZMovement;

// 		TotalCurrentSpeed += -ZMovement;


// 		RightTotalAdded = TotalAdded;
// 	}

// 	UFUNCTION()
// 	void MoveComponentToOriginalState(UMagneticScaleComponent MagneticComponent, USceneComponent ComponentToMove, float DeltaTime)
// 	{
// 		float TotalAdded;		
// 		TotalAdded = RightTotalAdded;

// 		float ZMovement = MagneticScaleActor.ReturnSpeed * DeltaTime;

// 		if(TotalAdded > 0)
// 		{
// 			ZMovement *= -1.0f;
// 		}

// 		FVector DeltaMovement = FVector(0, 0, ZMovement);
// 		ComponentToMove.AddLocalOffset(-DeltaMovement);
// 		TotalAdded += ZMovement;
// 		TotalCurrentSpeed += -ZMovement;

// 		RightTotalAdded = TotalAdded;
// 	}
	
// }