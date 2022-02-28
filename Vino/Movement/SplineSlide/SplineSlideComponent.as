import Vino.Movement.SplineSlide.SplineSlideSpline;
import Rice.Math.MathStatics;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;

event void FOnSlidingStartedSliding(ASplineSlideSpline SplineSlide);
event void FOnSlidingStoppedSliding(ASplineSlideSpline SplineSlide);

class USplineSlideComponent : UActorComponent
{
	ASplineSlideSpline ActiveSplineSlideSpline;
	TArray<ASplineSlideSpline> NearbySplineSlideSplines;

	UPROPERTY()
	FOnSlidingStartedSliding OnSlidingStarted;

	UPROPERTY()
	FOnSlidingStartedSliding OnSlidingStopped;

	UPROPERTY(Category = "Event Handlers")
	TArray<TSubclassOf<USplineSlideEventHandler>> EventHandlerTypes;
	TArray<USplineSlideEventHandler> EventHandlers;

	// The scale of your speed - used for rubberbanding
	float RubberbandScale = 1.f;

	TArray<UObject> ActiveRampJumps;

	// Set to the potential destination if jumping towards a spline
	// which is a valid destination from previous spline
	ASplineSlideSpline JumpDestination;
	FVector	JumpDestinationEstimatedLandingLocation;
	TMap<ASplineSlideSpline, float> JumpDistanceAlongSplines;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionFeatureBase KnockdownLocomotionFeature_May;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionFeatureBase KnockdownLocomotionFeature_Cody;

	float CurrentLongitudinalSpeed = 0.f;
	AHazeActor ActiveBoost;

	UPROPERTY()
	const float CoyoteTime = 0.22f;

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		CurrentLongitudinalSpeed = 0.f;

		auto Player = Cast<AHazePlayerCharacter>(Owner);
		Player.BlockCapabilities(MovementSystemTags::SplineSlide, this);
		Player.UnblockCapabilities(MovementSystemTags::SplineSlide, this);
		
