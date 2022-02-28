import Cake.LevelSpecific.SnowGlobe.SnowTurtle.SnowTurtleBaby;
import Vino.Movement.Components.MovementComponent;

class USnowTurtleMagnetCapability : UHazeCapability
{
	default CapabilityTags.Add(n"TurtleMovement");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ASnowTurtleBaby SnowTurtle;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	float DefaultDrag = 0.35f;
	float Drag;
	float ReboundVelocityDivider = 0.9f;
	float TurtleGravity = 2800.f;

	FVector Velocity;

	bool bIsTurningLeft;
	int RotationDirection;

	float RotationSpeed;
	float RotationSpeedDivider = 13.5f;

	float CollideMovingObjAddedSpeed;

	float SlopeSpeed = 1050.f;

	float ImpulseMultiplier = 1.f;

	FHazeAcceleratedFloat YawAccelerated;
	FHazeAcceleratedRotator SlopeRotationAccelerated;

	FQuat Rotation;
	FQuat PrevRotation;

	FName Tag = n"Turtle";

	FVector PreMoveVelocity;

	float NetworkRate = 0.2f;
	float NetworkNewTime;

	bool bIsSleeping = true;
	float SleepTimer = 0.f;

	float ResetPositionTimer;
	float ResetPositionMaxtimer = 15.f;

