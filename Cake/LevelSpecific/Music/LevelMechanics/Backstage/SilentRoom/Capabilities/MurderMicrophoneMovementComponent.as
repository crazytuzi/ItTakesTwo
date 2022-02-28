import bool IsSnakeInsideChaseArea(AActor) from "Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophone";
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophoneSettings;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophoneTargetingComponent;

#if EDITOR
class UMurderMicrophoneMovementComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UMurderMicrophoneMovementComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		UMurderMicrophoneMovementComponent MoveComp = Cast<UMurderMicrophoneMovementComponent>(Component);

        if (!ensure((MoveComp != nullptr)))
			return;

		if(!MoveComp.bEnableVisualizer)
			return;

		if(!MoveComp.bConstrainWithinBoundingBox)
			return;

		DrawWireBox(MoveComp.ConstraintOriginWorldLocation, MoveComp.ConstrainBounds, FQuat::Identity, MoveComp.VisualizerColor, 5);
	}
}
#endif // EDITOR

struct FMurderMicrophoneMovementInfo
{
	FVector StartLocation;
	FVector FinalLocation;
	FVector DirectionToTarget;
}

class UMurderMicrophoneMovementComponent : UActorComponent
{
	UPROPERTY()
	bool bConstrainWithinBoundingBox = false;
	bool bWasWithinHeightLimit = false;

	float PitchLimitStart = 0.0f;

	default PrimaryComponentTick.bStartWithTickEnabled = true;

	private FBox _BoundingBox;
	FBox GetConstraintBoundingBox() const property { return _BoundingBox; }
	private USceneComponent _UpdatedComp = nullptr;
	private UMurderMicrophoneTargetingComponent _TargetingComp;

	private FQuat _TargetFacingRotation = FQuat::Identity;
	private FQuat _FacingRotationCurrent = FQuat::Identity;
	private FVector _TargetLocation = FVector::ZeroVector;
	private FVector _SnakeBaseOrigin = FVector::ZeroVector;
	
	private UMurderMicrophoneSettings Settings;
	private float _MovementVelocity = 0.0f;
	private float _RotationVelocity = 0.0f;
	private bool bFaceTargetLocation = true;

	USceneComponent GetUpdatedComponent() const property { return _UpdatedComp; }

	UPROPERTY(meta = (MakeEditWidget))
	FVector ConstraintOrigin = FVector::ZeroVector;
	UPROPERTY()
	FVector ConstrainBounds = FVector(1500.0f, 1500.0f, 1500.0f);
	FVector CachedBoxOrigin = FVector::ZeroVector;

	UPROPERTY(Category = Debug, meta = (EditCondition="bConstrainWithinBoundingBox == true", EditConditionHides))
	bool bEnableVisualizer = true;

	UPROPERTY(Category = Debug, meta = (EditCondition="bEnableVisualizer == true && bConstrainWithinBoundingBox == true", EditConditionHides))
	FLinearColor VisualizerColor = FLinearColor::Red;

	void SnapToFacingRotation(FRotator InFacingRotation) 
	{ 
		SetTargetFacingRotation(InFacingRotation);
		_FacingRotationCurrent = InFacingRotation.Quaternion();
	}

	void SnapToFacingRotation(FQuat InFacingRotation) 
	{ 
		SetTargetFacingRotation(InFacingRotation);
		_FacingRotationCurrent = InFacingRotation;
	}

	void SnapToFacingDirection(FVector InFacingDirection) 
	{ 
		SetTargetFacingDirection(InFacingDirection);
		_FacingRotationCurrent = InFacingDirection.ToOrientationQuat();
	}

	void SetFaceTargetLocation(bool bValue) { bFaceTargetLocation = bValue; }

	void SetTargetLocation(FVector InTargetLocation) 
	{ 
		_TargetLocation = InTargetLocation;
	}
	FVector GetTargetLocation() const property { return _TargetLocation; }

	FVector GetTargetFacingDirection() const property 
	{ 
		return _TargetFacingRotation.Vector();
	}
	
	FQuat GetTargetFacingRotation() const property 
	{ 
		return _TargetFacingRotation; 
	}

	FQuat GetFacingRotationCurrent() const property { return _FacingRotationCurrent; }
	FVector GetFacingDirectionCurrent() const property { return _FacingRotationCurrent.Vector(); }
	
	void SetTargetFacingRotation(FQuat InTargetFacingRotation) { _TargetFacingRotation = InTargetFacingRotation; }
	void SetTargetFacingRotation(FRotator InTargetFacingRotation) { _TargetFacingRotation = InTargetFacingRotation.Quaternion(); }
	void SetTargetFacingDirection(FVector InTargetFacingDirection) { _TargetFacingRotation = InTargetFacingDirection.ToOrientationQuat(); }

	void ResetMovementVelocity() { _MovementVelocity = 0.0f; }
	void ResetRotationVelocity() { _RotationVelocity = 0.0f; }

	AHazeActor HazeOwner;