		ActiveSplineSlideSpline = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Spawn the event handlers!
		for(auto HandlerType : EventHandlerTypes)
		{
			auto Handler = Cast<USplineSlideEventHandler>(NewObject(this, HandlerType));
			EventHandlers.Add(Handler);

			Handler.InitInternal(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for(auto Handler : EventHandlers)
			Handler.OnTick(DeltaTime);
	}

	FSplineSlideSettings GetSplineSettings() property
	{
		if (ActiveSplineSlideSpline == nullptr)
			return FSplineSlideSettings();

		return ActiveSplineSlideSpline.SplineSettings;
	}

	void ConstrainVelocityToSpline(FVector& Velocity, FVector& ReturnedDeltaMove, float DeltaTime)
	{
		if (ActiveSplineSlideSpline == nullptr)
			return;

		ReturnedDeltaMove = Velocity * DeltaTime;

		// Calculate the future position
		FVector FuturePosition = Owner.ActorLocation + ReturnedDeltaMove;

		float FutureDistanceAlongSpline = ActiveSplineSlideSpline.Spline.GetDistanceAlongSplineAtWorldLocation(FuturePosition);
		FVector FutureSplineNearestLocation = ActiveSplineSlideSpline.Spline.GetLocationAtDistanceAlongSpline(FutureDistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector FutureSplineRightVector = ActiveSplineSlideSpline.Spline.GetRightVectorAtDistanceAlongSpline(FutureDistanceAlongSpline, ESplineCoordinateSpace::World).GetSafeNormal();
		float FutureSplineWidth = ActiveSplineSlideSpline.GetWidthAtDistanceAlongSpline(FutureDistanceAlongSpline);

		FVector SplineToFuturePosition = (FuturePosition - FutureSplineNearestLocation).ConstrainToDirection(FutureSplineRightVector);

		// If the spline to future position is farther than the width of the spline
		if (SplineToFuturePosition.Size() > FutureSplineWidth)
		{
			const float Direction = FMath::Sign(SplineToFuturePosition.DotProduct(FutureSplineRightVector));

			// Constrain the delta move to the width of the spline
			const float Overshoot = SplineToFuturePosition.Size() - FutureSplineWidth;
			ReturnedDeltaMove -= FutureSplineRightVector * Overshoot * Direction;

			// Remove outwards velocity
			float RightSpeed = FMath::Max(0.f, FMath::Abs(FutureSplineRightVector.DotProduct(Velocity)))  * Direction;
			Velocity -= FutureSplineRightVector * RightSpeed;
		}
	}

	FVector GetVelocityRotatedTowardsDirection(FVector Velocity, FVector TargetDirection, FVector Axis, FVector WorldUp, FVector SplineForward, float RotationRate)
	{
		FVector FlattenedForward = SplineForward.ConstrainToPlane(WorldUp).GetSafeNormal();

		FVector Direction = TargetDirection.GetSafeNormal();
		if (Direction.DotProduct(FlattenedForward) < 0.f)
			Direction = Direction.ConstrainToPlane(FlattenedForward).GetSafeNormal();

		FVector NewVelocity = Math::RotateVectorTowardsAroundAxis(Velocity, Direction, Axis, RotationRate * FMath::Min(1.f, TargetDirection.Size()));

		return NewVelocity;
	}

	bool IsWithinSplineBounds(ASplineSlideSpline SplineSlideSpline, bool bActivating) const
	{
		return IsWithinSplineLongitudinalBounds(SplineSlideSpline, bActivating) && IsWithinSplineLateralBounds(SplineSlideSpline) && IsWithinSplineVerticalBounds(SplineSlideSpline);
	}

	bool IsWithinSplineLongitudinalBounds(ASplineSlideSpline SplineSlideSpline, bool bActivating) const
	{
		float DistanceAlongSpline = SplineSlideSpline.Spline.GetDistanceAlongSplineAtWorldLocation(Owner.ActorLocation);
		FVector SplineForward = SplineSlideSpline.Spline.GetTangentAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World).GetSafeNormal();
		FVector SplineLocation = SplineSlideSpline.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector SplineToPlayer = Owner.ActorLocation - SplineLocation;

		// If the player is behind the start, or after the end of the spline - return false
		float ForwardDot = SplineToPlayer.DotProduct(SplineForward);
		if (DistanceAlongSpline == 0.f && ForwardDot < 0.f)
			return false;
		else if (DistanceAlongSpline == SplineSlideSpline.Spline.SplineLength)
		{
			/*
				If you are activating: Only check if you are in the bounds of the SplineForward
				If you are deactivating: Allow yourself to stay active past the end of the spline, depending on margin size
			*/
			if (bActivating)
			{				
 				if (ForwardDot > 0.f)
					return false;
			}
			else if (ForwardDot > SplineSlideSpline.SplineEndMargin)
				return false;
		} 

		return true;
	}

	bool IsWithinSplineLateralBounds(ASplineSlideSpline SplineSlideSpline) const
	{
		float DistanceAlongSpline = SplineSlideSpline.Spline.GetDistanceAlongSplineAtWorldLocation(Owner.ActorLocation);
		FVector SplineLocation = SplineSlideSpline.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector SplineToPlayer = Owner.ActorLocation - SplineLocation;

		// If the player is outside the width of the spline - return false
		FVector SplineRight = SplineSlideSpline.Spline.GetRightVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		float SplineWidth = SplineSlideSpline.GetWidthAtDistanceAlongSpline(DistanceAlongSpline);
		float RightDot = FMath::Abs(SplineToPlayer.DotProduct(SplineRight));

		return RightDot <= SplineWidth;
	}

	bool IsWithinSplineVerticalBounds(ASplineSlideSpline SplineSlideSpline) const
	{
		float DistanceAlongSpline = SplineSlideSpline.Spline.GetDistanceAlongSplineAtWorldLocation(Owner.ActorLocation);
		FVector SplineUp = SplineSlideSpline.Spline.GetUpVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector SplineLocation = SplineSlideSpline.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector SplineToPlayer = Owner.ActorLocation - SplineLocation;

		float VerticalHeight = SplineUp.DotProduct(SplineToPlayer);
		FSplineSlideSettings Settings = SplineSlideSpline.SplineSettings;

		if (SplineSlideSpline.bLimitActivationUpwards && VerticalHeight > SplineSlideSpline.UpwardsLimit)
			return false;
		
		if (SplineSlideSpline.bLimitActivationDownwards && VerticalHeight < -SplineSlideSpline.DownwardsLimit)
			return false;

		return true;
	}

	void UpdateJumpDestination(FVector CurrentLocation, FVector Velocity, float CurrentDistanceAlongActiveSpline)
	{
		if (ActiveSplineSlideSpline == nullptr)
		{
			JumpDestination = nullptr;
			return;
		}

		// Check if we'll land on current spline 
		float LandingFitness = BIG_NUMBER;
		float LandingDistAlongSpline = 0.f;
		FVector LandingLoc = FVector::ZeroVector;
		FSplineSlideSplineJumpDestination ActiveJumpDest;
		ActiveJumpDest.Spline = ActiveSplineSlideSpline;
		ActiveJumpDest.ExpectedEntryDistance = CurrentDistanceAlongActiveSpline;
		if (MightLandOnSpline(ActiveJumpDest, CurrentLocation, Velocity, LandingFitness, LandingDistAlongSpline, LandingLoc))
		{
			JumpDestination = ActiveSplineSlideSpline;
			JumpDestinationEstimatedLandingLocation = LandingLoc;
			JumpDistanceAlongSplines.Add(ActiveSplineSlideSpline, LandingDistAlongSpline);
			DebugDrawJumpDestination();
			return;		
		}

		// Check if we might land on a jump destination spline 
		ASplineSlideSpline BestDest = nullptr;
		FVector BestLandingLoc = FVector::ZeroVector;
		float BestFitness = BIG_NUMBER;
		for (FSplineSlideSplineJumpDestination JumpDest : ActiveSplineSlideSpline.JumpDestinations)
		{
			if (MightLandOnSpline(JumpDest, CurrentLocation, Velocity, LandingFitness, LandingDistAlongSpline, LandingLoc))
			{
				JumpDistanceAlongSplines.Add(JumpDest.Spline, LandingDistAlongSpline);
				if (LandingFitness < BestFitness)
				{
					BestFitness = LandingFitness;
					BestLandingLoc = LandingLoc;	
					BestDest = JumpDest.Spline;
				}
			}
		} 

		JumpDestination = BestDest;
		JumpDestinationEstimatedLandingLocation = BestLandingLoc;
		DebugDrawJumpDestination();
	}

	bool MightLandOnSpline(FSplineSlideSplineJumpDestination JumpDest, FVector Location, FVector Velocity, float& OutFitnessValue, float& OutDistAlongSpline, FVector& OutEstimatedLandingLocation) const
	{
		UHazeSplineComponent Spline = (JumpDest.Spline != nullptr) ? JumpDest.Spline.Spline : nullptr;
		if (Spline == nullptr)
			return false;

		// Use expected entry location to calculate height difference and estimate when player would land
		float EntryDist = JumpDest.ExpectedEntryDistance;

		// Use last valid jump distance along spline if possible, for better entry height estimation
		float LastValidJumpDist = EntryDist;
		if (JumpDistanceAlongSplines.Find(JumpDest.Spline, LastValidJumpDist) && (LastValidJumpDist > EntryDist))
			EntryDist = LastValidJumpDist;

		FVector EntryLoc = Spline.GetLocationAtDistanceAlongSpline(EntryDist, ESplineCoordinateSpace::World);

		// If we're too low we do not expect to land on spline at all. 
		// Assume gravity in world space for now!
		if (Location.Z + FMath::Max(0.f, Velocity.Z * 1.f) < EntryLoc.Z)
		{
			DebugDrawLandingLocation(EntryLoc, false, Spline, EntryDist, 5);
			return false;
		}

		// Estimate time (t) until we hit spline height (h1) from current height (h0) given 
		// initial velocity (v) and gravity magnitude (g)
		// t = (v/g) +- Sqrt((v/g)^2 + 2(h0 - h1)/g)
		float Gravity = ActiveSplineSlideSpline.SplineSettings.Jump.Gravity;
		float InverseGravity = 1.f / FMath::Max(0.1f, Gravity);
		float Discriminant = FMath::Square(Velocity.Z * InverseGravity) + (2.f * (Location.Z - EntryLoc.Z) * InverseGravity);
		if (Discriminant < 0)
		{
			DebugDrawLandingLocation(EntryLoc, false, Spline, EntryDist, 4);
			return false;
		}

		// Always assume we'll land on the way down (i.e. ignore lower solution)
		float LandTime = (Velocity.Z * InverseGravity) + FMath::Sqrt(Discriminant);
		if (LandTime > 2.f)
			LandTime = 2.f; // Never predict landing more than this time ahead
		FVector LandLoc = Location + Velocity * LandTime;
		LandLoc.Z  = EntryLoc.Z;

		// Check nearest spline distance, capped by jump destination settings to avoid unwanted locations from looping spline etc
		float DistanceAlongSpline = Spline.GetDistanceAlongSplineAtWorldLocation(LandLoc);
		if (DistanceAlongSpline > JumpDest.ExpectedEntryDistance + JumpDest.MaxDistancePastEntry)
			DistanceAlongSpline = JumpDest.ExpectedEntryDistance + JumpDest.MaxDistancePastEntry;

		// Check if behind or in front of spline
		FVector SplineForward = Spline.GetTangentAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World).GetSafeNormal();
		FVector SplineLocation = Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector SplineToLanding = LandLoc - SplineLocation;
		float ForwardDot = SplineToLanding.DotProduct(SplineForward);
		if ((DistanceAlongSpline == 0.f) && (ForwardDot < -JumpDest.LandingSlack))
		{
			DebugDrawLandingLocation(LandLoc, false, Spline, DistanceAlongSpline, 3);
			return false;
		}
		else if ((DistanceAlongSpline == Spline.SplineLength) && (ForwardDot > JumpDest.LandingSlack))
		{
			DebugDrawLandingLocation(LandLoc, false, Spline, DistanceAlongSpline, 2);
			return false;
		}

		// Check if within width of spline
		FVector SplineRight = Spline.GetRightVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		float SplineWidth = JumpDest.Spline.GetWidthAtDistanceAlongSpline(DistanceAlongSpline);
		float RightDot = FMath::Abs(SplineToLanding.DotProduct(SplineRight));
		if (RightDot > (SplineWidth + JumpDest.LandingSlack))
		{
			DebugDrawLandingLocation(LandLoc, false, Spline, DistanceAlongSpline, 1);
			return false;
		}

		// We can expect to land on spline!
		OutFitnessValue = (LandLoc - SplineLocation).SizeSquared();
		OutDistAlongSpline = DistanceAlongSpline;
		OutEstimatedLandingLocation = LandLoc;
		DebugDrawLandingLocation(LandLoc, true);
		return true;
	}

