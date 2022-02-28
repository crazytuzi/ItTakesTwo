import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Swinging.SwingComponent;
import Vino.Movement.Swinging.SwingSettings;

class USwingGrappleFromGroundCapability : UCharacterMovementCapability
{	
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::MovementAction);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SwingGrapple");
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 4;

	default CapabilityDebugCategory = n"Movement Swinging";

	AHazePlayerCharacter Player;
	USwingingComponent SwingingComponent;
	FSwingSettings SwingSettings;

	USwingPointComponent ActiveSwingPoint;
	FVector InitialPlayerToSwingPoint;	

	float StartSpeed = 0.f;
	float EndSpeed = 1800.f;
	float CurrentDistance = 0.f;

	const float EntryDegreesFromPosition = 35.f;

	float CurveAlpha = 0.f;
	float CurveLength = 0.f;

	FVector GrappleStartLocation;
	FVector GrappleStartTangentLocation;
	FVector GrappleEndTangentLocation;
	FVector GrappleEndLocation;

	float DebugDrawTime = 5.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwingingComponent = USwingingComponent::GetOrCreate(Owner);

		SwingingComponent.OnAttachedToSwingPoint.AddUFunction(this, n"OnAttachedToSwingPoint");
		SwingingComponent.OnDetachedFromSwingPoint.AddUFunction(this, n"OnDetachedFromSwingPoint");

	}

	UFUNCTION()
	void OnAttachedToSwingPoint(USwingPointComponent SwingPoint)
	{
		if (SwingPoint == nullptr)
			return;

		ActiveSwingPoint = SwingPoint;
	}

	UFUNCTION()
	void OnDetachedFromSwingPoint(USwingPointComponent SwingPoint)
	{
		ActiveSwingPoint = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsAirborne())
			return EHazeNetworkActivation::DontActivate;

		if (ActiveSwingPoint == nullptr)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
		{
			if (HasControl())
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			else
				return EHazeNetworkDeactivation::DeactivateLocal;
		}

		if (CurveAlpha >= 1.f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ActiveSwingPoint = SwingingComponent.GetActiveSwingPoint();

		MoveComp.Velocity = (MoveComp.WorldUp + SwingingComponent.PlayerToSwingPoint.GetSafeNormal()) / 2.f;
		MoveComp.Velocity = MoveComp.Velocity * 3400.f;
		//SwingingComponent.PlayerToSwingPoint.GetSafeNormal() * 2400.f;

		// Player.ApplyPivotLagSpeed(FVector(0.f, 0.f, 0.f), this, EHazeCameraPriority::Low);
		// Player.ApplyPivotLagMax(FVector(200.f, 200.f, 400.f), this, EHazeCameraPriority::Low);

		CurveAlpha = 0.f;
		CurrentDistance = 0.f;		

		InitialPlayerToSwingPoint = SwingingComponent.PlayerToSwingPoint;

		SetLocationsAndTangentsForStraightCurve();
		//SetLocationsAndTangentsForCurvedCurve();

		StartSpeed = MoveComp.Velocity.Size() * 1.25f;
		//StartSpeed = GetExpectedSpeedAtSwingPosition(-SwingingComponent.PlayerToSwingPoint);
		EndSpeed = GetExpectedSpeedAtSwingPosition(GrappleEndLocation - ActiveSwingPoint.WorldLocation);

		if (IsDebugActive())
		{
			System::DrawDebugLine(GrappleStartLocation, GrappleStartTangentLocation, FLinearColor::Gray, DebugDrawTime);
			System::DrawDebugLine(GrappleStartTangentLocation, GrappleEndTangentLocation, FLinearColor::Gray, DebugDrawTime);
			System::DrawDebugLine(GrappleEndTangentLocation, GrappleEndLocation, FLinearColor::Gray, DebugDrawTime);

			System::DrawDebugPoint(GrappleStartLocation, 4.f, FLinearColor::Black, DebugDrawTime);
			System::DrawDebugPoint(GrappleStartTangentLocation, 4.f, FLinearColor::Black, DebugDrawTime);
			System::DrawDebugPoint(GrappleEndTangentLocation, 4.f, FLinearColor::Black, DebugDrawTime);
			System::DrawDebugPoint(GrappleEndLocation, 4.f, FLinearColor::Black, DebugDrawTime);

			//System::DrawDebugSphere(ActiveSwingPoint.WorldLocation, ActiveSwingPoint.SwingDistance, 32, FLinearColor::Green, Duration = DebugDrawTime, Thickness = 1.f);
		}

		// Calculate the length of the curve
		int Iterations = 50;
		CurveLength = 0.f;
		for (int Index = 0, Count = Iterations; Index < Count; ++Index)
		{
			float StartAlpha = (1.f / Count) * Index;
			FVector StartLocation = GetLocationOnGrappleCurve(StartAlpha);
			float EndAlpha = (1.f / Count) * (Index + 1);
			FVector EndLocation = GetLocationOnGrappleCurve(EndAlpha);

			CurveLength += (EndLocation - StartLocation).Size();

			if (IsDebugActive())
				System::DrawDebugLine(StartLocation, EndLocation, FLinearColor::LucBlue, DebugDrawTime);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ActiveSwingPoint = nullptr;
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"Swinging");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveCharacter(FrameMove, n"Swinging");
			
			CrumbComp.LeaveMovementCrumb();	
		}
	}	

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{	
			float Speed = MoveComp.Velocity.Size();
			float DeltaDistance = MoveComp.Velocity.Size() * DeltaTime;
			CurrentDistance = CurrentDistance += DeltaDistance;

			CurveAlpha = Math::Saturate(CurrentDistance / CurveLength);
			FVector NewLocation = GetLocationOnGrappleCurve(CurveAlpha);
			FVector DeltaMove = NewLocation - SwingingComponent.PlayerLocation;

			float CurrentSpeed = MoveComp.Velocity.Size();
			float SpeedDifference = EndSpeed - CurrentSpeed;
			float Acceleration = SpeedDifference * 6.f * DeltaTime;

			if (FMath::Abs(Acceleration) > FMath::Abs(SpeedDifference))
				CurrentSpeed = EndSpeed;
			else
				CurrentSpeed += Acceleration;

			//float NewSpeed = FMath::Lerp(StartSpeed, EndSpeed, CurveAlpha) * ScaleSpeedByAlpha(CurveAlpha, 0.8f);
			float NewSpeed = CurrentSpeed;
			FString String = "";
			String += "Alpha: " + CurveAlpha;
			String += " - Speed: " + NewSpeed;
			//Print(String, 5.f);

			FrameMove.ApplyDeltaWithCustomVelocity(DeltaMove, DeltaMove.GetSafeNormal() * NewSpeed);
			FrameMove.OverrideGroundedState(EHazeGroundedState::Airborne);
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

	FVector GetSwingEnterLocation(FVector Direction = FVector::ZeroVector)
	{
		EntryDegreesFromPosition;

		// Calculate the current position
		FVector SwingPointToPlayer = -InitialPlayerToSwingPoint.GetSafeNormal() * ActiveSwingPoint.RopeLength;
		FVector CurrentPositionOnSwingSphere = ActiveSwingPoint.WorldLocation + SwingPointToPlayer;

		// Calculate the future position
		FVector Axis = Direction.CrossProduct(MoveComp.WorldUp).GetSafeNormal();

		float Angle = EntryDegreesFromPosition * DEG_TO_RAD;
		FQuat RotationQuat = FQuat(Axis, Angle);
		FVector RotatedSwingPointToPlayer = RotationQuat * SwingPointToPlayer;

		FVector TargetPositionOnSwingSphere = ActiveSwingPoint.WorldLocation + RotatedSwingPointToPlayer;

		if (IsDebugActive())
		{
			System::DrawDebugPoint(CurrentPositionOnSwingSphere, 6.f, FLinearColor::Red, DebugDrawTime);
			System::DrawDebugArrow(ActiveSwingPoint.WorldLocation, ActiveSwingPoint.WorldLocation + (Axis * 250.f), 200.f, FLinearColor::Green, DebugDrawTime);
			System::DrawDebugPoint(TargetPositionOnSwingSphere, 6.f, FLinearColor::Green, DebugDrawTime);
			System::DrawDebugArrow(CurrentPositionOnSwingSphere, TargetPositionOnSwingSphere, 200.f, FLinearColor::Yellow, DebugDrawTime);
		}
		
		return TargetPositionOnSwingSphere;
	}

	void SetLocationsAndTangentsForStraightCurve()
	{
		// Store the start and end locations
		GrappleStartLocation = SwingingComponent.PlayerLocation;
		GrappleEndLocation = GetSwingEnterLocation(MoveComp.Velocity);

		// Distance is used to scale the tangents' lengths
		float DistanceToTarget = (SwingingComponent.PlayerLocation - GrappleEndLocation).Size();

		// Calculate the first control point
		FVector GrappleStartTangent = MoveComp.Velocity * 0.2f;
		//FVector GrappleStartTangent = (MoveComp.Velocity.GetSafeNormal() + (GrappleEndLocation - GrappleStartLocation).GetSafeNormal()) / 2.f;
		//GrappleStartTangent *= (GrappleStartLocation - GrappleEndLocation).Size() * 0.25f;

		GrappleStartTangentLocation = GrappleStartLocation + GrappleStartTangent;

		// Calculate the second control point
		FVector UpVector = ActiveSwingPoint.WorldLocation - GrappleEndLocation;
		FVector RightVector = MoveComp.WorldUp.CrossProduct(MoveComp.Velocity);
		FVector ForwardVector = RightVector.CrossProduct(UpVector).GetSafeNormal();
		FVector GrappleEndTangent = -ForwardVector * DistanceToTarget * 0.5f;
		GrappleEndTangentLocation = GrappleEndLocation + GrappleEndTangent;
	}

	void SetLocationsAndTangentsForCurvedCurve()
	{
		// Store the start and end locations
		GrappleStartLocation = SwingingComponent.PlayerLocation;




		GrappleEndLocation = GetSwingEnterLocation(MoveComp.Velocity);
		// Distance is used to scale the tangents' lengths
		float DistanceToTarget = (SwingingComponent.PlayerLocation - GrappleEndLocation).Size();

		// Calculate the first control point
		FVector GrappleStartTangent = MoveComp.Velocity * 0.2f;
		GrappleStartTangentLocation = GrappleStartLocation + GrappleStartTangent;

		// Calculate the second control point
		FVector UpVector = ActiveSwingPoint.WorldLocation - GrappleEndLocation;
		FVector RightVector = MoveComp.WorldUp.CrossProduct(UpVector);
		FVector ForwardVector = RightVector.CrossProduct(UpVector).GetSafeNormal();
		FVector GrappleEndTangent = -ForwardVector * DistanceToTarget * 0.5f;
		GrappleEndTangentLocation = GrappleEndLocation + GrappleEndTangent;
	}

	FVector GetLocationOnGrappleCurve(float Alpha)
	{
		return Math::GetPointOnCubicBezierCurve(GrappleStartLocation, GrappleStartTangentLocation, GrappleEndTangentLocation, GrappleEndLocation, Alpha);
	}

	float ScaleSpeedByAlpha(float Alpha, float LowestValue = 0.5f)
	{
		float SaturatedAlpha = Math::Saturate(Alpha);
		float X = SaturatedAlpha;
		X *= 3.142f;
		X += 3.142f * 0.5f;
		return 1 - (FMath::Pow(FMath::Cos(X), 2.f) * (1.f - LowestValue));
	}

	float GetExpectedSpeedAtSwingPosition(FVector SwingPointToPlayer)
	{	
		float AngleDot = -MoveComp.WorldUp.GetSafeNormal().DotProduct(SwingPointToPlayer.GetSafeNormal());
		float AngleDifference = FMath::RadiansToDegrees(FMath::Acos(AngleDot));
		float AngleLerp = 1 - FMath::Clamp(AngleDifference / (ActiveSwingPoint.SwingAngle), 0.f, 1.f);
		float AngleLerpCurved = FMath::Pow(AngleLerp, 0.32f);
		return 2850.f * AngleLerpCurved;
	}
}
