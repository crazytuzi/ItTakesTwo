import Cake.LevelSpecific.SnowGlobe.SnowTurtle.SnowTurtleBaby;
import Cake.LevelSpecific.SnowGlobe.SnowTurtle.SnowTurtleNest;
import Rice.Math.MathStatics;

class USnowTurtleMoveToNestCapability : UHazeCapability
{
	default CapabilityTags.Add(n"TurtleMoveToNest");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 95;

	ASnowTurtleBaby SnowTurtle;
	TArray<ASnowTurtleNest> SnowTurtleNestArray;
	ASnowTurtleNest ChosenNest;

	FHazeAcceleratedRotator AcceleratedRotation;

	float TargetMinimumDistance = 420.f;
	float MoveSpeed = 400.f;
	float TurnSpeedTime = 0.75f;
	float DistanceFromPlayer = 320.f;
	float JumpHorizontalSpeed = 720.f;

	bool bCanMoveToNest;

	bool bNetIsInNest;

	FRotator MakeRot;

	FHazeTraceParams TraceParams;

	TArray<AHazePlayerCharacter> PlayersInRange;
	TArray<AHazeActor> TurtlesInRange;

	float NextMoveTime;
	float MoveTimeRate = 0.5f;

	float NetworkNewTime;
	float NetworkTimeRate = 0.4f;

	float MaxAngle = 45.f;

	FVector TargetDirection;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SnowTurtle = Cast<ASnowTurtleBaby>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{	
		if (!SnowTurtle.MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (SnowTurtle == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		if (!SnowTurtle.bCanMoveToNest)
			return EHazeNetworkActivation::DontActivate;

		if (SnowTurtle.bIsInNest)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	//If control, set vector info and then add to activation params
	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{	
		float MinDistance = 2000.f;

		GetAllActorsOfClass(SnowTurtleNestArray);
		ASnowTurtleNest CurrentNest;

		for (ASnowTurtleNest Nest : SnowTurtleNestArray)
		{
			if (!Nest.bIsChosen)
			{
				FVector Direction = Nest.ActorLocation - SnowTurtle.ActorLocation;
				SnowTurtle.DistanceFromNest = Direction.Size();

				if (SnowTurtle.DistanceFromNest < MinDistance)
				{
					MinDistance = SnowTurtle.DistanceFromNest;
					SnowTurtle.TargetNestPosition = Nest.ActorLocation + FVector(0,0,130.f);
					CurrentNest = Nest;
				}
			}
		}

		ActivationParams.AddVector(n"TargetNest", SnowTurtle.TargetNestPosition);
		ActivationParams.AddObject(n"ChosenNest", CurrentNest);
	}

	//On activate, set our target to the stored vector param, regardless if control or remote (doesn't matter as it sets to same value anyway)
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bCanMoveToNest = false;

		ChosenNest = Cast<ASnowTurtleNest>(ActivationParams.GetObject(n"ChosenNest"));

		SnowTurtle.NestForwardVector = ChosenNest.ActorForwardVector;
		ChosenNest.bIsChosen = true;

		SnowTurtle.TargetNestPosition = ActivationParams.GetVector(n"TargetNest");
		AcceleratedRotation.SnapTo(SnowTurtle.RotationControl.WorldRotation);

		TargetDirection = SnowTurtle.TargetNestPosition - SnowTurtle.ActorLocation;
		TargetDirection = TargetDirection.ConstrainToPlane(FVector::UpVector);
		TargetDirection.Normalize();

		MakeRot = FRotator::MakeFromX(TargetDirection);

		float Dot = MakeRot.ForwardVector.DotProduct(SnowTurtle.ActorForwardVector); 
		Dot = FMath::Clamp(Dot, 0.1f, 1.f);
		Dot = 1.f - Dot;
		TurnSpeedTime *= Dot; 
		float CanMoveTimer = TurnSpeedTime * 0.21f;

		SnowTurtle.bIsSettledInNest = false;

		System::SetTimer(this, n"SetCanMoveToNest", CanMoveTimer, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SnowTurtle.MoveComp.Velocity = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (SnowTurtle.MoveComp.CanCalculateMovement())
		{
			ObstacleAngleCheck();
			
			if (!SnowTurtle.bIsInNest || !SnowTurtle.bIsSettledInNest)
				DistanceCheck();
			
			if (SnowTurtle.DistanceFromNest <= TargetMinimumDistance && ChosenNest != nullptr)
			{
				if (!ChosenNest.bIsOccupied && HasControl())
					NetActivateJumpIntoNest(ChosenNest);
			}

			SetRotationSpeedTowardsNest(DeltaTime);

			if (PlayersInRange.Num() > 0)
			{
				SnowTurtle.bPlayerIsInTheWay = true;
				NextMoveTime = System::GameTimeInSeconds + MoveTimeRate;
			}
			else if (TurtlesInRange.Num() > 0)
			{
				SnowTurtle.bPlayerIsInTheWay = true;
				NextMoveTime = System::GameTimeInSeconds + MoveTimeRate;
			}
			else
			{
				if (NextMoveTime <= System::GameTimeInSeconds && !SnowTurtle.bIsInNest)
				{
					CalculateMovement(DeltaTime);
					SnowTurtle.bPlayerIsInTheWay = false;
				}
			}
		}
	}

	UFUNCTION()
	void ObstacleAngleCheck()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!Player.ActorLocation.IsNear(SnowTurtle.ActorLocation, 610.f))
			{
				if (PlayersInRange.Contains(Player))
					PlayersInRange.Remove(Player);

				continue;
			}

			FVector PlayerDirection = (Player.ActorLocation - SnowTurtle.ActorLocation).GetSafeNormal();
			FVector NestDirection = TargetDirection;

			float DotForward = PlayerDirection.DotProduct(SnowTurtle.SkeletalMeshComponent.ForwardVector);
			float DotToNest = PlayerDirection.DotProduct(NestDirection);

			if (DotToNest > 0.8f && DotForward > 0.85f)
			{
				float Angle = FMath::RadiansToDegrees(FMath::Acos(DotToNest));  

				if (!PlayersInRange.Contains(Player))
					PlayersInRange.Add(Player);

			}
			else
			{
				if (PlayersInRange.Contains(Player))
					PlayersInRange.Remove(Player);
			}
		}

		for (AHazeActor Turtle : SnowTurtle.TurtleEventManager.TurtlesArray)
		{
			if (Turtle == SnowTurtle)
				return;

			float Distance = (Turtle.ActorLocation - SnowTurtle.ActorLocation).Size();

			if (Distance >= 610.f)
			{
				if (TurtlesInRange.Contains(Turtle))
					TurtlesInRange.Remove(Turtle);

				continue;
			}

			ASnowTurtleBaby TurtleBabyRef = Cast<ASnowTurtleBaby>(Turtle);

			if (TurtleBabyRef == nullptr)
				return;

			if (TurtleBabyRef.bIsInNest)
			{
				if (TurtlesInRange.Contains(Turtle))
					TurtlesInRange.Remove(Turtle);
				
				return;
			}

			FVector TurtleDirection = (Turtle.ActorLocation - SnowTurtle.ActorLocation).GetSafeNormal();
			float Dot = TurtleDirection.DotProduct(SnowTurtle.SkeletalMeshComponent.ForwardVector);

			if (Dot > 0.80f)
			{
				float Angle = FMath::RadiansToDegrees(FMath::Acos(Dot));  

				if (!TurtlesInRange.Contains(Turtle))
					TurtlesInRange.Add(Turtle);
			}
			else
			{
				if (TurtlesInRange.Contains(Turtle))
					TurtlesInRange.Remove(Turtle);
			}
		}
	}