	ASplineSlideSpline GetValidSplineForActivation(UHazeMovementComponent MoveComp, bool bActivating)
	{
		if (!MoveComp.DownHit.bBlockingHit)
			return nullptr;

		for (ASplineSlideSpline SplineSlideSpline : NearbySplineSlideSplines)
		{
			if (!SplineSlideSpline.bEnabled)
				continue;

			if (IsWithinSplineBounds(SplineSlideSpline, bActivating))
				return SplineSlideSpline;
		}

		return nullptr;
	}

	void DebugDrawJumpDestination() 
	{
#if EDITOR
		//bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool && (JumpDestination != nullptr) && (JumpDistanceAlongSplines.Contains(JumpDestination)))
		{
			float DistAlongSpline = JumpDistanceAlongSplines[JumpDestination]; 
			FVector Loc = JumpDestination.Spline.GetLocationAtDistanceAlongSpline(DistAlongSpline, ESplineCoordinateSpace::World);
			System::DrawDebugSphere(Loc + FVector(100.f), 200.f, 4, FLinearColor::Yellow, 0.f, 20.f);
		}
#endif
	}

	void DebugDrawLandingLocation(FVector Loc, bool bSuccess, UHazeSplineComponent Spline = nullptr, float Dist = 0.f, int Marker = 0) const
	{
#if EDITOR
		if (bHazeEditorOnlyDebugBool)
		{
			FLinearColor Color = bSuccess ? FLinearColor::Green : FLinearColor::Red;
			System::DrawDebugLine(Owner.ActorLocation, Loc, Color, 0.f, 5.f);
			System::DrawDebugSphere(Loc + FVector(0,0,50), 50.f, 4, Color, 0.f, 5.f);
			if (Spline != nullptr)
				System::DrawDebugLine(Loc, Spline.GetLocationAtDistanceAlongSpline(Dist, ESplineCoordinateSpace::World), Color * 0.5f, 0.f, 1.f);
			for (int i = 0; i < Marker; i++)
			{
				System::DrawDebugLine(Loc + FVector(0,5,110 + i * 10), Loc + FVector(0,-5,110 + i * 10), Color, 0.f, 5.f);
			}
		}
#endif		
	}
}

