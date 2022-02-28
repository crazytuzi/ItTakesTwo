

// import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
// import Vino.Movement.Swinging.SwingComponent;

// class USwingPhysicsMovementCapability : UCharacterMovementCapability
// {
// 	default CapabilityTags.Add(CapabilityTags::Movement);
// 	default CapabilityTags.Add(CapabilityTags::MovementAction);
// 	default CapabilityTags.Add(n"Swinging");
// 	default CapabilityTags.Add(n"SwingingMovement");

// 	default CapabilityDebugCategory = n"Movement Swinging";

// 	default TickGroup = ECapabilityTickGroups::ActionMovement;
// 	default TickGroupOrder = 5;

// 	AHazePlayerCharacter OwningPlayer;
// 	USwingingComponent SwingingComponent;
// 	USwingPointComponent ActiveSwingPoint;

// 	float TetherLength = 0.f;
// 	float TetherLengthAcceleration = 100.f;

// 	FVector SwingDirection;

// 	FVector Vel;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		Super::Setup(SetupParams);

// 		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
// 		SwingingComponent = USwingingComponent::GetOrCreate(Owner);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void PreTick(float DeltaTime)
// 	{		
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if (SwingingComponent.GetActiveSwingPoint() == nullptr)
// 			return EHazeNetworkActivation::DontActivate;

// 		if (!MoveComp.CanCalculateMovement())
// 			return EHazeNetworkActivation::DontActivate;
        
// 		return EHazeNetworkActivation::ActivateLocal;
		
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if (ActiveSwingPoint != SwingingComponent.GetActiveSwingPoint())
// 			return EHazeNetworkDeactivation::DeactivateLocal;

// 		return EHazeNetworkDeactivation::DontDeactivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		ActiveSwingPoint = SwingingComponent.GetActiveSwingPoint();	

// 		OwningPlayer.BlockCapabilities(n"Movement", this);

// 		TetherLength = (ActiveSwingPoint.WorldLocation - SwingingComponent.PlayerLocation).Size();

// 		SwingDirection = ((ActiveSwingPoint.WorldLocation - SwingingComponent.PlayerLocation) * FVector(1, 1, 0)).GetSafeNormal();

// 		Print("MoveComp.Velocity" + MoveComp.Velocity.Size(), 5.f);

