// import Cake.LevelSpecific.SnowGlobe.Magnetic.Shark.MagneticSharkActor;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticSharkComponent;

// class UMagneticSharkSpotLightCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(n"LevelSpecific");
// 	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
// 	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

// 	UHazeMovementComponent MoveComp; 
// 	AMagneticSharkActor Shark; 

// 	FRotator StartRotation;

// 	float SpotLightRotationSpeed = 90.f; 

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		Shark = Cast<AMagneticSharkActor>(Owner);
// 		MoveComp = Shark.MovementComponent;
// 		StartRotation = Shark.VisionRoot.RelativeRotation; 
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		return EHazeNetworkActivation::ActivateFromControl;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		return EHazeNetworkDeactivation::DontDeactivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 	}


// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		Shark.VisionRoot.SetWorldRotation(StartRotation);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		FRotator TargetRotation;

// 		if(Shark.TargetPlayer != nullptr)
// 		{
// 			FVector Direction = Shark.TargetPlayer.ActorLocation - Shark.VisionRoot.WorldLocation;
// 			TargetRotation = FRotator::MakeFromX(Direction);
// 		}
// 		else
// 		{
// 			//Turns rotator into world location from relative
// 			FQuat QuatRotation = Shark.ActorTransform.TransformRotation(StartRotation.Quaternion());
// 			TargetRotation = QuatRotation.Rotator();
// 		}
// 		//HOW fast we tunr spotlight
// 		FRotator NewRotation = FMath::RInterpConstantTo(Shark.VisionRoot.WorldRotation, TargetRotation, DeltaTime, SpotLightRotationSpeed);
// 		Shark.VisionRoot.SetWorldRotation(NewRotation);
// 	}



// }