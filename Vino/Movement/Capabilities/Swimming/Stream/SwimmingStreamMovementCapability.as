import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Capabilities.Swimming.Stream.SwimmingStream;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Swimming.SwimmingCollisionHandler;
import Vino.Movement.Capabilities.Swimming.SwimmingSettings;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;

class USwimmingStreamMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	default CapabilityTags.Add(SwimmingTags::Underwater);
	default CapabilityTags.Add(SwimmingTags::Stream);

	default CapabilityDebugCategory = n"Movement Swimming";
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 40;

	AHazePlayerCharacter Player;
	USnowGlobeSwimmingComponent SwimComp;
	UPlayerHazeAkComponent HazeAkComp;

	UStreamComponent StreamComponent;
	float DistanceAlongSpline = 0.f;
	float StreamSpeed = 0.f;
	FVector2D PlaneVelocity;
	FVector2D PlaneOffset;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Player);
		HazeAkComp = UPlayerHazeAkComponent::Get(Owner);
		
		Player.CapsuleComponent.OnComponentBeginOverlap.AddUFunction(this, n"PlayerBeginOverlap");
		Player.CapsuleComponent.OnComponentEndOverlap.AddUFunction(this, n"PlayerEndOverlap");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SwimComp == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!SwimComp.bIsInWater)
			return EHazeNetworkActivation::DontActivate;

		ASwimmingStream ActiveNearbyStream = GetFirstNearbyStreamThatShouldTakeControl();
		if (ActiveNearbyStream == nullptr)
			return EHazeNetworkActivation::DontActivate;

		SwimComp.ActiveStream = ActiveNearbyStream;
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SwimComp.bIsInWater)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!SwimComp.ActiveStream.IsStreamActive())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!IsInsideStream(SwimComp.ActiveStream, false))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	ASwimmingStream GetFirstNearbyStreamThatShouldTakeControl() const
	{
		for (int Index = 0, Count = SwimComp.NearbyStreams.Num(); Index < Count; ++Index)
		{	
			if (SwimComp.NearbyStreams[Index] == nullptr)
				continue;

			if (!SwimComp.NearbyStreams[Index].StreamComponent.IsStreamActive())
				continue;			

			if (IsInsideStream(SwimComp.NearbyStreams[Index]))
				return SwimComp.NearbyStreams[Index];
		}
		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"ActiveStream", SwimComp.ActiveStream);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FCapabilityActivationParams& ActivationParams)
	{
		SwimComp.ActiveStream = Cast<ASwimmingStream>(ActivationParams.GetObject(n"ActiveStream"));
		StreamComponent = SwimComp.ActiveStream.StreamComponent;
		
		DistanceAlongSpline = SwimComp.ActiveStream.StreamComponent.GetDistanceAlongSplineAtWorldLocation(Player.ActorLocation);

		FVector Tangent = StreamComponent.GetTangentAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World).GetSafeNormal();
		FVector HorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(Tangent);
		PlaneVelocity = GetPlaneVelocityFromWorldVelocity(HorizontalVelocity, DistanceAlongSpline);

		PlaneOffset = GetPlaneOffsetAtDistanceAlongSpline(DistanceAlongSpline);

		StreamSpeed = Tangent.DotProduct(MoveComp.Velocity);

		SwimComp.SwimmingState = ESwimmingState::Stream;

		Player.BlockCapabilities(n"SwimmingBoost", this);

		float CurrentSpeed = PlaneVelocity.Size();
		float Value = CurrentSpeed / HorizontalTopSpeed;
		HazeAkComp.SetRTPCValue("Rtpc_Vehicle_Swimming_StreamMovement", Value);

		const float CurrentDistance = PlaneOffset.Size();
		const float MaximumDistance = StreamComponent.GetDistanceScaleAtDistance(DistanceAlongSpline) * StreamComponent.StreamDistance;
		const float DistanceDifference = MaximumDistance - CurrentDistance;

		if (DistanceDifference <= 1000.f)
		{
			if (SwimComp.AudioData[Player].StreamEnter != nullptr)
				HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].StreamEnter);
		}
		else
		{
			if (SwimComp.AudioData[Player].StreamEnterSoft != nullptr)
				HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].StreamEnterSoft);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwimComp.ActiveStream = nullptr;

		Player.UnblockCapabilities(n"SwimmingBoost", this);

		if (SwimComp.AudioData[Player].StreamExit != nullptr)
			HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].StreamExit);

		HazeAkComp.SetRTPCValue("Rtpc_Vehicle_Swimming_StreamMovement", 0.f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			
		if(!SwimComp.ActiveStream.IsStreamActive())
		{
			return;
		}	
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SwimmingStream");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveCharacter(FrameMove, n"SwimmingStream");
			
			CrumbComp.LeaveMovementCrumb();	
		}

		float CurrentSpeed = PlaneVelocity.Size();
		float Value = CurrentSpeed / HorizontalTopSpeed;
		HazeAkComp.SetRTPCValue("Rtpc_Vehicle_Swimming_StreamMovement", Value);	
	}

	float GetHorizontalTopSpeed() property
	{
		return SwimmingSettings::Stream.StreamPlayerHorizontalAcceleration / SwimmingSettings::Stream.StreamPlayerDrag;
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{
			ApplyStreamForwardMovement(DeltaTime, FrameMove);
			ApplyPlayersPlaneMovement(DeltaTime, FrameMove);

			FrameMove.OverrideCollisionSolver(USwimmingCollisionSolver::StaticClass());
			FrameMove.ApplyAndConsumeImpulses();
			FrameMove.OverrideStepDownHeight(0.f);
			FrameMove.OverrideGroundedState(EHazeGroundedState::Airborne);

			FVector FacingDirection = FrameMove.Velocity.GetSafeNormal();
			if (FacingDirection.IsNearlyZero())
				FacingDirection = StreamComponent.GetTangentAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World).GetSafeNormal();
			MoveComp.SetTargetFacingDirection(FacingDirection, 8.f);
			FrameMove.ApplyTargetRotationDelta();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}	
	}

	void ApplyStreamForwardMovement(float DeltaTime, FHazeFrameMovement& FrameMove)
	{
		// Apply Drag
		StreamSpeed -= StreamSpeed * SwimmingSettings::Stream.StreamForwardDrag * DeltaTime;

		// Apply Acceleration
		float CurrentStreamStrength = GetPlayersStreamStrengthAtDistance(DistanceAlongSpline);
		StreamSpeed += CurrentStreamStrength * DeltaTime;

		// Update Distance Along Spline
		float PreviousDistanceAlongSpline = DistanceAlongSpline;
		DistanceAlongSpline += (StreamSpeed * DeltaTime);

		if (StreamComponent.IsClosedLoop())
		{
			if (DistanceAlongSpline < 0.f)
				DistanceAlongSpline += StreamComponent.SplineLength;
			else if (DistanceAlongSpline >= StreamComponent.SplineLength)
				DistanceAlongSpline -= StreamComponent.SplineLength;
		}
	}

	void ApplyPlayersPlaneMovement(float DeltaTime, FHazeFrameMovement& FrameMove)
	{
		// Apply Drag
		PlaneVelocity -= PlaneVelocity * SwimmingSettings::Stream.StreamPlayerDrag * DeltaTime;

		// Apply Acceleration
		FVector Input = GetAttributeVector(AttributeVectorNames::MovementRaw);

		float VerticalInput = 0.f;
		if (IsActioning(ActionNames::MovementJump))
			VerticalInput += 1.f;
		if (IsActioning(ActionNames::MovementCrouch))
			VerticalInput -= 1.f;
		VerticalInput = FMath::Clamp(VerticalInput, -1.f, 1.f);

		SwimComp.StreamInput = FVector2D(Input.Y, VerticalInput);

		FVector2D PlaneAcceleration;
		PlaneAcceleration.X = SwimmingSettings::Stream.StreamPlayerVerticalAcceleration * SwimComp.StreamInput.Y * DeltaTime;
		PlaneAcceleration.Y = SwimmingSettings::Stream.StreamPlayerHorizontalAcceleration * SwimComp.StreamInput.X * DeltaTime;		
		PlaneVelocity += PlaneAcceleration;

		PlaneOffset += PlaneVelocity * DeltaTime;

		float StreamDistanceMax = StreamComponent.GetStreamDistanceAtDistance(DistanceAlongSpline);
		if (StreamComponent.bLockPlayersInside && PlaneOffset.Size() > StreamDistanceMax)
		{
			// Clamp the offset to the margin
			//PrintScaled("PlaneOffset Length = " + PlaneOffset.Size()  + " / Max: " + StreamDistanceMax, 2.f, Scale = 2.f);
			PlaneOffset = PlaneOffset.GetClampedToMaxSize(StreamDistanceMax);


			// Remove the offset velocity away from the spline
			// FVector2D PlaneOffsetDirection = PlaneOffset.GetSafeNormal();
			// float SpeedTowardsPlaneOffset = PlaneOffsetDirection.DotProduct(PlaneVelocity);
			// PlaneVelocity -= PlaneOffsetDirection * SpeedTowardsPlaneOffset;
		}

		FVector NewLocation = GetLocationWithOffsetAtDistanceAlongSpline(DistanceAlongSpline);

		FVector DeltaMove = NewLocation - Owner.ActorLocation;
		FrameMove.ApplyDelta(DeltaMove);
	}

	bool IsInsideStream(ASwimmingStream SwimmingStream, bool bIsActivation = true) const
	{
		float _DistanceAlongSpline = SwimmingStream.StreamComponent.GetDistanceAlongSplineAtWorldLocation(Player.ActorLocation);

		float StreamScale = SwimmingStream.StreamComponent.GetDistanceScaleAtDistance(_DistanceAlongSpline);
		float StreamDistance = SwimmingStream.StreamComponent.StreamDistance;
		float StreamScaledDistance = StreamScale * StreamDistance;		
		
		FVector ClosestPointOnSpline = SwimmingStream.StreamComponent.FindLocationClosestToWorldLocation(Owner.ActorLocation, ESplineCoordinateSpace::World);
		FVector PlayerToSpline = ClosestPointOnSpline - Owner.ActorLocation;

		const float SplineLength = SwimmingStream.StreamComponent.SplineLength;
		if (_DistanceAlongSpline == 0.f || _DistanceAlongSpline == SplineLength)
		{
			if (bIsActivation)
				StreamScaledDistance *= 0.5f;

			if (PlayerToSpline.Size() <= StreamScaledDistance)
				return true;
		}
		else
		{

			if (!bIsActivation && SwimmingStream.StreamComponent.bLockPlayersInside)
				return true;

			if (PlayerToSpline.Size() <= StreamScaledDistance)
				return true;
		}

		return false;
	}

	float GetPlayersStreamStrengthAtDistance(float DistanceAlongSpline)
	{
		float Alpha = GetPlayersDistancePercentageAtDistance(DistanceAlongSpline);

		// Make sure the strength is 0 if the player is outside the stream (they should leave anyway)
		if (Alpha > 1.f)
			return 0.f;

		float StreamStrengthAtCenter = StreamComponent.GetStreamStrengthAtDistance(DistanceAlongSpline);
		float StreamStrengthAtEdge = StreamStrengthAtCenter * StreamComponent.StreamStrengthAtEdge;		

		float StreamStrength = FMath::Lerp(StreamStrengthAtCenter, StreamStrengthAtEdge, Alpha);
		return StreamStrength;
	}

	float GetPlayersDistancePercentageAtDistance(float DistanceAlongSpline)
	{
		float CurrentDistance = PlaneOffset.Size();
		if (FMath::IsNearlyZero(CurrentDistance))
			return 0.f;

		float MaximumDistance = StreamComponent.GetDistanceScaleAtDistance(DistanceAlongSpline) * StreamComponent.StreamDistance;
		float Percentage = FMath::Clamp(CurrentDistance / MaximumDistance, 0.f, 1.f);
		
		return Percentage;
	}



	// FVector GetLocationAtDistanceAlongSplineAtPlayerStreamPercentage(float DistanceAlongSpline, FVector2D Percentage)
	// {
	// 	float StreamDistance = GetStreamDistanceAtDistanceAlongSpline(DistanceAlongSpline);

	// 	FVector Tangent = SwimComp.ActiveStream.StreamComponent.GetTangentAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
	// 	FVector MoveRight = MoveComp.WorldUp.CrossProduct(Tangent.GetSafeNormal());

	// 	FVector Vertical = MoveComp.WorldUp * Percentage.X * StreamDistance;
	// 	FVector Lateral = MoveRight * Percentage.Y * StreamDistance;

	// 	return Vertical + Lateral;
	// }




	// float GetStreamStrength(float DistanceAlongSpline, ASwimmingStream SwimmingStream)
	// {
	// 	FVector ClosestPointOnSpline = SwimmingStream.StreamComponent.FindLocationClosestToWorldLocation(Owner.ActorLocation, ESplineCoordinateSpace::World);

	// 	float StreamScale = SwimmingStream.StreamComponent.GetDistanceScaleAtDistance(DistanceAlongSpline);
	// 	float StreamDistance = SwimmingStream.StreamComponent.StreamDistance;
	// 	float StreamScaledDistance = StreamScale * StreamDistance;

	// 	float DefaultStreamStrength = SwimmingStream.StreamComponent.StreamStrength;
	// 	float StreamStrengthAtMaxDistance = SwimmingStream.StreamComponent.StreamStrengthAtMaxDistance;
		
	// 	// Get the distance from actor location to spline location
	// 	float DistanceToSpline = (ClosestPointOnSpline - Owner.ActorLocation).Size();

	// 	// If the distance is greater than the spline distance, stength should be 0
	// 	if (DistanceToSpline > StreamScaledDistance)
	// 		return 0.f;

	// 	// Calculate the percentage you are away from the spline
	// 	float DistanceScale = 1 - FMath::Clamp(DistanceToSpline / StreamScaledDistance, 0.f, 1.f);

	// 	// Stream strength at the eye of the stream
	// 	float MaxStreamStrength = DefaultStreamStrength * StreamScale;

	// 	// Stream strength at the edge of the stream
	// 	float MinStreamStrength = MaxStreamStrength * StreamStrengthAtMaxDistance;

	// 	// Calculate the actual stream strength due to distance
	// 	float StreamStrength = FMath::Lerp(MinStreamStrength, MaxStreamStrength, DistanceScale);

	// 	return  StreamStrength;
	// }

	UFUNCTION(NotBlueprintCallable)
	void PlayerBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
		UPrimitiveComponent OtherComponent, int OtherBodyIndex,
		bool bFromSweep, FHitResult& Hit)
	{
		ASwimmingStream SwimmingStream = Cast<ASwimmingStream>(OtherActor);
		if (SwimmingStream == nullptr)
			return;

		if (OtherComponent != SwimmingStream.StreamBox)
			return;
		
		SwimComp.NearbyStreams.Add(SwimmingStream);
    }

	UFUNCTION(NotBlueprintCallable)
    void PlayerEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		ASwimmingStream SwimmingStream = Cast<ASwimmingStream>(OtherActor);
		if (SwimmingStream == nullptr)
			return;

		if (OtherComponent != SwimmingStream.StreamBox)
			return;

		SwimComp.NearbyStreams.Remove(SwimmingStream);
    }

	FTransform GetPlaneTransformAtDistanceAlongSpline(float InDistanceAlongSpline)
	{
		FVector Location = StreamComponent.GetLocationAtDistanceAlongSpline(InDistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector Tangent = StreamComponent.GetTangentAtDistanceAlongSpline(InDistanceAlongSpline, ESplineCoordinateSpace::World).GetSafeNormal();
		FVector UpVector = StreamComponent.GetUpVectorAtDistanceAlongSpline(InDistanceAlongSpline, ESplineCoordinateSpace::World).GetSafeNormal();
		FRotator Rotation = FRotator::MakeFromXZ(Tangent, UpVector);

		return FTransform(Rotation, Location);
	}

	FVector2D GetPlaneOffsetAtDistanceAlongSpline(float InDistanceAlongSpline)
	{
		FTransform PlaneTransform = GetPlaneTransformAtDistanceAlongSpline(InDistanceAlongSpline);
		FVector ToPlayer = Owner.ActorLocation - PlaneTransform.Location;
		FVector Offset = PlaneTransform.InverseTransformVectorNoScale(ToPlayer);

		return FVector2D(Offset.Z, Offset.Y);
	}

	FVector GetLocationWithOffsetAtDistanceAlongSpline(float InDistanceAlongSpline)
	{
		FTransform PlaneTransform = GetPlaneTransformAtDistanceAlongSpline(InDistanceAlongSpline);

		if (!StreamComponent.IsClosedLoop() && DistanceAlongSpline > StreamComponent.SplineLength)
		{
			float Overshoot = DistanceAlongSpline - StreamComponent.SplineLength;
			
			FVector Location = StreamComponent.GetLocationAtDistanceAlongSpline(StreamComponent.SplineLength, ESplineCoordinateSpace::World);
			FVector EndTangent = StreamComponent.GetTangentAtDistanceAlongSpline(StreamComponent.SplineLength, ESplineCoordinateSpace::World).GetSafeNormal();
			PlaneTransform.Location = Location + (EndTangent * Overshoot);
		}

		FVector Offset = FVector(0.f, PlaneOffset.Y, PlaneOffset.X);
		FVector ToPlayer = PlaneTransform.TransformVectorNoScale(Offset);

		return PlaneTransform.Location + ToPlayer;
	}

	FVector2D GetPlaneVelocityFromWorldVelocity(FVector WorldVelocity, float InDistanceAlongSpline)
	{
		FTransform SplineTransform = GetPlaneTransformAtDistanceAlongSpline(InDistanceAlongSpline);
		FVector SplineVelocity = SplineTransform.InverseTransformVectorNoScale(WorldVelocity);

		return FVector2D(SplineVelocity.Z, SplineVelocity.Y);
	}

	FVector GetWorldVelocityFromPlaneVelocity(FVector2D PlaneVelocity, float InDistanceAlongSpline)
	{
		FVector _PlaneVelocity = FVector(0.f, PlaneVelocity.Y, PlaneVelocity.X);

		FTransform SplineTransform = GetPlaneTransformAtDistanceAlongSpline(InDistanceAlongSpline);
		FVector SplineVelocity = SplineTransform.TransformVectorNoScale(_PlaneVelocity);

		return SplineVelocity;
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		if(IsActive())
		{
			FString DebugText = "";
			
			DebugText += "Stream Speed: " + StreamSpeed + "\n";
			DebugText += "Stream Drag: " + SwimmingSettings::Stream.StreamForwardDrag + "\n\n";

			DebugText += "Distance Along Spline: " + DistanceAlongSpline + "\n";			
			DebugText += "Percentage: " + GetPlayersDistancePercentageAtDistance(DistanceAlongSpline) + "\n";
			DebugText += "Stream Strength: " + GetPlayersStreamStrengthAtDistance(DistanceAlongSpline);

			return DebugText;
		}

		return "Not Active";
	}
}
