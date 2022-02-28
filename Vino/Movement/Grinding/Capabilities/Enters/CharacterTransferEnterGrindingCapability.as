import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.GrindSettings;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Grinding.GrindingTransferActivationPoint;
import Vino.Movement.Grinding.Capabilities.CharacterGrindingTransferComponent;

class UCharacterTransferEnterGrindingCapability : UCharacterMovementCapability
{
	default RespondToEvent(GrindingActivationEvents::Grinding);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Movement);
	default CapabilityTags.Add(GrindingCapabilityTags::Enter);
	default CapabilityTags.Add(GrindingCapabilityTags::Transfer);
	default CapabilityTags.Add(GrindingCapabilityTags::GrindMoveAction);

	default CapabilityDebugCategory = n"Grinding";	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 105;

	AHazePlayerCharacter Player;
	UUserGrindComponent UserGrindComp;
	UCharacterGrindingTransferComponent TransferComp;

	UGrindingTransferActivationPoint ActivationPoint;

	FVector RelativeTestLocation = FVector::ZeroVector;

	TArray<FName> ActiveBlocks;
	bool bReachedTarget = false;

	float Speed = 0.f;
	float InitialDistanceToTarget = 0.f;
	FVector InitialLocation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		TransferComp = UCharacterGrindingTransferComponent::GetOrCreate(Owner);

		Player = Cast<AHazePlayerCharacter>(Owner);
		UserGrindComp = UUserGrindComponent::GetOrCreate(Owner);
		ActivationPoint = UGrindingTransferActivationPoint::GetOrCreate(Owner);
	}
	
	UFUNCTION(BlueprintOverride)
	void PreTick_EventBased()
	{
		UserGrindComp.MoveInput = GetAttributeVector(AttributeVectorNames::MovementDirection);

		bool bUsingActivationPoint = UpdateActivationPoint(CharacterOwner.GetActorDeltaSeconds());

		// Disable activation point if we aren't using it
		if (!bUsingActivationPoint && ActivationPoint.ValidationType != EHazeActivationPointActivatorType::None)
			ActivationPoint.ChangeValidActivator(EHazeActivationPointActivatorType::None);
    }

	bool UpdateActivationPoint(float DeltaTime)
	{
		if (IsBlocked())
			return false;

		if (IsActive())
			return false;

		TransferComp.EvaluationTarget.Reset();
	
		if (UserGrindComp.HasTargetGrindSpline())
			return false;

		if (!UserGrindComp.HasActiveGrindSpline())
			return false;

		if (UserGrindComp.ActiveGrindSpline.TransferDirection == EGrindSplineTransferDirection::TransferTo)
			return false;

		return EvaluateTransferLocation(DeltaTime);
	}

	bool EvaluateTransferLocation(float DeltaTime)
	{
		FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementRaw);
		FVector InputUp = MoveComp.WorldUp * MoveInput.X;
		FVector InputRight = Player.ViewRotation.RightVector * MoveInput.Y;

		FVector TestDirection = InputUp + InputRight;

		FHazeSplineSystemPosition PredictedLocation = UserGrindComp.SplinePosition;
		PredictedLocation.Move(UserGrindComp.CurrentSpeed * DeltaTime);

		// Start the test location at the future position
		FVector PlayerPredictedLocation = PredictedLocation.WorldLocation + (PredictedLocation.WorldUpVector * UserGrindComp.ActiveGrindSpline.HeightOffset);
		FVector TargetLocation = GetTestLocationVersion2(PlayerPredictedLocation);

		FVector TargetRelativeLocation = TargetLocation - PlayerPredictedLocation;
		RelativeTestLocation = FMath::Lerp(RelativeTestLocation, TargetRelativeLocation, DeltaTime * 5.f);

		TargetLocation = PlayerPredictedLocation + RelativeTestLocation;

		if (IsDebugActive())
			System::DrawDebugSphere(TargetLocation, 25.f, LineColor = FLinearColor::Yellow, Duration = 0.f);

		TransferComp.EvaluationTarget = GetBestPotentialTransferSplineInDirection(TargetLocation, TestDirection);
		if (!TransferComp.IsEvalTargetValid())
			return false;

		// Make sure the transfer isnt too far away.
		FVector ToTarget = TransferComp.EvaluationTarget.SystemPosition.WorldLocation - Owner.ActorLocation;
		float DistanceToTarget = ToTarget.Size();
		if (DistanceToTarget > GrindSettings::Transfer.MaxTransferDistance)
		{
			TransferComp.EvaluationTarget.Reset();
			return false;
		}
		FVector OtherSplineStartLocation = TransferComp.HeightOffsetedEvaluationWorldLocation;

		TransferComp.EvaluationTarget.ReverseTowardsDirection(UserGrindComp.SplinePosition.WorldForwardVector);

		UserGrindComp.UpdateTargetPointLocation(TransferComp.EvaluationTarget.SystemPosition.WorldLocation);
		ActivationPoint.SetWorldLocation(UserGrindComp.TargetPointLocation + TransferComp.EvaluationTarget.SystemPosition.WorldUpVector * TransferComp.EvaluationTarget.GrindSpline.HeightOffset);
		ActivationPoint.AttachTo(TransferComp.EvaluationTarget.GrindSpline.RootComponent, NAME_None, EAttachLocation::KeepWorldPosition, true);

		// Enable the activation point if we weren't using it before
		if (ActivationPoint.ValidationType == EHazeActivationPointActivatorType::None)
			ActivationPoint.ChangeValidActivator(Player.IsCody() ? EHazeActivationPointActivatorType::Cody : EHazeActivationPointActivatorType::May);

		Player.UpdateActivationPointAndWidgets(UGrindingTransferActivationPoint::StaticClass());
		if (!ActivationPoint.IsTargetedBy(Player))
			TransferComp.EvaluationTarget.Reset();

		if (IsDebugActive())
		{
			System::DrawDebugSphere(TransferComp.HeightOffsetedEvaluationWorldLocation, 25.f, LineColor = FLinearColor::Green, Duration = 0.f);
			System::DrawDebugSphere(OtherSplineStartLocation, 25.f, LineColor = FLinearColor::Yellow, Duration = 0.f);

			DebugDrawArrowDelta(TestDirection * 250.f, 15.f, FLinearColor::Purple, 0.f, 5.f);

			DebugDrawLine(TargetLocation, TransferComp.EvaluationPosition.WorldLocation, FLinearColor::Green, 0.f);
			DebugDrawLine(TargetLocation, OtherSplineStartLocation, FLinearColor::Yellow, 0.f);
		}

		return true;
	}

	/*
		Camera control moves a point in front of the players view direction (follows camera completely)
		Input is not constrained at all
	*/
	FVector GetTestLocationVersion1(FVector FuturePosition)
	{
		FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementRaw);
		FVector InputUp = MoveComp.WorldUp * MoveInput.X;
		FVector InputRight = Player.ViewRotation.RightVector * MoveInput.Y;
		FVector TestDirection = InputUp + InputRight;

		FVector TestLocation = FuturePosition;
		TestLocation += Player.ViewRotation.ForwardVector * GrindSettings::Transfer.AttachPointForwardDistance;
		TestLocation += TestDirection * GrindSettings::Transfer.AttachPointForwardDistance;

		return TestLocation;
	}

	/*
		Fixed point in front of the players forward
		Camera control is constrained to players forward plane
		Input is contrained to players forward plane
	*/
	FVector GetTestLocationVersion2(FVector FuturePosition)
	{
		FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementRaw);
		FVector InputUp = MoveComp.WorldUp * MoveInput.X;
		FVector InputRight = Player.ViewRotation.RightVector * MoveInput.Y;
		FVector TestDirection = InputUp + InputRight;

		FVector TestLocation = FuturePosition;

		// Add on left stick to guide the 
			/* 	This should be updated to more accurately represent what the player might want to do. 
				Doesnt work well when facing perpendicular to the spline forward
			*/
		TestDirection = TestDirection.ConstrainToPlane(Owner.ActorForwardVector);		
		TestLocation += TestDirection * GrindSettings::Transfer.AttachPointForwardDistance;
		
		// Add on the cameras facing direction, but dont allow forward or backwards
		TestLocation += Owner.ActorForwardVector * GrindSettings::Transfer.AttachPointForwardDistance;
		TestLocation += (Player.ViewRotation.ForwardVector * GrindSettings::Transfer.AttachPointForwardDistance).ConstrainToPlane(Owner.ActorForwardVector);

		return TestLocation;
	}

	/*
		Mix of 1 and 2
		Camera control moves a point in front of the players view direction (follows camera completely)
		Input is contrained to players forward plane
	*/
	FVector GetTestLocationVersion3(FVector FuturePosition)
	{
		FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementRaw);
		FVector InputUp = MoveComp.WorldUp * MoveInput.X;
		FVector InputRight = Player.ViewRotation.RightVector * MoveInput.Y;
		FVector TestDirection = InputUp + InputRight;

		FVector TestLocation = FuturePosition;
		TestLocation += Player.ViewRotation.ForwardVector * GrindSettings::Transfer.AttachPointForwardDistance;

		// Add on left stick to guide the 
			/* 	This should be updated to more accurately represent what the player might want to do. 
				Doesnt work well when facing perpendicular to the spline forward
			*/
		TestDirection = TestDirection.ConstrainToPlane(Owner.ActorForwardVector);		
		TestLocation += TestDirection * GrindSettings::Transfer.AttachPointForwardDistance;

		return TestLocation;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (DeactiveDuration < 0.25f)
       		return EHazeNetworkActivation::DontActivate;

		if (!UserGrindComp.HasActiveGrindSpline())
       		return EHazeNetworkActivation::DontActivate;

		if (!TransferComp.IsEvalTargetValid())
        	return EHazeNetworkActivation::DontActivate;

		if (!WasActionStartedDuringTime(ActionNames::SwingAttach, 0.1f))
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (UserGrindComp.HasActiveGrindSpline())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (bReachedTarget)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!UserGrindComp.HasTargetGrindSpline())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		UHazeSplineComponentBase SplineComp;
		float Distance = 0.f;
		bool bForward = true;
		TransferComp.EvaluationPosition.BreakData(SplineComp, Distance, bForward);
		
		AGrindspline TargetGrindSpline = TransferComp.EvaluationTarget.GrindSpline;
		ActivationParams.AddObject(n"TargetGrindSpline", TargetGrindSpline);
		ActivationParams.AddObject(n"TargetSplineComp", SplineComp);
		ActivationParams.AddValue(n"TargetSplineDistance", Distance);
		if (bForward)
			ActivationParams.AddActionState(n"TargetSplineForward");
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Owner.BlockCapabilities(GrindingCapabilityTags::BlockedWhileGrinding, this);

		InitialLocation = UserGrindComp.ActiveGrindSplineData.HeightOffsetedWorldLocation;
		bReachedTarget = false;

		UserGrindComp.LeaveActiveGrindSpline(EGrindDetachReason::Transfer);
		UserGrindComp.StartGrindSplineCooldown(UserGrindComp.ActiveGrindSplineData.GrindSpline);
		
		AGrindspline GrindSpline = Cast<AGrindspline>(ActivationParams.GetObject(n"TargetGrindSpline"));
		UHazeSplineComponentBase SplineComp = Cast<UHazeSplineComponentBase>(ActivationParams.GetObject(n"TargetSplineComp"));
		float Distance = ActivationParams.GetValue(n"TargetSplineDistance");
		bool bForward = ActivationParams.GetActionState(n"TargetSplineForward");
		FGrindSplineData TargetGrindSplineData(GrindSpline, SplineComp, Distance, bForward);

		UserGrindComp.UpdateTargetGrindSpline(TargetGrindSplineData);

		Speed = 3400.f;
		InitialDistanceToTarget = (UserGrindComp.TargetGrindSplineData.HeightOffsetedWorldLocation - MoveComp.OwnerLocation).Size();

		// We would get a division by zero down below if this triggered previously. I just added an if statement
		// in order to fix it, but this case should perhaps be handled differently? 
		// feel free to remove this ensure if you want 
		ensure(InitialDistanceToTarget > 0.f);

		ActiveBlocks = UserGrindComp.TargetGrindSplineData.GrindSpline.CapabilityBlocks;
		for (FName CapabilityTag : ActiveBlocks)
		{
			Player.BlockCapabilities(CapabilityTag, this);
		}

		if (HasControl())
			MoveComp.SetTargetFacingDirection(TargetGrindSplineData.SystemPosition.WorldForwardVector, 2.f);

		if (UserGrindComp.GrindingForceFeedbackData != nullptr && UserGrindComp.GrindingForceFeedbackData.TransferJumpRumble != nullptr)
			Player.PlayForceFeedback(UserGrindComp.GrindingForceFeedbackData.TransferJumpRumble, false, true, NAME_None, 0.5f);

		Player.SetAnimVectorParam(n"GrindTransferLocation", TargetGrindSplineData.SystemPosition.WorldLocation);

		GrindSpline.OnPlayerTargeted.Broadcast(Player, EGrindTargetReason::Transfer);		
		UserGrindComp.OnGrindSplineTargeted.Broadcast(GrindSpline, EGrindTargetReason::Transfer);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Owner.UnblockCapabilities(GrindingCapabilityTags::BlockedWhileGrinding, this);
		for (FName CapabilityTag : ActiveBlocks)
		{
			Player.UnblockCapabilities(CapabilityTag, this);
		}

		if (!UserGrindComp.IsValidToStartGrinding())
			return;

		UserGrindComp.StartGrinding(UserGrindComp.TargetGrindSplineData, EGrindAttachReason::Transfer);

		if (UserGrindComp.GrindingForceFeedbackData != nullptr && UserGrindComp.GrindingForceFeedbackData.TransferLandRumble != nullptr)
			Player.PlayForceFeedback(UserGrindComp.GrindingForceFeedbackData.TransferLandRumble, false, true, NAME_None, 0.4f);

		Player.SetAnimVectorParam(n"GrindTransferLocation", FVector::ZeroVector);
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"GrindTransfer");
			CalculateFrameMove(FrameMove, DeltaTime);
			FrameMove.OverrideCollisionSolver(n"NoCollisionSolver");
			MoveCharacter(FrameMove, n"GrindTransfer");
			
			CrumbComp.LeaveMovementCrumb();	
		}
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{
			FVector ToTransfer = UserGrindComp.TargetGrindSplineData.HeightOffsetedWorldLocation - MoveComp.OwnerLocation;
			ToTransfer = ToTransfer.ConstrainToPlane(MoveComp.WorldUp);

			// Calculate the position the player will move towards, and add a bit of height bsed on the distance to target
			FVector TargetLocation = UserGrindComp.TargetGrindSplineData.HeightOffsetedWorldLocation;
			TargetLocation += MoveComp.WorldUp * ToTransfer.Size() * 0.25f;

			// The direction of the move
			FVector ToTarget = (TargetLocation - MoveComp.OwnerLocation).GetSafeNormal();
			
			// Scale the speed so that the transfer duration is similar between short and long jumps
			const float SpeedScaler = FMath::Clamp((UserGrindComp.TargetGrindSplineData.HeightOffsetedWorldLocation - InitialLocation).Size() / 1000.f, 0.5f, 1.5f);
			const float MaxSpeed = 3100.f * SpeedScaler;
			const float MinSpeed = 2200.f * SpeedScaler;

			
			// Calculate the speed curve so you slow down a bit in the middle of the jump
			const float DistanceToTarget = ToTransfer.Size();

			float DistancePercentage = 0.f;
			if(InitialDistanceToTarget != 0.f)
				DistancePercentage = FMath::Clamp(DistanceToTarget / InitialDistanceToTarget, 0.f, 1.f);

			float Alpha = 1.f + FMath::Sin(PI + (DistancePercentage * PI));
			Speed = FMath::Lerp(MinSpeed, MaxSpeed, Alpha);

			// Calculate the move delta
			FVector DeltaMove = ToTarget * Speed * DeltaTime;
            if (DistanceToTarget <= DeltaMove.Size())
            {
                DeltaMove = ToTransfer.GetSafeNormal() * DistanceToTarget;
                bReachedTarget = true;
            }

			FrameMove.ApplyDelta(DeltaMove);
			FrameMove.OverrideStepDownHeight(0.f);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}

		FrameMove.ApplyTargetRotationDelta(); 		
	}

	FGrindSplineData GetBestPotentialTransferSplineInDirection(FVector FromLocation, FVector Direction)
	{
		FGrindSplineData GrindSplineLocationData;
		float Distance = BIG_NUMBER;

		for (AGrindspline PotentialGrindSpline : UserGrindComp.ValidNearbyGrindSplines)
		{
			// Ignore if target does not accept arriving transfers
			if (PotentialGrindSpline.TransferDirection == EGrindSplineTransferDirection::TransferFrom)
				continue;

			if (!PotentialGrindSpline.bGrindingAllowed)
				continue;

			// Get the nearest location on the potential spline
			FHazeSplineSystemPosition PotentialPosition = PotentialGrindSpline.Spline.GetPositionClosestToWorldLocation(FromLocation, true);
			FVector HeightOffset = PotentialPosition.WorldUpVector * PotentialGrindSpline.HeightOffset;
			FVector ToPotentialPosition = (PotentialPosition.WorldLocation + HeightOffset) - FromLocation;

			// Update the spline data with the one that has the shortest distance
			float PotentialDistance = ToPotentialPosition.Size();
			if (PotentialDistance < Distance)
			{
				GrindSplineLocationData.GrindSpline = PotentialGrindSpline;
				GrindSplineLocationData.SystemPosition = PotentialPosition;
				Distance = PotentialDistance;
			}
		}
		
		return GrindSplineLocationData;
	}
}