struct FSplineSlideSplineData
{
	private UHazeSplineComponent Spline;
	private float DistanceAlongSpline = 0.f;
	private FVector WorldLocation;
	private FVector Forward;
	private FVector Right;
	private FVector Up;

	private void UpdateSplineData(UHazeSplineComponent _Spline, float _DistanceAlongSpline)
	{
		if (Spline == _Spline && DistanceAlongSpline == _DistanceAlongSpline)
			return;

		Spline = _Spline;
		WorldLocation = _Spline.GetLocationAtDistanceAlongSpline(_DistanceAlongSpline, ESplineCoordinateSpace::World);
		Forward = _Spline.GetTangentAtDistanceAlongSpline(_DistanceAlongSpline, ESplineCoordinateSpace::World).GetSafeNormal();
		Right = _Spline.GetRightVectorAtDistanceAlongSpline(_DistanceAlongSpline, ESplineCoordinateSpace::World);
		Up = _Spline.GetUpVectorAtDistanceAlongSpline(_DistanceAlongSpline, ESplineCoordinateSpace::World);
	}

	FVector GetSplineLocation(UHazeSplineComponent _Spline, float _DistanceAlongSpline)
	{
		UpdateSplineData(_Spline, _DistanceAlongSpline);
		return WorldLocation;
	}

	FVector GetSplineForward(UHazeSplineComponent _Spline, float _DistanceAlongSpline)
	{
		UpdateSplineData(_Spline, _DistanceAlongSpline);
		return Forward;
	}
}

class USplineSlideEventHandler : UObjectInWorld
{
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(BlueprintReadOnly)
	USplineSlideComponent SlidingComp;

	void InitInternal(USplineSlideComponent Owner)
	{
		SetWorldContext(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner.Owner);
		SlidingComp = Owner;

		BeginPlay();
	}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void BeginPlay() {}
	
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnTick(float DeltaTime) {}	
}