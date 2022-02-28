// import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.Mines.PirateMineActor;

// class UPirateMineMoveToSurfaceCapability : UHazeCapability
// {
//     default CapabilityTags.Add(n"PirateEnemy");

// 	APirateMineActor Mine;

// 	bool bWheelBoatDetected = false;

// 	AWheelBoatActor WheelBoat;
	
//     UFUNCTION(BlueprintOverride)
//     void Setup(FCapabilitySetupParams Params)
//     {
// 		Mine = Cast<APirateMineActor>(Owner);

// 		if(!HasControl())
// 			return;

// 		Mine.DetectionCollider.OnComponentBeginOverlap.AddUFunction(this, n"EnterDetection");
// 		Mine.DetectionCollider.OnComponentEndOverlap.AddUFunction(this, n"ExitDetection");
//     }

// 	UFUNCTION(NotBlueprintCallable)
// 	void EnterDetection(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
// 	{
// 		AWheelBoatActor Boat = Cast<AWheelBoatActor>(OtherActor);

// 		if (Boat == nullptr)
// 			return;

// 		if(!Mine.bOnSurface)
// 		{
// 			bWheelBoatDetected = true;
// 			WheelBoat = Boat;
// 			Mine.EnemyComponent.WheelBoat = WheelBoat;
// 		}
// 		else
// 		{
// 			Mine.EnemyComponent.bFacePlayer = true;
// 		}
// 	}

// 	UFUNCTION(NotBlueprintCallable)
// 	void ExitDetection(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
// 	{
// 		AWheelBoatActor Boat = Cast<AWheelBoatActor>(OtherActor);

// 		if (Boat == nullptr)
// 			return;
		
// 		Mine.EnemyComponent.bFacePlayer = false;
// 	}

//     UFUNCTION(BlueprintOverride)
//     EHazeNetworkActivation ShouldActivate() const
//     {
//         if(bWheelBoatDetected)
// 			return EHazeNetworkActivation::DontActivate;

//         return EHazeNetworkActivation::ActivateFromControl; 
//     }

//     UFUNCTION(BlueprintOverride)
//     EHazeNetworkDeactivation ShouldDeactivate() const
//     {
//          if(Mine.bOnSurface)
// 			return EHazeNetworkDeactivation::DeactivateFromControl;
				
//         return EHazeNetworkDeactivation::DontDeactivate; 
//     }

//     UFUNCTION(BlueprintOverride)
//     void OnActivated(FCapabilityActivationParams ActivationParams)
//     {
// 		PlayFloatUpAnimation();
// 		Mine.PostFloatUpAudioEvent();
//     }

// 	void PlayFloatUpAnimation()
// 	{
// 		FHazeAnimationDelegate OnBlendingIn;
// 		FHazeAnimationDelegate OnBlendingOut;
		
// 		FHazePlaySlotAnimationParams SlotAnimParams;
// 		SlotAnimParams.Animation = Mine.FloatUpAnimation.Sequence;
// 		SlotAnimParams.PlayRate = Mine.FloatUpAnimation.PlayRate;
// 		SlotAnimParams.bLoop = true;

// 		Mine.SkeletalMesh.PlaySlotAnimation(
// 			OnBlendingIn, 
// 			OnBlendingOut,
// 			SlotAnimParams
// 			);
// 	}


//     UFUNCTION(BlueprintOverride)
//     void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
//     {
// 		if(Mine.DetectionCollider.IsOverlappingActor(WheelBoat))
// 		{
// 			Mine.EnemyComponent.bFacePlayer = true;			
// 		}
//     }

//     UFUNCTION(BlueprintOverride)
//     void TickActive(float DeltaTime)
//     {
// 		if(Mine.SkeletalMesh.RelativeLocation.Z < 0.0f)
// 		{
// 			Mine.SkeletalMesh.SetRelativeLocation(FVector(0.0f, 0.0f, FMath::Lerp(Mine.StartZLocation, 0.0f, DeltaTime * Mine.VerticalSpeed)));
// 		}
// 		else
// 		{
// 			Mine.bOnSurface = true;
// 		}
//     }
// };