	void Setup(USceneComponent InUpdatedComp, FVector SnakeBaseOrigin)
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		_UpdatedComp = InUpdatedComp;
		CachedBoxOrigin = ConstraintOriginWorldLocation;
		_BoundingBox = FBox(CachedBoxOrigin - ConstrainBounds, CachedBoxOrigin + ConstrainBounds);
		Settings = UMurderMicrophoneSettings::GetSettings(HazeOwner);
		_TargetingComp = UMurderMicrophoneTargetingComponent::Get(Owner);
		_SnakeBaseOrigin = SnakeBaseOrigin;
	}

	FVector GetConstraintOriginWorldLocation() const property
	{
		return Owner.ActorTransform.TransformPositionNoScale(ConstraintOrigin);
	}

	void DebugDrawBoundingBox() const
	{
		System::DrawDebugBox(_BoundingBox.Center, _BoundingBox.Extent, FLinearColor::Green, FRotator::ZeroRotator, 0, 10.0f);
	}

	void Move(float DeltaTime, FMurderMicrophoneMovementInfo& MovementInfo)
	{
		FVector LocationCurrent = _UpdatedComp.WorldLocation;
		MovementInfo.StartLocation = LocationCurrent;
		FVector DirectionToTarget = (_TargetLocation - LocationCurrent).GetSafeNormal();
		MovementInfo.DirectionToTarget = DirectionToTarget;
		
		_MovementVelocity += Settings.Acceleration * DeltaTime;
		_MovementVelocity *= FMath::Pow(Settings.Damping, DeltaTime);
		_MovementVelocity = FMath::Min(_MovementVelocity, Settings.MaxSpeed);

		const float DistSquared = _TargetLocation.DistSquared(LocationCurrent);
		const float DistanceScalar = FMath::Clamp((DistSquared - FMath::Square(Settings.SlowdownDistance.X)) / FMath::Square(Settings.SlowdownDistance.Y), 0.0f, 1.2f);

		FVector NewLocation = LocationCurrent + DirectionToTarget * (_MovementVelocity * DistanceScalar) * DeltaTime;

		MovementInfo.FinalLocation = NewLocation;
	}

	void ConstrainMovement(FMurderMicrophoneMovementInfo& MovementInfo)
	{
		// If this point is not inside the chase range, move it back into the chase range.
		if(!_TargetingComp.IsPointInsideChaseRange(MovementInfo.FinalLocation))
		{
			FVector LocationOnSphere = FVector::ZeroVector;
			float T = 0.0f;
			if(LineIntersectSphere(MovementInfo.FinalLocation, -MovementInfo.DirectionToTarget, T, LocationOnSphere))
			{
				MovementInfo.FinalLocation = LocationOnSphere;
			}
		}
		
		if(bConstrainWithinBoundingBox && !IsWithinBoundingBox(MovementInfo.FinalLocation))
		{
			FVector LocationOnBox = FVector::ZeroVector;
			FVector Min = _BoundingBox.Min;
			FVector Max = _BoundingBox.Max;

			LocationOnBox = _BoundingBox.GetClosestPointTo(MovementInfo.FinalLocation);
			MovementInfo.FinalLocation = LocationOnBox;
		}
	}

	bool IsWithinBoundingBox(FVector InLocation) const
	{
		return _BoundingBox.IsInside(InLocation);
	}

	void UpdateFacingRotation(float DeltaTime)
	{
		_RotationVelocity = FMath::FInterpTo(_RotationVelocity, Settings.RotationSpeed, DeltaTime, 1.0f);

		if(bConstrainWithinBoundingBox)
		{
			const float HeightCurrent = _UpdatedComp.WorldLocation.Z;
			FVector Center, Extents;
			_BoundingBox.GetCenterAndExtents(Center, Extents);
			const float BottomLimit = (Center - FVector(0, 0, Extents.Z)).Z;
			const float TopLimit = (Center + FVector(0, 0, Extents.Z)).Z;
			const float HeightDiffBottom = FMath::Max(HeightCurrent - BottomLimit, 0.0f);
			const float HeightDiffTop = FMath::Max(TopLimit - HeightCurrent, 0.0f);
			float HeightDiff = 0.0f;

			bool bIsWithinHeightLimit = false;

			const float HeightLimitLength = 250.0f;
			if(HeightDiffBottom < HeightLimitLength)
			{
				bIsWithinHeightLimit = true;
				HeightDiff = HeightDiffBottom;
			}
			else if(HeightDiffTop < HeightLimitLength)
			{
				bIsWithinHeightLimit = true;
				HeightDiff = HeightDiffTop;
			}

			if(bIsWithinHeightLimit)
			{
				if(!bWasWithinHeightLimit)
					PitchLimitStart = _FacingRotationCurrent.Rotator().Pitch;

				float HeightFraction = HeightDiff / HeightLimitLength;
				float TargetPitch = FMath::Lerp(0.0f, PitchLimitStart, HeightFraction);
				FRotator Rot = _TargetFacingRotation.Rotator();
				Rot.Pitch = TargetPitch;
				_TargetFacingRotation = Rot.Quaternion();
			}

			bWasWithinHeightLimit = bIsWithinHeightLimit;
		}

		_FacingRotationCurrent = FQuat::Slerp(_FacingRotationCurrent, _TargetFacingRotation, DeltaTime * _RotationVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const FVector CodyLoc = Game::Cody.ActorCenterLocation;
		const FVector MayLoc = Game::May.ActorCenterLocation + FVector(0, 0, 6600);
		FVector DirectionToMay = (MayLoc - CodyLoc).GetSafeNormal();
		FVector Hit;
		float T = 0.0f;
		//bool bIntersects = LineIntersectSphere(CodyLoc, DirectionToMay, T,  Hit);
		//PrintToScreen("bIntersects " + bIntersects);
		//System::DrawDebugPoint(Hit, 10, FLinearColor::Blue);
	}

	bool LineIntersectSphere(FVector P, FVector D, float& T, FVector& Hit)
	{
		FVector M = P - _SnakeBaseOrigin;
		float B = M.DotProduct(D);
		float C = M.DotProduct(M) - _TargetingComp.ChaseRangeSq;

		if(C > 0.0f && B > 0.0f)
			return false;

		float Discr = FMath::Square(B) - C;

		if(Discr < 0.0f)
			return false;

		T = -B - FMath::Sqrt(Discr);
		
		if(T < 0.0f)
			T = 0.0f;

		Hit = P + D * T;

		return true;
	}
}