// 		/*if (MoveComp.Velocity.Size() < 1800.f)
// 		{
// 			MoveComp.Velocity = MoveComp.Velocity.GetSafeNormal() * 1800.f;
// 		}*/
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		OwningPlayer.UnblockCapabilities(n"Movement", this);
// 		ActiveSwingPoint = nullptr;	
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{	
// 		/*
// 		- Always enter with consistent speed
// 		- When holding a direction, the player should have consistent speed
// 		- If moving in the same direction as pressed on the stick, should swing back and fourth
// 		- If moving in a different direction as pressed, should swing around to match that direction		
// 		- If you don't press any direction, should slow down and hang
// 		- Should responsively speed up and slow down on pressed/not pressed
// 		*/

// 		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"Swinging");

// 		// Lerps the tether length towards desired
// 		UpdateTetherLength(DeltaTime);

// 		FVector SwingPointLocation = ActiveSwingPoint.WorldLocation;
// 		FVector PlayerToPoint = (ActiveSwingPoint.WorldLocation - SwingingComponent.PlayerLocation);

// 		FVector Velocity = MoveComp.Velocity;
// 		Velocity += MoveComp.Gravity * DeltaTime * 0.8f;

// 		FVector TargetDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
// 		System::DrawDebugArrow(SwingingComponent.PlayerLocation, SwingingComponent.PlayerLocation + TargetDirection * 250.f, 100.f, LineColor = FLinearColor::Blue, Thickness = 2.f);

// 		//Velocity = SetFirstRotationTest(Velocity, DeltaTime);
// 		//Velocity = SetSecondRotationTest(Velocity, DeltaTime);		


// 		Velocity = ClampVelocityToTether(Velocity, DeltaTime);


		
// 		FrameMove.ApplyVelocity(Velocity);

// 		FrameMove.SetRotation(Math::MakeRotFromX(Velocity).Quaternion());
// 		MoveCharacter(FrameMove, n"Swinging");

// 		System::DrawDebugLine(ActiveSwingPoint.WorldLocation, SwingingComponent.PlayerLocation, LineColor = FLinearColor::Green);
// 		System::DrawDebugLine(SwingingComponent.PlayerLocation, SwingingComponent.PlayerLocation + Velocity, LineColor = FLinearColor::Red);

// 	}

// 	void UpdateTetherLength(float DeltaTime)
// 	{
// 		if (TetherLength != ActiveSwingPoint.SwingRangeDistance)
// 		{
// 			float AccelerationDirection = FMath::Sign((ActiveSwingPoint.SwingRangeDistance - TetherLength));
// 			TetherLength += TetherLengthAcceleration * AccelerationDirection * DeltaTime;

// 			if (TetherLength > ActiveSwingPoint.SwingRangeDistance && AccelerationDirection > 0)
// 				TetherLength = ActiveSwingPoint.SwingRangeDistance;
// 			else if (TetherLength < ActiveSwingPoint.SwingRangeDistance && AccelerationDirection < 0)
// 				TetherLength = ActiveSwingPoint.SwingRangeDistance;
// 		}

// 		Print("Tether Length: " + TetherLength);
// 	}

// 	FVector ClampVelocityToTether(FVector Velocity, float DeltaTime)
// 	{
// 		FVector SwingPointLocation = ActiveSwingPoint.WorldLocation;
// 		FVector ResultingLocation = SwingingComponent.PlayerLocation + (Velocity * DeltaTime);

// 		if ((ResultingLocation - SwingPointLocation).Size() > TetherLength)
// 		{
// 			ResultingLocation = SwingPointLocation + ((ResultingLocation - SwingPointLocation).GetSafeNormal() * TetherLength);
// 			return (ResultingLocation - SwingingComponent.PlayerLocation) / DeltaTime;
// 		}



// 		return Velocity;
// 	}

// 	FVector SetFirstRotationTest(FVector Velocity, float DeltaTime)
// 	{
// 		FVector TargetDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
// 		FVector Up = MoveComp.WorldUp;
// 		FVector VelocityFlat = Velocity.ConstrainToPlane(Up);

// 		TargetDirection.Normalize();
// 		VelocityFlat.Normalize();

// 		float Angle = FMath::Asin(VelocityFlat.CrossProduct(TargetDirection).DotProduct(Up));
// 		FQuat VelocityTurnQuat = FQuat(Up, Angle * 2 * DeltaTime);

// 		return VelocityTurnQuat * Velocity;
// 	}

// 	FVector SetSecondRotationTest(FVector Velocity, float DeltaTime)
// 	{
// 		FVector SwingPointLocation = ActiveSwingPoint.WorldLocation;
// 		FVector PlayerToPoint = (ActiveSwingPoint.WorldLocation - SwingingComponent.PlayerLocation);
// 		FVector TargetDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);

// 		FVector Vel = Velocity;

// 		FVector Up = MoveComp.WorldUp;
// 		float DirectionSign = FMath::Sign(Vel.ConstrainToPlane(Up).DotProduct(PlayerToPoint));
// 		FVector CurrentDirection = PlayerToPoint.ConstrainToPlane(Up).GetSafeNormal() * DirectionSign;
// 		System::DrawDebugLine(SwingingComponent.PlayerLocation, SwingingComponent.PlayerLocation + CurrentDirection * 250.f, LineColor = FLinearColor::Yellow);

// 		float CurrentSwingPosition = -PlayerToPoint.DotProduct(CurrentDirection);


// 		if (TargetDirection.IsNearlyZero(0.1f))
// 			TargetDirection = CurrentDirection;

// 		TargetDirection.Normalize();

// 		FVector TargetPoint = TargetDirection * CurrentSwingPosition;
			
// 		FVector ToTarget = TargetPoint - (CurrentDirection * CurrentSwingPosition);
// 		ToTarget -= CurrentDirection * ToTarget.DotProduct(CurrentDirection);
// 		System::DrawDebugLine(SwingingComponent.PlayerLocation, SwingingComponent.PlayerLocation + ToTarget);

// 		FVector VelocityFlat = Vel.ConstrainToPlane(Up);
// 		VelocityFlat.Normalize();

// 		return Vel + ToTarget * 3 * DeltaTime;

// 		/*float Angle = FMath::Asin(VelocityFlat.CrossProduct(ToTarget.GetSafeNormal()).DotProduct(Up));
// 		FQuat VelocityTurnQuat = FQuat(Up, Angle * 2 * DeltaTime);

// 		Velocity = VelocityTurnQuat * Velocity;*/
// 	}
// }