	void CalculateMovement(float DeltaTime)
	{
		TargetDirection = SnowTurtle.TargetNestPosition - SnowTurtle.ActorLocation;
		TargetDirection = TargetDirection.ConstrainToPlane(FVector::UpVector);
		TargetDirection.Normalize();

		if (bCanMoveToNest)
			SnowTurtle.MoveComp.Velocity = SnowTurtle.RotationControl.ForwardVector * MoveSpeed;
		else
			SnowTurtle.MoveComp.Velocity = 0.f;

		MakeRot = FRotator::MakeFromX(TargetDirection);

		AcceleratedRotation.AccelerateTo(MakeRot, TurnSpeedTime, DeltaTime);
		SnowTurtle.RotationControl.WorldRotation = AcceleratedRotation.Value;

		// SnowTurtle.ActorRotation = AcceleratedRotation.Value;

		FHazeFrameMovement FrameMovement = SnowTurtle.MoveComp.MakeFrameMovement(n"TurtleMove");

		FrameMovement.ApplyVelocity(SnowTurtle.MoveComp.Velocity);
		FrameMovement.ApplyTargetRotationDelta();

		SnowTurtle.MoveComp.Move(FrameMovement);
	}
	
	void DistanceCheck()
	{
		FVector Direction = SnowTurtle.TargetNestPosition - SnowTurtle.ActorLocation;
		SnowTurtle.DistanceFromNest = Direction.Size();
	}

	UFUNCTION(NetFunction)
	void NetActivateJumpIntoNest(ASnowTurtleNest ChosenNest)
	{	
		SnowTurtle.bIsInNest = true;
		ChosenNest.bIsOccupied = true;
		SnowTurtle.TurtleEventManager.CheckForCompletedQuest();
	}

	UFUNCTION()	
	void SetCanMoveToNest()
	{
		bCanMoveToNest = true;
		SnowTurtle.DisableTurtleMagnet();
	}

	void SetRotationSpeedTowardsNest(float DeltaTime)
	{		
		if (!bCanMoveToNest)
		{
			float Dot = SnowTurtle.RotationControl.WorldRotation.ForwardVector.DotProduct(SnowTurtle.ActorForwardVector); 
			Dot = FMath::Clamp(Dot, 0.1f, 1.f);
			float RotationSpeed = 160.f * Dot;
			SnowTurtle.RotationSpeed = RotationSpeed;
		}
		else
		{
			SnowTurtle.RotationSpeed = FMath::FInterpTo(SnowTurtle.RotationSpeed, 0.f, DeltaTime, 1.8f);
		}
	}

	UFUNCTION(NetFunction)
	void NetIsInNestBool (bool IsInNest)
	{
		bNetIsInNest = IsInNest;
	}
}