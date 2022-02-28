import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Hopscotch.SideContent.PullbackCar;

class UPullbackCarCapability : UHazeCapability
{	
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::MovementAction);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	APullbackCar PullbackCar;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComponent;


	const float WindupAmountMaxDistance = 500.f;	
	const float MaxAcceleration = 12500.f;

	float CurrentAcceleration = 0.f;
	float CurrentReleaseSpeed = 0;

	bool bAddedAirImpulse = false;
	FVector LastMovedDelta;

	float CurrentWindupForceAmount;
	float AutoDestroyTimer = 0;
	float ImpactDestroyTimer = 0;

	float DepotMoveAlpha = 0.f;
	FVector AirLiftOffVelocity = 0.f;
	float StartZ = 0;
	//float UpdatedRotationTime = 0;
	//FRotator TargetMovementRotation;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PullbackCar = Cast<APullbackCar>(Owner);
		MoveComp = UHazeMovementComponent::Get(PullbackCar);
		CrumbComponent = UHazeCrumbComponent::Get(PullbackCar);
		PullbackCar.OnPullbackCarWasDestroyed.AddUFunction(this, n"OnCarDestroyed");
		StartZ = PullbackCar.GetActorLocation().Z;
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

	UFUNCTION(NotBlueprintCallable)
	void OnCarDestroyed()
	{
		CurrentAcceleration = 0.f;
		CurrentReleaseSpeed = 0.f;
		AirLiftOffVelocity = 0.f;

		bAddedAirImpulse = false;
		LastMovedDelta = FVector::ZeroVector;

		CurrentWindupForceAmount = 0.f;
		AutoDestroyTimer = 0;
		ImpactDestroyTimer = 0;
		DepotMoveAlpha = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove;
			if (HasControl())
			{
				if(PullbackCar.CurrentMovementState == EPullBackCarMovementState::WindingUp)
				{
					FrameMove = MoveComp.MakeFrameMovement(n"PullCarWindupMovement");
					CalculateFrameMoveDuringWindup(FrameMove, DeltaTime);
				}
				else if(PullbackCar.CurrentMovementState == EPullBackCarMovementState::Released)
				{
					FrameMove = MoveComp.MakeFrameMovement(n"PullCarWindupReleasedGroundedMovement");
					CalculateFrameMoveWindupRelease(FrameMove, DeltaTime);
				}
				else if(PullbackCar.CurrentMovementState == EPullBackCarMovementState::Exploding)
				{
	
					FrameMove = MoveComp.MakeFrameMovement(n"PullCarWExploding");
				}
				else if(PullbackCar.CurrentMovementState == EPullBackCarMovementState::Respawning)
				{
					FrameMove = MoveComp.MakeFrameMovement(n"PullCarWindupMoveFromDepoMovement");
					CalculateFrameMoveMoveFromDepot(FrameMove, DeltaTime);
				}
				else
				{
					FrameMove = MoveComp.MakeFrameMovement(n"PullCarIdleMovement");
					CalculateIdleFrameMove(FrameMove, DeltaTime);		
				}	

				CrumbComponent.SetCustomCrumbRotation(PullbackCar.MovementRoot.RelativeRotation);
			} 
			else
			{
				ConsumeCrumbs(FrameMove, DeltaTime);
			} 

			const FVector LastActorLocation = PullbackCar.GetActorLocation();
			MoveComp.Move(FrameMove);
			CrumbComponent.LeaveMovementCrumb();
			LastMovedDelta = PullbackCar.GetActorLocation() - LastActorLocation;
		}

		FinalizeFrame(DeltaTime);
	}

	void CalculateIdleFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{
		FrameMove.ApplyTargetRotationDelta();
		FrameMove.ApplyGravityAcceleration();
		FrameMove.ApplyActorVerticalVelocity();
	}

	void CalculateFrameMoveDuringWindup(FHazeFrameMovement& FrameMove, float DeltaTime)
	{
		FVector WindupDirection = PullbackCar.WindupDirection;
		FVector WantedVelocity = FVector::ZeroVector;

		float ForceToAdd = 0;
		if(!WindupDirection.IsNearlyZero(0.1f))
		{
			FHazeHitResult BackHit;
			if(!TraceBehindImpact(BackHit, 100.f))
			{
				ForceToAdd = (FMath::Max((-WindupDirection).DotProduct(PullbackCar.ActorForwardVector), 0.f));
				if(!LastMovedDelta.IsNearlyZero())
				{
					float CorrectMovement = FMath::Max((LastMovedDelta).DotProduct(-PullbackCar.ActorForwardVector), 0.f);
					CurrentWindupForceAmount += (CorrectMovement) / 4.f;
				}
			}
		}
	
		CurrentWindupForceAmount = FMath::Min(WindupAmountMaxDistance, CurrentWindupForceAmount);
		PullbackCar.CurrentWindupRotationForce = WindupDirection.DotProduct(PullbackCar.ActorRightVector);

		float WindupAlpha = FMath::Min(FMath::EaseIn(0.f, 1.f, CurrentWindupForceAmount / WindupAmountMaxDistance, 2.f) + 0.1f, 1.f);
		float MoveSpeed = MoveComp.GetMoveSpeed() * FMath::Lerp(1.f, 0.f, WindupAlpha);
		WantedVelocity = -PullbackCar.ActorForwardVector * MoveSpeed * ForceToAdd;
	
		FRotator Rot = FMath::RotatorFromAxisAndAngle(PullbackCar.ActorUpVector, (PullbackCar.CurrentWindupRotationForce * PullbackCar.WindupRotationForceMultiplier) * DeltaTime);
		MoveComp.SetTargetFacingDirection(Rot.RotateVector(MoveComp.OwnerRotation.ForwardVector));

		if(PullbackCar.PlayerDrivingCar != nullptr)
			FrameMove.AddActorToIgnore(PullbackCar.PlayerDrivingCar);

		if(PullbackCar.PlayerPullingCar != nullptr)
			FrameMove.AddActorToIgnore(PullbackCar.PlayerPullingCar);

		FrameMove.ApplyTargetRotationDelta();
		FrameMove.ApplyGravityAcceleration();
		FrameMove.ApplyVelocity(WantedVelocity);
	}

	void CalculateFrameMoveWindupRelease(FHazeFrameMovement& FrameMove, float DeltaTime)
	{
		FVector FrontGround = FVector::ZeroVector;
		bool bHasFrontGround = false;

		FVector BackGround = FVector::ZeroVector;
		bool bHasBackGround = false;
		if(!bAddedAirImpulse)
		{
			bHasFrontGround = TraceFront(FrontGround);
			bHasBackGround = TraceBack(BackGround);
		}

		const FVector DirMeshRotationForward = (FrontGround - BackGround).GetSafeNormal();
	
		// If the ground under us will force us down, we do that slowly
		if(DirMeshRotationForward.DotProduct(PullbackCar.MovementRoot.WorldRotation.UpVector) < -KINDA_SMALL_NUMBER)
			bHasBackGround = false;

		if(bHasBackGround && !bAddedAirImpulse)
		{			
			FVector MoveDir = PullbackCar.MovementRoot.WorldRotation.ForwardVector;
			CurrentWindupForceAmount = FMath::Max(CurrentWindupForceAmount, 100.f);
			CurrentReleaseSpeed += CurrentAcceleration * DeltaTime;
			FVector DeltaToAdd = MoveDir * CurrentReleaseSpeed * DeltaTime;
			FrameMove.ApplyDelta(DeltaToAdd);
			float WindupAlpha = CurrentWindupForceAmount / WindupAmountMaxDistance;
			CurrentAcceleration = FMath::FInterpTo(CurrentAcceleration, MaxAcceleration * WindupAlpha, DeltaTime, 2.5f); 
	
			if(bHasFrontGround && MoveComp.IsGrounded())
			{
				PullbackCar.MovementRoot.SetWorldLocation((FrontGround + BackGround) * 0.5f);
				FVector Cross = DirMeshRotationForward.CrossProduct(PullbackCar.ActorRightVector);
				FRotator Rot = Math::MakeRotFromXZ(DirMeshRotationForward, Cross);
				float RoationSpeed = CurrentAcceleration / (MaxAcceleration * WindupAlpha);
				RoationSpeed = FMath::Lerp(8.f, 32.f, RoationSpeed);

				PullbackCar.MovementRoot.SetWorldRotation(FMath::RInterpTo(PullbackCar.MovementRoot.WorldRotation, Rot, DeltaTime, RoationSpeed));
			}
		}
		else
		{
			FrameMove = MoveComp.MakeFrameMovement(n"PullCarWindupReleasedAirMovement");
			FrameMove.OverrideStepDownHeight(0.f);
			if (!bAddedAirImpulse)
			{
				AirLiftOffVelocity = MoveComp.Velocity;
		
				bAddedAirImpulse = true;
				float WindupAlpha = FMath::Clamp(FMath::EaseIn(0.f, 1.f, CurrentWindupForceAmount / WindupAmountMaxDistance, 2.f),
					0.f, 0.4f);

				FVector MoveDir = Math::SlerpVectorTowards(AirLiftOffVelocity.GetSafeNormal(), FVector::UpVector, WindupAlpha).GetSafeNormal();
				AirLiftOffVelocity = MoveDir * AirLiftOffVelocity.Size();
			}
			else
			{
				// Apply gravity
				FVector GravityAccelerationToApply = MoveComp.GetGravity();
				AirLiftOffVelocity += GravityAccelerationToApply * FMath::Square(DeltaTime);
				AirLiftOffVelocity += GravityAccelerationToApply * DeltaTime;
			}

			FrameMove.ApplyVelocity(AirLiftOffVelocity);
			if(!FrameMove.Velocity.IsNearlyZero())
			{
				FRotator NewMeshRotation = FMath::RInterpTo(PullbackCar.MovementRoot.WorldRotation, FrameMove.Velocity.ToOrientationRotator(), DeltaTime, 3.f);
				PullbackCar.MovementRoot.SetWorldRotation(NewMeshRotation);
			}

		}

		FrameMove.AddActorToIgnore(Game::GetCody());
		FrameMove.AddActorToIgnore(Game::GetMay());
		FrameMove.ApplyAndConsumeImpulses();
	}

	void CalculateFrameMoveMoveFromDepot(FHazeFrameMovement& FrameMove, float DeltaTime)
	{
		DepotMoveAlpha += DeltaTime / 2.5f;
		DepotMoveAlpha = FMath::Min(DepotMoveAlpha, 1.f);
		FVector NewLoc = FMath::EaseInOut(PullbackCar.RespawnLocationActor.ActorLocation, PullbackCar.DriverToFromDepotLocationActor.ActorLocation, DepotMoveAlpha, 2.f);
		FVector NewDelta = NewLoc - PullbackCar.GetActorLocation();

		FrameMove.AddActorToIgnore(Game::GetCody());
		FrameMove.AddActorToIgnore(Game::GetMay());

		FrameMove.ApplyDelta(NewDelta);
	}

	void ConsumeCrumbs(FHazeFrameMovement& FrameMove, float DeltaTime)
	{
		FrameMove = MoveComp.MakeFrameMovement(n"PullCarReplicatedMovement");
		FHazeActorReplicationFinalized ConsumedParams;
		CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
		FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		PullbackCar.MovementRoot.RelativeRotation = ConsumedParams.CustomCrumbRotator;
	}

	void FinalizeFrame(float DeltaTime)
	{
		if(PullbackCar.CurrentMovementState == EPullBackCarMovementState::Released)
		{
			if (HasControl())
			{
				AutoDestroyTimer += DeltaTime;
				bool bShouldBeDestroyed = false;
				FMovementCollisionData Collisions = MoveComp.GetImpacts();
				if(!bAddedAirImpulse)
				{
					if(Collisions.ForwardImpact.bBlockingHit)
					{
						// We check the next frame to ensure movement
						bShouldBeDestroyed = ImpactDestroyTimer > 0.5f;

						float ImpactDot = Collisions.ForwardImpact.ImpactNormal.DotProduct(FVector::UpVector);
						float ForWardDot = PullbackCar.MovementRoot.ForwardVector.DotProduct(FVector::UpVector);
						const float Diff = FMath::Abs(ImpactDot - ForWardDot);
						if(Diff < 0.05f)
						{
							ImpactDestroyTimer += DeltaTime * 3.f;
						}
						else if(Diff > 0.5f || LastMovedDelta.IsNearlyZero())
						{
							ImpactDestroyTimer += DeltaTime;		
						}
					}
					else
					{
						ImpactDestroyTimer = 0.f;
					}
				}
				else if(!MoveComp.BecameAirborne())
				{
					if(Collisions.HasAnyImpact())
						bShouldBeDestroyed = true;
					else if(AutoDestroyTimer >= 6.f)
						bShouldBeDestroyed = true;
					else if(PullbackCar.GetActorLocation().Z - 300 < StartZ)
						bShouldBeDestroyed = true;
				}

				if(bShouldBeDestroyed)
				{
					FHazeDelegateCrumbParams CrumbParams;
					PullbackCar.CrumbComponent.LeaveAndTriggerDelegateCrumb(
						FHazeCrumbDelegate(PullbackCar, n"Crumb_DestroyCar"), CrumbParams);
				}
			}
		}

		if(PullbackCar.CurrentMovementState == EPullBackCarMovementState::Respawning)
		{
			if(HasControl() && DepotMoveAlpha >= 1.f)
			{
				FHazeDelegateCrumbParams CrumbParams;
				PullbackCar.CrumbComponent.LeaveAndTriggerDelegateCrumb(
					FHazeCrumbDelegate(PullbackCar, n"Crumb_FinishRespawn"), CrumbParams);
			}
		}

		if(!LastMovedDelta.IsNearlyZero() && MoveComp.IsGrounded() &&
			(PullbackCar.CurrentMovementState == EPullBackCarMovementState::Released
			|| PullbackCar.CurrentMovementState == EPullBackCarMovementState::Respawning))
		{
			FHazeTraceParams TraceParams;
			TraceParams.InitWithPrimitiveComponent(PullbackCar.FrontKillCollision);

			TArray<EObjectTypeQuery> ObjectTypes;
			ObjectTypes.Add(EObjectTypeQuery::PlayerCharacter);
			TraceParams.InitWithObjectTypes(ObjectTypes);
			TraceParams.IgnoreActor(PullbackCar);

			TraceParams.From = TraceParams.From - LastMovedDelta;
		
			//TraceParams.DebugDrawTime = 0.f;

			FHazeHitResult CharacterHit;
			if (TraceParams.Trace(CharacterHit))
			{
				auto Player = Cast<AHazePlayerCharacter>(CharacterHit.GetActor());
				if(Player != nullptr 
					&& Player != PullbackCar.PlayerPullingCar 
					&& Player != PullbackCar.PlayerDrivingCar)
				{
					Player.KillPlayer();
				}
			}
		}
		

		//UpdatedRotationTime -= DeltaTime;
	}

	bool TraceFront(FVector& FrontHitLoc)
	{
		FVector UpVector = PullbackCar.MovementRoot.UpVector;

		FHazeTraceParams FrontTraceParams;
		FrontTraceParams.InitWithMovementComponent(MoveComp);
		FrontTraceParams.IgnoreActor(PullbackCar);
		FrontTraceParams.IgnoreActor(Game::GetCody());
		FrontTraceParams.IgnoreActor(Game::GetMay());
		FrontTraceParams.SetToLineTrace();
		//FrontTraceParams.DebugDrawTime = 0.5f;
		FrontTraceParams.From = PullbackCar.FrontTraceLocation.WorldLocation + (UpVector * 100);
		FrontTraceParams.To = PullbackCar.FrontTraceLocation.WorldLocation - (UpVector * 500.f);
		
		FrontHitLoc = FrontTraceParams.To;
		FHazeHitResult FrontHit;
		if(FrontTraceParams.Trace(FrontHit))
		{
			if(FrontHit.bStartPenetrating)
				FrontHitLoc = PullbackCar.FrontTraceLocation.WorldLocation;
			else
				FrontHitLoc = FrontHit.ImpactPoint;

			return true;
		}

		return false;
	}

	bool TraceBack(FVector& BackHitLoc)
	{
		FVector UpVector = PullbackCar.MovementRoot.UpVector;

		FHazeTraceParams BackTraceParams;
		BackTraceParams.InitWithMovementComponent(MoveComp);
		BackTraceParams.IgnoreActor(PullbackCar);
		BackTraceParams.IgnoreActor(Game::GetCody());
		BackTraceParams.IgnoreActor(Game::GetMay());
		BackTraceParams.SetToLineTrace();
		//BackTraceParams.DebugDrawTime = 0.5f;
		BackTraceParams.From = PullbackCar.BackTraceLocation.WorldLocation + (UpVector * 100);
		BackTraceParams.To = PullbackCar.BackTraceLocation.WorldLocation - (UpVector * 500.f);

		BackHitLoc = BackTraceParams.To;
		FHazeHitResult BackHit;
		if(BackTraceParams.Trace(BackHit))
		{
			if(BackHit.bStartPenetrating)
				BackHitLoc = PullbackCar.BackTraceLocation.WorldLocation;
			else
				BackHitLoc = BackHit.ImpactPoint;

			return true;
		}
		
		return false;
	}

	bool TraceBehindImpact(FHazeHitResult& BackHit, float Distance) const
	{
		FHazeTraceParams BackTraceParams;
		BackTraceParams.InitWithMovementComponent(MoveComp);
		BackTraceParams.IgnoreActor(PullbackCar);
		BackTraceParams.IgnoreActor(Game::GetCody());
		BackTraceParams.IgnoreActor(Game::GetMay());
		BackTraceParams.From = PullbackCar.GetActorLocation();
		BackTraceParams.To = BackTraceParams.From -(PullbackCar.ActorForwardVector * Distance);
		return BackTraceParams.Trace(BackHit);	
	}

	FVector TraceFromMoveComp()
	{
		FHazeTraceParams MoveCompTraceParams;
		MoveCompTraceParams.InitWithMovementComponent(MoveComp);
		MoveCompTraceParams.IgnoreActor(PullbackCar);
		MoveCompTraceParams.IgnoreActor(Game::GetCody());
		MoveCompTraceParams.IgnoreActor(Game::GetMay());
		MoveCompTraceParams.SetToLineTrace();
		MoveCompTraceParams.DebugDrawTime = 0.f;
		MoveCompTraceParams.From = PullbackCar.BoxComponent.WorldLocation;
		MoveCompTraceParams.To = PullbackCar.BoxComponent.WorldLocation + FVector(0.f, 0.f, -1000.f);

		FVector CompHitLoc = PullbackCar.BoxComponent.WorldLocation;
		FHazeHitResult CompHit;
		if(MoveCompTraceParams.Trace(CompHit))	
			CompHitLoc = CompHit.ImpactPoint;
		return CompHitLoc;
	}
}