	bool bHasReset;
	bool bAfterReset;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SnowTurtle = Cast<ASnowTurtleBaby>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);

		SnowTurtle.AddActorTag(Tag);	

		Drag = DefaultDrag;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{	
		if (SnowTurtle == nullptr)
        	return EHazeNetworkActivation::DontActivate;
		
		if (SnowTurtle.bCanMoveToNest)
        	return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
		if (SnowTurtle.bCanMoveToNest)
        	return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PrevRotation = SnowTurtle.RotationControl.WorldRotation.Quaternion();
		YawAccelerated.SnapTo(SnowTurtle.RotationControl.WorldRotation.Yaw);
		SlopeRotationAccelerated.SnapTo(SnowTurtle.RotationControl.WorldRotation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector ToMiddle = FVector(0.f);

		//Network average out position
		if (Network::IsNetworked() && !SnowTurtle.bNeedsReset)
		{
			FVector MiddleLoc = SnowTurtle.ActorLocation + SnowTurtle.OtherSidePosition;
			MiddleLoc *= 0.5f;
			ToMiddle = MiddleLoc - SnowTurtle.ActorLocation;

			FVector CheckCorrectionForce = ToMiddle * DeltaTime;
			float DistanceFromOther = (SnowTurtle.ActorLocation - SnowTurtle.OtherSidePosition).Size();
			//Check if stuck and if so, use counter to determine when it should reset its position
			if (DistanceFromOther > 300.f)
			{
				FVector VelDifference = SnowTurtle.MoveComp.Velocity - SnowTurtle.OtherVelocity;
				FVector Direction = ToMiddle.GetSafeNormal();
				float SpeedTowardsMiddle = VelDifference.DotProduct(Direction);
			
				//is moving away or not at all
				if (FMath::IsNearlyZero(SpeedTowardsMiddle, 0.05f) || SpeedTowardsMiddle < 0.f)
				{
					ResetPositionTimer += DeltaTime;
					
					//If not tried to reach center for extended period of time
					if (ResetPositionTimer >= ResetPositionMaxtimer)
					{
						if (HasControl() && !bHasReset)
						{
							SnowTurtle.ResetTurtlePosition(); //NetFunction
							bHasReset = true;
							bAfterReset = true;
							System::SetTimer(this, n"SetAfterResetFalse", 1.5f, false);
						}
					}
				}
			}
			else
			{
				if (bHasReset)
					bHasReset = false;

				ResetPositionTimer = 0.f;
			}
		}

		//Wakes up if in use or network ToMiddle Value above 20
		if (IsPlayerActivatingMagnet() || ToMiddle.Size() > 20.f)
		{
			bIsSleeping = false;
			SleepTimer = 0.f;
		}

		//Movement if awake and can move
		if (MoveComp.CanCalculateMovement() && !bIsSleeping && !bAfterReset)
		{	
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"TurtleMove");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveComp.Move(FrameMove);
			CollisionHit(PreMoveVelocity);

			if (SnowTurtle.bMayIsAffecting || SnowTurtle.bCodyIsAffecting || MoveComp.Velocity.Size() > 100.f)
			{
				System::SetTimer(this, n"ResetCaspuleSize", 4.0f, false);
				SnowTurtle.CapsuleColliderOnHidden(true);
			}

			//Go to sleep state if Correction force and Velocity is almost 0 and if player is no longer using manget
			if (MoveComp.Velocity.IsNearlyZero(20.f) && ToMiddle.Size() <= 20.f && !IsPlayerActivatingMagnet())
			{
				SleepTimer += DeltaTime;
				if (SleepTimer >= 1.f)
					bIsSleeping = true;
			}
			else
			{
				SleepTimer = 0.f;
			}
		}	

		NetworkControl(DeltaTime);		
	}	

	UFUNCTION()
	void SetAfterResetFalse()
	{
		bAfterReset = false;
	}

	bool IsPlayerActivatingMagnet()
	{
		return SnowTurtle.SnowMagnetInfoComp.PlayerArray.Num() > 0;
	}

	UFUNCTION()
	void ResetCaspuleSize()
	{
		SnowTurtle.CapsuleColliderOnHidden(false);
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		UpdateDragStrengthBasedOnPlayerDistance();

		if (SnowTurtle.bHaveEnteredNestArea)
			Drag = 8.5f;

		MoveComp.Velocity -= MoveComp.Velocity * Drag * DeltaTime;
		RotationSpeed -= RotationSpeed * Drag * DeltaTime;

		if (MoveComp.IsAirborne() && !SnowTurtle.bHaveEnteredNestArea)
			MoveComp.Velocity += -MoveComp.WorldUp * TurtleGravity * DeltaTime;

		FrameMove.OverrideStepDownHeight(30.f);		
		
		AddAcceleration(FrameMove, DeltaTime);
		
		RotateTurtleOnHit(DeltaTime);

		FVector Impulses = MoveComp.ConsumeAccumulatedImpulse();
		Impulses = Math::ConstrainVectorToSlope(Impulses, MoveComp.DownHit.Normal, MoveComp.WorldUp);
		FrameMove.ApplyVelocity(Impulses);	

		//Decay/Drag othervelocity - the longer between network updates, the more we want to lessen othervelocity to help avoid big differences between control and remote's velocity
		SnowTurtle.OtherVelocity -= SnowTurtle.OtherVelocity * DeltaTime * 0.45f;
		
		//predicted location -> add other velocity on top of other position * deltatime
		SnowTurtle.OtherSidePosition += SnowTurtle.OtherVelocity * DeltaTime;

		FVector CorrectionForce;

		if (Network::IsNetworked() && !SnowTurtle.bNeedsReset)
		{
			//We find the middle location between ourself and the other side's position
			FVector MiddleLoc = SnowTurtle.ActorLocation + SnowTurtle.OtherSidePosition;
			MiddleLoc *= 0.5f;
			FVector ToMiddle = MiddleLoc - SnowTurtle.ActorLocation;
			CorrectionForce = ToMiddle * DeltaTime;
		}

		//Use this to add our delta velocity ontop of the correction move
		FVector DeltaMove = MoveComp.Velocity * DeltaTime;

		// if (SnowTurtle.bHaveEnteredNestArea)

		//Moves the remote or control side in the predicted direction + our delta velocity, but does so without changing the movecomp's actual velocity
		FrameMove.ApplyDeltaWithCustomVelocity(CorrectionForce + DeltaMove, MoveComp.Velocity);

		//For on hit information, we want to record our prior velocity before we hit
		PreMoveVelocity = MoveComp.Velocity;
		FrameMove.ApplyTargetRotationDelta(); 		
	}
	
	void AddAcceleration(FHazeFrameMovement& FrameMove, float DeltaTime)
	{
		FVector Acceleration;

		//Follow slope rotation
		FVector Right = SnowTurtle.MoveComp.WorldUp.CrossProduct(MoveComp.DownHit.Normal).GetSafeNormal();
		FVector SlopeAngle = Right.CrossProduct(MoveComp.DownHit.Normal).GetSafeNormal();
		float AngleStrength = (-SnowTurtle.MoveComp.WorldUp.DotProduct(SlopeAngle));

		float AngleDegrees = FMath::Acos(AngleStrength) * RAD_TO_DEG;
		// FVector NewRight = MoveComp.DownHit.Normal.CrossProduct(SnowTurtle.RotationControl.ForwardVector).GetSafeNormal();
		// FVector NewForward = NewRight.CrossProduct(MoveComp.DownHit.Normal).GetSafeNormal();
		
		Acceleration = SlopeAngle * SlopeSpeed * AngleStrength * DeltaTime;
		//Velocity addition
		Acceleration += SnowTurtle.SnowMagnetInfoComp.PushPowerToAdd * DeltaTime; 
		Acceleration += SnowTurtle.SnowMagnetInfoComp.PullPowerToAdd * DeltaTime;

		FrameMove.ApplyVelocity(Acceleration);
	}

	void RotateTurtleOnHit(float DeltaTime)
	{
		YawAccelerated.AccelerateTo(YawAccelerated.Value + 2.15f, 5.f, DeltaTime);
		YawAccelerated.Value = FRotator::NormalizeAxis(YawAccelerated.Value);		 		
		FQuat RotationQuat(MoveComp.DownHit.Normal, RotationSpeed * DeltaTime);
		FQuat FinalRot = SnowTurtle.RotationControl.WorldRotation.Quaternion() * RotationQuat;
		SnowTurtle.RotationControl.WorldRotation = FinalRot.Rotator();
		
		FVector ConstrainedForwardVector = Math::ConstrainVectorToSlope(SnowTurtle.RotationControl.ForwardVector, MoveComp.DownHit.Normal, FVector::UpVector); 
		SlopeRotationAccelerated.AccelerateTo(ConstrainedForwardVector.Rotation(), 0.52f, DeltaTime);
		SnowTurtle.RotationControl.WorldRotation =  SlopeRotationAccelerated.Value;
	}
	
	UFUNCTION()
	void UpdateDragStrengthBasedOnPlayerDistance()
	{
		float ClosestDistance = 4000.f;
		float Proximity = 1200.f;
		float DistanceMultiplier;

		if (SnowTurtle.SnowMagnetInfoComp.PlayerArray.Num() > 0)
		{
			for (auto Player : SnowTurtle.SnowMagnetInfoComp.PlayerArray)
			{
				FVector Direction = SnowTurtle.ActorCenterLocation - Player.ActorLocation;
				float DistanceCheck = Direction.Size();

				if (DistanceCheck <= Proximity)
					if (ClosestDistance > DistanceCheck)
						ClosestDistance = DistanceCheck; 
			}

			if (ClosestDistance <= Proximity)
				DistanceMultiplier = Proximity / ClosestDistance;
			else
				DistanceMultiplier = 0.8f;

			Drag = DistanceMultiplier;
		}
		else
		{
			Drag = DefaultDrag;	
		}	
	}

	void CollisionHit(FVector PreMoveVelocity)
	{
		if (MoveComp.ForwardHit.bBlockingHit)
		{
			ASnowTurtleBaby OtherTurtle = Cast<ASnowTurtleBaby>(MoveComp.ForwardHit.GetActor());
	
			if (OtherTurtle != nullptr)
			{
				FVector HitDirection = OtherTurtle.ActorLocation - SnowTurtle.ActorLocation;
				HitDirection = Math::ConstrainVectorToSlope(HitDirection, MoveComp.DownHit.Normal, MoveComp.WorldUp);
				HitDirection.Normalize();

				FVector Impulse = HitDirection * PreMoveVelocity.Size();

				OtherTurtle.MoveComp.AddImpulse(Impulse);

				if (!OtherTurtle.MoveComp.ForwardHit.bBlockingHit)
				{
					OtherTurtle.SnowMagnetInfoComp.bCanComponentRotate = true;
					OtherTurtle.SnowMagnetInfoComp.OnHitTurtleVelocity = SnowTurtle.GetActorVelocity().Size();
				}

				ReboundRotationHandler();
				RotationSpeed = FMath::Clamp(SnowTurtle.GetActorVelocity().Size() / RotationSpeedDivider, 0.f, 15.f);
				RotationSpeed *= RotationDirection;
			}
			else
			{
				ReboundHit();
				ReboundRotationHandler();
				RotationSpeed = FMath::Clamp(SnowTurtle.GetActorVelocity().Size() / RotationSpeedDivider, 0.f, 15.f);
				RotationSpeed *= RotationDirection;
			}

			SnowTurtle.SetCapabilityAttributeVector(n"AudioOnCollisionHit", PreMoveVelocity);
		}

		if (SnowTurtle.SnowMagnetInfoComp.bCanComponentRotate)
		{
			ReboundRotationHandler();
			RotationSpeed = FMath::Clamp(SnowTurtle.SnowMagnetInfoComp.OnHitTurtleVelocity.Size() / RotationSpeedDivider, 0.f, 15.f);
			RotationSpeed *= RotationDirection;
			SnowTurtle.SnowMagnetInfoComp.bCanComponentRotate = false;
		}
	}

	void ReboundHit()
	{
		SnowTurtle.MoveComp.Velocity = SnowTurtle.MoveComp.PreviousVelocity.MirrorByVector(SnowTurtle.MoveComp.ForwardHit.Normal);
		SnowTurtle.MoveComp.Velocity *= ReboundVelocityDivider;
	}

	UFUNCTION()
	void ReboundRotationHandler()
	{
		int r = FMath::RandRange(0, 1);

		if (r > 0)
			RotationDirection = -1;
		else
			RotationDirection = 1;
	}

	UFUNCTION()
	void NetworkControl(float DeltaTime)
	{
		if (SnowTurtle.bShouldNetwork && Network::IsNetworked())
		{
			if (NetworkNewTime <= System::GameTimeInSeconds)
			{
				NetworkNewTime = System::GameTimeInSeconds + NetworkRate;
				NetOtherSidePosition(HasControl(), SnowTurtle.ActorLocation, MoveComp.Velocity);
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetOtherSidePosition(bool bControlSide, FVector OtherPosition, FVector OtherVelocity)
	{
		if (HasControl() == bControlSide)
			return;

		SnowTurtle.OtherSidePosition = OtherPosition;
		SnowTurtle.OtherVelocity = OtherVelocity;
	}
}