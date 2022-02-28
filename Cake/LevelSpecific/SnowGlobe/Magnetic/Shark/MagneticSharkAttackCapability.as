// import Cake.LevelSpecific.SnowGlobe.Magnetic.Shark.MagneticSharkActor;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticSharkComponent;

// class UMagneticSharkAttackCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(n"LevelSpecific");
// 	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
// 	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

// 	UHazeMovementComponent MoveComp; 
// 	AMagneticSharkActor Shark; 
 
// 	FVector TargetDirection; 

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		Shark = Cast<AMagneticSharkActor>(Owner);
// 		MoveComp = Shark.MovementComponent;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if (Shark.CurrentState != EMagneticSharkState::Attacking)
//             return EHazeNetworkActivation::DontActivate;

//         else
// 			return EHazeNetworkActivation::ActivateFromControl;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if (Shark.CurrentState == EMagneticSharkState::Attacking)
//             return EHazeNetworkDeactivation::DontDeactivate;
//         else
//             return EHazeNetworkDeactivation::DeactivateFromControl;
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
// 		if(!MoveComp.CanCalculateMovement())
// 		{
// 			return;
// 		}
// 		TargetDirection = Shark.TargetPlayer.GetActorLocation() - Shark.ActorLocation; 
// 		TargetDirection.Normalize();
// 		Shark.Velocity += TargetDirection * Shark.AttackAcceleration * DeltaTime;
// 		Shark.Velocity -= Shark.Velocity * Shark.Drag * DeltaTime; 
// 		Move(DeltaTime);
// 		//Print("" + TargetDirection.Size());
// 		//Print("" + Shark.Velocity.Size());
		
// 	}

// 	void Move(float DeltaTime)
// 	{
// 		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SharkAttack");

// 			FrameMove.ApplyVelocity(Shark.Velocity);
// 			MoveComp.SetTargetFacingDirection(TargetDirection, 1.f);
// 			FrameMove.ApplyTargetRotationDelta();
// 			MoveComp.Move(FrameMove);
// 	}

// }