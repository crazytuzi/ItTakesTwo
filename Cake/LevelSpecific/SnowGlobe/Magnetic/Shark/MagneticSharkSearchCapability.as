// import Cake.LevelSpecific.SnowGlobe.Magnetic.Shark.MagneticSharkActor;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticSharkComponent;

// class UMagneticSharkSearchCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(n"LevelSpecific");
// 	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
// 	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

// 	float CurrentDistanceOnSpline;
// 	float SpeedAlongSpline = 4000.f;
// 	FVector TargetDirection;
	
// 	UHazeMovementComponent MoveComp; 

// 	AMagneticSharkActor Shark;

// 	bool bFoundPlayer = false;
 

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		Shark = Cast<AMagneticSharkActor>(Owner);
// 		MoveComp = Shark.MovementComponent;

// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if (Shark.CurrentState != EMagneticSharkState::Searching)
//             return EHazeNetworkActivation::DontActivate;

//         else
// 			return EHazeNetworkActivation::ActivateFromControl;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if (Shark.CurrentState == EMagneticSharkState::Searching)
//             return EHazeNetworkDeactivation::DontDeactivate;
//         else
//             return EHazeNetworkDeactivation::DeactivateFromControl;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		bFoundPlayer = false; 
// 	}


// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 			if(!MoveComp.CanCalculateMovement())
// 		{
// 			return;
// 		}
		
// 		//SPLINEMOVEMENT

// 		CurrentDistanceOnSpline += SpeedAlongSpline * DeltaTime; 
// 		FVector CurrentLocation = Shark.SplineToFollow.Spline.GetLocationAtDistanceAlongSpline(CurrentDistanceOnSpline, ESplineCoordinateSpace::World);
// 		//FRotator CurrentRotation = Shark.SplineToFollow.Spline.GetRotationAtDistanceAlongSpline(CurrentDistanceOnSpline, ESplineCoordinateSpace::World); 

// 		if (CurrentDistanceOnSpline >= Shark.SplineToFollow.Spline.SplineLength)
// 		{
// 			CurrentDistanceOnSpline = 0.f; 
// 		}

// 		TargetDirection = CurrentLocation - Shark.ActorLocation; 
// 		TargetDirection.Normalize();
// 		Shark.Velocity += TargetDirection * Shark.AttackAcceleration * DeltaTime;
// 		Shark.Velocity -= Shark.Velocity * Shark.Drag * DeltaTime; 

// 		Move(DeltaTime);

// 		//DETECT PLAYERS: 
		
// 		if(bFoundPlayer)
// 		{
// 			return;
// 		}

// 		TArray<AActor> OverlappingActors;
// 		Shark.VisionCone.GetOverlappingActors(OverlappingActors);
// 		for(AActor Actor : OverlappingActors)
// 		{
// 			if(Actor == Game::GetMay() || Actor == Game::GetCody())
// 			{
// 				FHitResult Hit; 
// 				TArray<AActor> ActorsToIgnore; 
// 				System::LineTraceSingle(Shark.ActorLocation, Actor.ActorLocation, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);
				
// 				if(Hit.bBlockingHit && Hit.Actor == Actor)
// 				{
// 					//bFoundPlayer = true;
// 					Shark.TargetPlayer = Cast<AHazePlayerCharacter>(Actor);
// 					Shark.CurrentState = EMagneticSharkState::Attacking;
// 					return;
// 				}
// 			}
// 		}
// 	}

// 	void Move(float DeltaTime)
// 	{
// 		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SharkSearching");

// 		FrameMove.ApplyVelocity(Shark.Velocity);
// 		MoveComp.SetTargetFacingDirection(TargetDirection, 1.f);
// 		FrameMove.ApplyTargetRotationDelta();
// 		MoveComp.Move(FrameMove);
// 	}

// }