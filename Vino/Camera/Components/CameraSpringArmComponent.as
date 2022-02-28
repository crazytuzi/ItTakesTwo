import Vino.Camera.Components.CameraUserComponent;
import Peanuts.Containers.BlendedCurvesContainer;
import Vino.Camera.Components.CameraLerp;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Components.CameraAssetsComponent;

#if TEST
const FConsoleVariable CVar_SpringArmCollisionTest("Haze.SpringArmCollisionTest", 0);
const FConsoleVariable CVar_SpringArmForceIdealDistance("Haze.SpringArmForceIdealDistance", 0);
const FConsoleVariable CVar_SpringArmForceMinTraceBlockedRange("Haze.SpringArmForceMinTraceBlockedRange", 0);
const FConsoleVariable CVar_SpringArmTestAlwaysBlockerSingleTrace("Haze.SpringArmTestAlwaysBlockerSingleTrace", 0);
#endif

const FConsoleVariable CVar_SpringArmUsePrediction("Haze.SpringArmUsePrediction", 0);

delegate FRotator FGetSpringArmFinalWorldRotation(FRotator From, FRotator To, float DeltaTime, float Speed);

struct FSpringArmObstruction
{
	FVector Front = FVector(BIG_NUMBER);
	FVector Back = FVector(BIG_NUMBER);
	FSpringArmObstruction(const FVector& Location)
	{
		Front = Location;
	}
}

class UCameraSpringArmComponent : UHazeCameraParentComponent
{
	default bWantsCameraInput = true;

	UPROPERTY()
	FHazeCameraSpringArmSettings OverrideSettings;

	UPROPERTY()
	float RotationSpeed = 3600.f;

	// When obstructed, camera needs to be at least this far away from the other side of the obstruction 
	// or it will be moved to the near side of the obstruction. 
	UPROPERTY()
	float ObstructedClearance = 64.0f;

	// If != 0, we set pivot velocity to this velocity in owner space
	UPROPERTY()
	FVector StartPivotVelocity = FVector::ZeroVector;

	UCurveFloat LagSpeedCurve = nullptr;

	AHazePlayerCharacter PlayerUser = nullptr;
	UCameraUserComponent User = nullptr;
	FVector PreviousPivotLocation;
	FVector PreviousCameraLocation;
	FRotator PreviousWorldRotation;
	float RotationDuration = 0.f;
	float TraceBlockedTime = 0.f;
	FHazeAcceleratedFloat TraceBlockedRange;
	FHazeAcceleratedFloat TraceBlockedExtensionAccelerationFactor;	
	FVector WorldPivotOffset;
	float WorldPivotOffsetResetSpeed = 0.f;
	float CurrentArmLength = 0;
	FHazeAcceleratedVector PivotSpeed;
	FHazeAcceleratedVector MaxPivotLag;
	FVector AccPivotWorldVelocity;
	FHazeAcceleratedRotator PivotOwnerRotation; 
	FBlendedCurvesContainer IdealDistanceByPitchCurves;
	default IdealDistanceByPitchCurves.DefaultValue = 1.f;
	FBlendedCurvesContainer PivotHeightByPitchCurves;
	default PivotHeightByPitchCurves.DefaultValue = 0.f;
	FBlendedCurvesContainer CameraOffsetByPitchCurves;
	default CameraOffsetByPitchCurves.DefaultValue = 1.f;
	FBlendedCurvesContainer CameraOffsetOwnerSpaceByPitchCurves;
	default CameraOffsetOwnerSpaceByPitchCurves.DefaultValue = 1.f;
	UHazeMovementComponent MoveComp = nullptr; 
	float PrevDeltaTime = 0.f;
	FHazeAcceleratedVector InheritedGroundVelocity;
	bool bGroundMoved = false;

	FGetSpringArmFinalWorldRotation OnGetSpringArmFinalWorldRotation;

	bool bClearPredictions = false;
	FVector PredictedCameraLocation;
	FVector PredictedPivotLocation;
	TArray<FHitResult> PredictedObstructions;
	TArray<FHitResult> PredictedReturnObstructions;

#if TEST
	float TestBlockedRangeFraction = 1.f;
	bool bDebugDrawPrediction = false;
#endif

	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent _User, EHazeCameraState PreviousState)
	{
		PlayerUser = Cast<AHazePlayerCharacter>(_User.GetOwner());
		User = Cast<UCameraUserComponent>(_User);
		MoveComp = UHazeMovementComponent::Get(GetOwner());

		if (LagSpeedCurve == nullptr)
		{
			UCameraAssetsComponent AssetsComp = UCameraAssetsComponent::Get(User.GetOwner());
			LagSpeedCurve = AssetsComp.SpringArmLagSpeedCurve;
		}

		if (PreviousState == EHazeCameraState::Inactive)
		{
			// Camera was not previously blending out or active, reset transients.
			if(MoveComp != nullptr)
			{
				MoveComp.OnBasePlatformMoved.AddUFunction(this, n"OnGroundMoved");
				MoveComp.OnJumpActivated.AddUFunction(this, n"OnUserJumped");
			}

			Snap();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraFinishedBlendingOut(UHazeCameraUserComponent _User, EHazeCameraState PreviousState)
	{
		if(MoveComp != nullptr)
		{
			MoveComp.OnBasePlatformMoved.Unbind(this, n"OnGroundMoved");
			MoveComp.OnJumpActivated.Unbind(this, n"OnUserJumped");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Update(float DeltaTime)
	{
		if ((Camera == nullptr) || (User == nullptr) || (PlayerUser == nullptr))
			return;

		FHazeCameraSpringArmSettings Settings;
		GetSettings(Settings);
		UpdateInternal(DeltaTime, Settings);
	}

	void UpdateInternal(float DeltaTime, const FHazeCameraSpringArmSettings& Settings)
	{
		float TimeDilation = Owner.GetActorTimeDilation();
		float UndilutedDeltaTime = (TimeDilation > 0.f) ? DeltaTime / TimeDilation : 1.f;
		
		UpdateWorldPivotOffset(DeltaTime);
		UpdateRotation(UndilutedDeltaTime, Settings);
		UpdateIdealDistanceByPitchCurve(DeltaTime, Settings);
		UpdatePivotHeightByPitchCurve(DeltaTime, Settings);
		UpdateCameraOffsetByPitchCurve(DeltaTime, Settings);
		UpdateCameraOffsetOwnerSpaceByPitchCurve(DeltaTime, Settings);
		UpdateLocation(DeltaTime, UndilutedDeltaTime, Settings);

		PrevDeltaTime = DeltaTime;
	}

	void GetSettings(FHazeCameraSpringArmSettings& OutSettings)
	{
		// Get user settings
		User.GetCameraSpringArmSettings(OutSettings);

		// Own settings may override in turn
		OutSettings.Override(OverrideSettings);
	}

	void UpdateRotation(float DeltaTime, const FHazeCameraSpringArmSettings& Settings)
	{
		float RotSpeed = RotationSpeed; 
		if (!PlayerUser.IsUsingGamepad())
			RotSpeed *= 10.f;
		
		FRotator NewRot;
		if(OnGetSpringArmFinalWorldRotation.IsBound())
			NewRot = OnGetSpringArmFinalWorldRotation.Execute(PreviousWorldRotation, User.GetDesiredRotation(), DeltaTime, RotSpeed);
		else
			NewRot = GetFinalWorldRotation(PreviousWorldRotation, User.GetDesiredRotation(), DeltaTime, RotSpeed);
	
		RotationDuration += DeltaTime;
		if (PreviousWorldRotation.Equals(NewRot, 0.1f))
			RotationDuration = 0.f;
		
		SetWorldRotation(NewRot);
		PreviousWorldRotation = NewRot;	
	}

	FRotator GetFinalWorldRotation(FRotator From, FRotator To, float DeltaTime, float Speed)
	{
		// Substepping to reduce twitchyness
		FRotator Rot = From;
		const float SubStepDuration = 0.004167; // 240 fps
		float SubsteppedTime = 0.f;
		for (; SubsteppedTime < DeltaTime - SubStepDuration; SubsteppedTime += SubStepDuration)
		{
			Rot = FMath::RInterpTo(Rot, To, SubStepDuration, Speed);
		} 
		if (DeltaTime - SubsteppedTime > 0.f)
			Rot = FMath::RInterpTo(Rot, To, DeltaTime - SubsteppedTime, Speed);
		return Rot;
	}

	float GetIdealDistance(const FHazeCameraSpringArmSettings& Settings)
	{
		const float LocalPitch = User.WorldToLocalRotation(GetWorldRotation()).Pitch;
		float IdealDist = Settings.IdealDistance;
		IdealDist *= IdealDistanceByPitchCurves.GetFloatValue(LocalPitch);
		IdealDist -= Settings.CameraOffset.X * CameraOffsetByPitchCurves.GetFloatValue(LocalPitch);
		if (IdealDist < Settings.MinDistance)
			IdealDist = Settings.MinDistance;
#if TEST
		float ForceIdealDistance = CVar_SpringArmForceIdealDistance.Float;
		if (ForceIdealDistance > 1.f)
			return ForceIdealDistance;
#endif
		return IdealDist;
	}

	void UpdateLocation(float DeltaTime, float UndilutedDeltaTime, const FHazeCameraSpringArmSettings& Settings)
	{
		FVector TargetPivotLoc = GetTargetPivotLocation(Settings);
		FVector PivotLoc = GetUpdatedPivotLocation(DeltaTime, TargetPivotLoc, Settings);

		const float LocalPitch = User.WorldToLocalRotation(GetWorldRotation()).Pitch;
		FVector OwnerSpaceOffset = User.LocalToWorldRotation(PivotOwnerRotation.Value).RotateVector(Settings.CameraOffsetOwnerSpace);
		OwnerSpaceOffset *= CameraOffsetOwnerSpaceByPitchCurves.GetFloatValue(LocalPitch);

		FVector CameraOffset = GetWorldRotation().RotateVector(FVector(0.f, Settings.CameraOffset.Y, Settings.CameraOffset.Z));
		CameraOffset *= CameraOffsetByPitchCurves.GetFloatValue(LocalPitch);

		float IdealDistance = GetIdealDistance(Settings);

		// Offset camera location from lagged pivot with ideal distance and settings camera offsets
		FVector ForwardDir = GetForwardVector();
		FVector ArmEndLoc = PivotLoc - ForwardDir * IdealDistance;
		FVector TargetCameraLoc = ArmEndLoc + CameraOffset + OwnerSpaceOffset;

		// Offset pivot by factor of camera offset for tracing purposes (note that camera offset in owner space should shrink to zero when fully obstructed, so will not be applied)
		FVector CameraStartOffset  = CameraOffset * Settings.CameraOffsetBlockedFactor;
		FVector OffsetPivotLoc = PivotLoc + CameraStartOffset; 
		FVector TraceStartLoc = TargetPivotLoc + CameraStartOffset;

		// Clamp camera location to within trace blocked range from pivot
		UpdateTraceBlockedExtension(UndilutedDeltaTime, Settings, OffsetPivotLoc, TargetCameraLoc);
		UpdatePredictedTraceBlockage(PivotLoc, TargetCameraLoc, DeltaTime);
		FVector CameraLoc = TargetCameraLoc;
		if (!PivotLoc.IsNear(TargetCameraLoc, TraceBlockedRange.Value))
			CameraLoc = OffsetPivotLoc + (TargetCameraLoc - OffsetPivotLoc).GetSafeNormal() * TraceBlockedRange.Value;

		// Don't check collision within min distance
		FVector MinOffset = FVector::ZeroVector;
		if (Settings.MinDistance > 0.f)
			MinOffset = (TargetCameraLoc - TraceStartLoc).GetSafeNormal() * Settings.MinDistance;

		// Check collision towards the target pivot location so we won't clip ground with lagging pivot.
		// Note that this will cause lag to lessen when obstructed.
        // TODO: When camera is blocked you might get some twitchyness, since blocked range needs to be tweaked accordingly. Fix!	
		FHitResult Obstruction;
		if (CheckCameraCollision(TraceStartLoc + MinOffset, CameraLoc, Obstruction))
		{
			CameraLoc = Obstruction.Location;
			float BlockedRange = (OffsetPivotLoc - Obstruction.Location).Size();
			SetTraceBlockedRange(BlockedRange);
			if (User.ShouldDebugDisplay(ECameraDebugDisplayType::Collision)) System::DrawDebugPoint(Obstruction.Location, 10, FLinearColor::Green);		
		}

		// Place any children (usually a camera comp) at camera location
		TArray<USceneComponent> Children; 
		GetChildrenComponents(false, Children);
		for (USceneComponent Child : Children)
		{
			Child.SetWorldLocation(CameraLoc);
		}
		
		// Set up prediction for next frame
		PreparePredictedTraceBlockage(PivotLoc, CameraLoc, WorldRotation, OwnerSpaceOffset, CameraOffset - FVector(IdealDistance, 0.f, 0.f));

		PreviousPivotLocation = PivotLoc;
		PreviousCameraLocation = CameraLoc;
		CurrentArmLength = FMath::Min(IdealDistance, TraceBlockedRange.Value); // This is not correct, remove usage in wallwalkinganimal or fix!		
	}

	float GetSpringArmLength()const
	{
		return CurrentArmLength;
	}

	void DrawCameraCollisionBlockage(const FVector& Location, const FVector& From)
	{
		FVector Direction = (Location - From).GetSafeNormal();
		System::DrawDebugPoint(Location, 5, FLinearColor::Red);		
		System::DrawDebugArrow(Location - (Direction * 5), Location, 20.f, FLinearColor::Red, 0.f, 3.f);		
	}

	bool CheckCameraCollision(const FVector& StartLocation, const FVector& EndLocation, FHitResult& OutObstruction)
	{
#if TEST
		if (CVar_SpringArmCollisionTest.Int == 1)
			return CheckCameraCollisionBaseLine(StartLocation, EndLocation, OutObstruction);
		if (CVar_SpringArmCollisionTest.Int == 2)
			return CheckCameraCollisionTrace(StartLocation, EndLocation, OutObstruction);
		if (CVar_SpringArmCollisionTest.Int == 3)
			return false; // Never trace
		if (CVar_SpringArmCollisionTest.Int == 4)
			return CheckCameraCollisionMultiTrace(StartLocation, EndLocation, OutObstruction);
#endif

		return CheckCameraCollisionSweep(StartLocation, EndLocation, OutObstruction);
	}

	bool CheckCameraCollisionSweep(const FVector& StartLocation, const FVector& EndLocation, FHitResult& OutObstruction)
	{
		float ScaledObstructedClearance = ObstructedClearance * PlayerUser.ActorScale3D.Z;
		bool bDrawDebugTraces = User.ShouldDebugDisplay(ECameraDebugDisplayType::Collision);

		if (bDrawDebugTraces) System::DrawDebugLine(StartLocation, EndLocation, FLinearColor::Green, 0, 1);
		FHitResult FirstObstruction;
		if (!Camera::CheckCameraCollision(Camera, StartLocation, EndLocation, FirstObstruction))
		{
			// No obstructions at all!
			return false;
		}

		if (bDrawDebugTraces) DrawCameraCollisionBlockage(FirstObstruction.Location, StartLocation);
				
		bool bCheckTunneling = false; // This may not be that useful as we have floor collision adn once we have prediction. Remove if we need to optimize.
		if (bCheckTunneling)
		{
			// If there are any obstructions in between previous camera location and current, we always count first obstruction as hard blocking
			FHitResult TunnelingObstruction;
			if (Camera::CheckCameraCollision(Camera, PreviousCameraLocation, EndLocation, TunnelingObstruction))
			{
				OutObstruction = FirstObstruction;
				return true;
			}
		}

		FVector FinalEndLocation = FindAlwaysBlockingObstructions(FirstObstruction, EndLocation);
		if (FinalEndLocation.DistSquared(FirstObstruction.Location) < FMath::Square(ScaledObstructedClearance))
		{
			// Hard blocking obstruction found too close to first obstruction
			OutObstruction = FirstObstruction;
			return true;
		}

		// Obstructed, check if there is sufficient room on the other side of obstruction to keep camera there 
		// Note that Trace::SphereTraceMultiAllHitsByChannel won't be enough with concave components, as it only finds the first hit (this is especially true with world bsp).
		FHitResult ReturnObstruction;
		if (!Camera::CheckCameraCollision(Camera, FinalEndLocation, FirstObstruction.Location, ReturnObstruction))
		{
			// Could not find back side of initial obstruction, assume we're inside something which doesn't block camera from behind.
			if (bDrawDebugTraces) System::DrawDebugLine(FinalEndLocation, FirstObstruction.Location, FLinearColor::Red, 0, 2);
			OutObstruction = FirstObstruction;
			return true;
		}

		if (bDrawDebugTraces) DrawCameraCollisionBlockage(ReturnObstruction.Location, FinalEndLocation);		
		if (ReturnObstruction.Distance > ScaledObstructedClearance)
		{
			// We have enough space behind last obstrucion, count as unblocked.
			OutObstruction.Location = FinalEndLocation;
			return false;
		}

		// Trying to find gaps in between obstructions is expensive and bug prone, but will give a slightly nicer feel. 
		// Let's keep it around as an option to test if camera feels to snappy in some places.
		bool bCheckInterveningSpaces = false;
		if (bCheckInterveningSpaces)
		{
			// End location is too near an obstruction, we try to find a gap in behind first obstruction by incremental steps
			// A binary search would probably require more traces normally, except for when camera is squeezed in between some 
			// large obstructions. Or when teleported to such a location.
			FVector PrevTestLoc = ReturnObstruction.Location;
			FVector TraceDir = (PrevTestLoc - FirstObstruction.Location);
			float TestDistance = TraceDir.Size();
			TraceDir /= TestDistance; // Normalize
			TestDistance -= ScaledObstructedClearance;
			float StepLength = FMath::Max(ScaledObstructedClearance, TestDistance * 0.1f); // In case clearance is small, accept that we might not find every valid gap.
			while (TestDistance > ScaledObstructedClearance)
			{
				FVector TestLoc = FirstObstruction.Location + (TraceDir * TestDistance);
				if (bDrawDebugTraces) System::DrawDebugLine(TestLoc, TestLoc + FVector(0,0,20), FLinearColor::Yellow, 0, 1);		
				if (!Camera::CheckCameraCollision(Camera, TestLoc, FirstObstruction.Location, ReturnObstruction))
				{
					// We've stepped into a block which doesn't block camera from behind.
					OutObstruction = FirstObstruction;
					if (bDrawDebugTraces) System::DrawDebugLine(TestLoc, FirstObstruction.Location, FLinearColor::Red, 0, 2);
					return true;
				}

				if (bDrawDebugTraces) DrawCameraCollisionBlockage(ReturnObstruction.Location, TestLoc);		
				if (ReturnObstruction.Distance > 0.f)
				{
					// Found an obstruction which might have enough space behind it. Probe forwards to find furthest side of gap.
					FHitResult ForwardObstruction;
					if (Camera::CheckCameraCollision(Camera, TestLoc, PrevTestLoc, ForwardObstruction))
					{
						if (ForwardObstruction.Distance + ReturnObstruction.Distance > ScaledObstructedClearance)
						{
							// Found a big enough gap!
							OutObstruction = ForwardObstruction;
							return true;
						}
					}
				}

				// No gap, or not enough space, step backwards and try again.
				TestDistance -= StepLength;
				PrevTestLoc = TestLoc;
			}
		}

		// Could not find a big enough gap
		OutObstruction = FirstObstruction;
		return true;
	}

	// Return the location of the first obstruction which will not allow camera to pass behind it
	FVector FindAlwaysBlockingObstructions(const FHitResult& FirstObstruction, const FVector& EndLocation)
	{
		if (IsAlwaysBlockingObstruction(FirstObstruction))
			return FirstObstruction.Location;

		// Test if it's cheaper to do several single traces, ignoring found soft obstructions as we go.
#if TEST
		if (CVar_SpringArmTestAlwaysBlockerSingleTrace.Int == 1)
		{
			// We do several single traces, ignoring found soft obstructions as we go. Investigate if it's cheaper with a single multi trace
			TArray<AActor> IgnoredActors;
			if (Camera.CameraCollisionParams.bIgnoreOwner)
				IgnoredActors.AddUnique(GetOwner());
			if (Camera.CameraCollisionParams.bIgnoreUser)
				IgnoredActors.AddUnique(PlayerUser);
			IgnoredActors.Add(FirstObstruction.Actor);
			FHitResult Obstruction;
			Obstruction.Location = FirstObstruction.Location; 
			float ProbeSizeSqr = FMath::Square(Camera.CameraCollisionParams.ProbeSize);
			while (Obstruction.Location.DistSquared(EndLocation) > ProbeSizeSqr)
			{
				if (!System::LineTraceSingle(Obstruction.Location, EndLocation, ETraceTypeQuery::Camera, false, IgnoredActors, EDrawDebugTrace::None, Obstruction, true))
				{
					// No further obstructions
					return EndLocation;		
				}
				if (IsAlwaysBlockingObstruction(Obstruction))
				{
					// Found a hard obstruction
					return Obstruction.Location;
				}
				// Found a soft obstruction, ignore it.
				IgnoredActors.Add(Obstruction.Actor);
			}
			return EndLocation;
		}
#endif
		TArray<FHitResult> Obstructions;		
		TArray<AActor> IgnoredActors;
		if (Camera.CameraCollisionParams.bIgnoreOwner)
			IgnoredActors.AddUnique(GetOwner());
		if (Camera.CameraCollisionParams.bIgnoreUser)
			IgnoredActors.AddUnique(PlayerUser);
		IgnoredActors.Add(FirstObstruction.Actor);
		Trace::LineTraceMultiAllHitsByChannel(FirstObstruction.Location, EndLocation, ETraceTypeQuery::Camera, false, IgnoredActors, Obstructions);
		for (FHitResult Obstruction : Obstructions)
		{
			if (IsAlwaysBlockingObstruction(Obstruction))
			{
				// Results are sorted, so this is the closest hard obstruction
				return Obstruction.Location;
			}
		}
		return EndLocation;
	}

	bool IsAlwaysBlockingObstruction(const FHitResult& Obstruction)
	{
		// Only camera blockers can obstruct
		if (!Obstruction.bBlockingHit)
			return false;

		// Components with the always blocking tag will obviously do that
		if ((Obstruction.Component != nullptr) && Obstruction.Component.HasTag(ComponentTags::AlwaysBlockCamera))
			return true;

		// BSP always obscruct
		if (Obstruction.Actor == nullptr)
			return true;

		// Any obstructions below player (in camera space) will count as always blocking, so we don't end up on the wrong side of the floor.
		FVector ToObstruction = Obstruction.Location - (PlayerUser.ActorLocation + Camera.CameraCollisionParams.ProbeSize + 1.f);
		if (User.YawAxis.DotProduct(ToObstruction) < 0.f)
			return true;

		return false;
	}

	bool CheckCameraCollisionBaseLine(const FVector& StartLocation, const FVector& EndLocation, FHitResult& OutObstruction)
	{
		// Just trace from start to end, count any obstructions as always blocking
		return CameraCollisionTrace(StartLocation, EndLocation, OutObstruction);
	}

	bool CheckCameraCollisionMultiTrace(const FVector& StartLocation, const FVector& EndLocation, FHitResult& OutObstruction)
	{
		// Multitrace from start to end and back again if there are obstructions.
		TArray<FHitResult> Obstructions;
		CameraCollisionMultiTrace(StartLocation, EndLocation, Obstructions);

		// Remove any overlaps
		for (int i = Obstructions.Num() - 1; i >= 0; i--)
		{
			if (!Obstructions[i].bBlockingHit)
			 	Obstructions.RemoveAt(i);
		}
		if (Obstructions.Num() == 0)
			return false; // No obstructions!

		// We'll trace backwards from the first always blocking obstruction (or end if there are none) 
		// to find a gap we're there's enough space to place the camera behind an obstruction.
		int iBlocker = 0;
		FVector ReturnLoc = EndLocation;
		for (; iBlocker < Obstructions.Num(); iBlocker++)
		{
			if (!IsAlwaysBlockingObstruction(Obstructions[iBlocker]))
				continue;
			ReturnLoc = Obstructions[iBlocker].Location;
			break;
		}

		// We need to be at least this far away from an obstruction to consider staying on the other side of it.
		float ScaledObstructedClearance = ObstructedClearance * PlayerUser.ActorScale3D.Z;
		for (; iBlocker >= 1; iBlocker--)
		{
			if (!ReturnLoc.IsNear(Obstructions[iBlocker - 1].Location, ScaledObstructedClearance))
				break;
			// Skip past any obstructions which are too near the return point or previous obstruction
			ReturnLoc = Obstructions[iBlocker -1].Location;
		}

		if (iBlocker == 0)
		{
			// First obstruction was blocking, or there was insuffcient space behind it
			OutObstruction = Obstructions[0];
			return true;
		}

		// Just do multi trace backwards to check what performance cost this would entail
		// TODO: Fix properly if this looks promising
		TArray<FHitResult> ReturnObstructions;
		CameraCollisionMultiTrace(ReturnLoc, Obstructions[0].Location, ReturnObstructions);
		OutObstruction = Obstructions[0];
		return true;
	}

	bool CameraCollisionTrace(const FVector& StartLocation, const FVector& EndLocation, FHitResult& OutObstruction)
	{
		TArray<AActor> IgnoreActors = Camera.CameraCollisionParams.AdditionalIgnoreActors;
		IgnoreActors.Add(Owner);
		return System::LineTraceSingle(StartLocation, EndLocation, ETraceTypeQuery::Camera, false, IgnoreActors, EDrawDebugTrace::None, OutObstruction, true);		
	}

	bool CameraCollisionMultiTrace(const FVector& StartLocation, const FVector& EndLocation, TArray<FHitResult>& OutObstructions)
	{
		TArray<AActor> IgnoreActors = Camera.CameraCollisionParams.AdditionalIgnoreActors;
		IgnoreActors.Add(Owner);
		return Trace::LineTraceMultiAllHitsByChannel(StartLocation, EndLocation, ETraceTypeQuery::Camera, false, IgnoreActors, OutObstructions);		
	}

	bool CheckCameraCollisionTrace(const FVector& StartLocation, const FVector& EndLocation, FHitResult& OutObstruction)
	{
		float ScaledObstructedClearance = ObstructedClearance * PlayerUser.ActorScale3D.Z;
		bool bDrawDebugTraces = User.ShouldDebugDisplay(ECameraDebugDisplayType::Collision);

		if (bDrawDebugTraces) System::DrawDebugLine(StartLocation, EndLocation, FLinearColor::Green, 0, 1);
		FHitResult FirstObstruction;
		if (!CameraCollisionTrace(StartLocation, EndLocation, FirstObstruction))
		{
			// No obstructions at all!
			return false;
		}

		if (bDrawDebugTraces) DrawCameraCollisionBlockage(FirstObstruction.Location, StartLocation);
				
		FVector FinalEndLocation = FindAlwaysBlockingObstructions(FirstObstruction, EndLocation);
		if (FinalEndLocation.DistSquared(FirstObstruction.Location) < FMath::Square(ScaledObstructedClearance))
		{
			// Hard blocking obstruction found too close to first obstruction
			OutObstruction = FirstObstruction;
			return true;
		}

		// Obstructed, check if there is sufficient room on the other side of obstruction to keep camera there 
		// Note that Trace::SphereTraceMultiAllHitsByChannel won't be enough with concave components, as it only finds the first hit (this is especially true with world bsp).
		FHitResult ReturnObstruction;
		if (!CameraCollisionTrace(FinalEndLocation, FirstObstruction.Location, ReturnObstruction))
		{
			// Could not find back side of initial obstruction, assume we're inside something which doesn't block camera from behind.
			if (bDrawDebugTraces) System::DrawDebugLine(FinalEndLocation, FirstObstruction.Location, FLinearColor::Red, 0, 2);
			OutObstruction = FirstObstruction;
			return true;
		}

		// We only check if there's room at the far end, checking every gap in between is expensive and usually not worth it.
		if (bDrawDebugTraces) DrawCameraCollisionBlockage(ReturnObstruction.Location, FinalEndLocation);		
		if (ReturnObstruction.Distance > ScaledObstructedClearance)
		{
			// We have enough space behind last obstrucion, count as unblocked.
			OutObstruction.Location = FinalEndLocation;
			return false;
		}

		// Could not find a big enough gap
		OutObstruction = FirstObstruction;
		return true;
	}

	FVector GetTargetPivotLocation(const FHazeCameraSpringArmSettings& Settings)
	{
		USceneComponent Parent = GetAttachParent();
		if (Parent == nullptr)
			Parent = GetOwner().GetRootComponent();
		
		const float LocalPitch = User.WorldToLocalRotation(GetWorldRotation()).Pitch;
		const float PivotBonusHeight = PivotHeightByPitchCurves.GetFloatValue(LocalPitch);
		FVector TotalPivotOffset = RelativeLocation + Settings.PivotOffset + FVector(0.f, 0.f, PivotBonusHeight);
		return Parent.GetWorldLocation() + Parent.GetWorldRotation().RotateVector(TotalPivotOffset) + WorldPivotOffset + Settings.WorldPivotOffset;
	}

	float UpdatePivotAxis(float Target, float Previous, float DeltaTime, float LagSpeed, float& InOutVelocity)
	{
		// Settings lag speed is in the range 0..1, where 0 is no pivot movement and 1 is no lag. 
		float NewLoc = Previous;
		if (LagSpeed > 0.99f)
		{
			InOutVelocity = 0.f;
			return Target;
		}

		if (LagSpeed > 0.f)
		{
			// In between 0..1 we accelerate pivot and determinate acc duration from lag speed
			float AccDuration = LagSpeedCurve.GetFloatValue(LagSpeed);
			FHazeAcceleratedFloat AccPivotLoc;
			AccPivotLoc.SnapTo(Previous, InOutVelocity);
			NewLoc = AccPivotLoc.AccelerateTo(Target, AccDuration, DeltaTime);
			InOutVelocity = AccPivotLoc.Velocity;
		}
		else
		{
			// 0 lag speed
			InOutVelocity = 0.f;
		}

		return NewLoc;
	}

	UFUNCTION()
	void OnUserJumped(FVector InheritedHorizontal, FVector InheritedVertical)
	{
		// Set inherited velocity from regular jumps, but not air jumps
		if (!PlayerUser.IsAnyCapabilityActive(n"AirJump") || PlayerUser.IsAnyCapabilityActive(n"AirJumpReset"))
			InheritedGroundVelocity.SnapTo(InheritedHorizontal + InheritedVertical);
	}

	UFUNCTION()
	void OnGroundMoved(FVector Delta, UPrimitiveComponent GroundComp)
	{
		bGroundMoved = true;
		if (PlayerUser == nullptr)
			return;

		if(MoveComp == nullptr)
			return;

		FHazeCameraSpringArmSettings Settings;
		GetSettings(Settings);
		PreviousPivotLocation += GetApplicableKeepUpWithMovingGroundDelta(Delta, Settings);
	}

	FVector GetApplicableKeepUpWithMovingGroundDelta(const FVector& Delta, const FHazeCameraSpringArmSettings& Settings)
	{
		if (!Settings.bKeepupWithMovingGroundHorizontal && !Settings.bKeepupWithMovingGroundVertical)
			return FVector::ZeroVector;

		if (Settings.bKeepupWithMovingGroundHorizontal && Settings.bKeepupWithMovingGroundVertical)
			return Delta;

		FVector VerticalDelta;
		FVector HorizontalDelta;
		Math::DecomposeVector(VerticalDelta, HorizontalDelta, Delta, MoveComp.WorldUp);
		if (Settings.bKeepupWithMovingGroundVertical)
			return VerticalDelta;
		else
			return HorizontalDelta;
	}

	FVector GetUpdatedPivotLocation(float DeltaTime, const FVector& TargetPivotLoc, const FHazeCameraSpringArmSettings& Settings)
	{
		if(MoveComp != nullptr)
		{		
			if (!bGroundMoved)
				PreviousPivotLocation += GetApplicableKeepUpWithMovingGroundDelta(InheritedGroundVelocity.Value * DeltaTime, Settings);
			if (!MoveComp.IsAirborne())
			   	InheritedGroundVelocity.AccelerateTo(FVector::ZeroVector, 0.5f, DeltaTime);
		}
		bGroundMoved = false;

		UpdatePivotLag(DeltaTime, Settings);

		FVector UpdatedPivotLoc = TargetPivotLoc;

		// Since we tweak interpolation differently for different axes, we need to handle interpolation in owner space
		// Accelerate owner space in case owner itself is snapped
		PivotOwnerRotation.AccelerateTo(User.WorldToLocalRotation(Owner.ActorRotation), 1.f, DeltaTime);
		FTransform OwnerTransform = FTransform(User.LocalToWorldRotation(PivotOwnerRotation.Value), Owner.ActorLocation);
		FVector LocalTargetLoc = OwnerTransform.InverseTransformPosition(TargetPivotLoc);
		FVector LocalPrevLoc = OwnerTransform.InverseTransformPosition(PreviousPivotLocation);
		FVector LocalPivotVelocity = OwnerTransform.InverseTransformVector(AccPivotWorldVelocity);

		// Update pivot axes separately since we might have separate lag speed and max difference
		UpdatedPivotLoc = LocalTargetLoc;
		UpdatedPivotLoc.X = UpdatePivotAxis(LocalTargetLoc.X, LocalPrevLoc.X, DeltaTime, PivotSpeed.Value.X, LocalPivotVelocity.X);
		UpdatedPivotLoc.Y = UpdatePivotAxis(LocalTargetLoc.Y, LocalPrevLoc.Y, DeltaTime, PivotSpeed.Value.Y, LocalPivotVelocity.Y);
		UpdatedPivotLoc.Z = UpdatePivotAxis(LocalTargetLoc.Z, LocalPrevLoc.Z, DeltaTime, PivotSpeed.Value.Z, LocalPivotVelocity.Z);

		UpdatedPivotLoc = GetClampedToMaxLag(UpdatedPivotLoc, LocalTargetLoc, MaxPivotLag.Value);

		AccPivotWorldVelocity = OwnerTransform.TransformVector(LocalPivotVelocity);
		return OwnerTransform.TransformPosition(UpdatedPivotLoc);
	}

	FVector GetClampedToMaxLag(const FVector& PivotLoc, const FVector& TargetLoc, const FVector& MaxLag)
	{
		FVector ClampedLoc = PivotLoc;
		FVector ToTarget = TargetLoc - PivotLoc;

		// Clamp to elliptical cylinder around target location. For free flying owner it might be nicer to use a spheroid, investigate.
		// Note we don't want to clamp each axis separately (i.e. clamping to within a cubeoid) or we can get glitches when owner turns and moves the corners.

		// Clamp x and y if outside cylinder base
		if (FMath::IsNearlyZero(MaxLag.X) || FMath::IsNearlyZero(MaxLag.Y) || FMath::IsNearlyZero(ToTarget.X) || FMath::IsNearlyZero(ToTarget.Y))
		{
			// Might as well clamp to rectangle if either radius or direction axes are zero (and it avoids some divide by zero issues)
			if (FMath::Abs(ToTarget.X) > MaxLag.X)
				ClampedLoc.X = TargetLoc.X - FMath::Sign(ToTarget.X) * MaxLag.X;
			if (FMath::Abs(ToTarget.Y) > MaxLag.Y)
				ClampedLoc.Y = TargetLoc.Y - FMath::Sign(ToTarget.Y) * MaxLag.Y;
		}
		else if (ToTarget.SizeSquared2D() > FMath::Min(MaxLag.X, MaxLag.Y))
		{
			// We might be outside ellipse, check properly
			float RadiusXSqr = FMath::Square(MaxLag.X);
			float RadiusYSqr = FMath::Square(MaxLag.Y);
			float Inclination = ToTarget.Y / ToTarget.X;
			float Discriminant = RadiusXSqr * RadiusYSqr / (RadiusYSqr + (RadiusXSqr * FMath::Square(Inclination)));
			if (Discriminant < FMath::Square(ToTarget.X))
			{
				// Clamp to where ToTarget line intersects with ellipse around target location
				float IntersectX = FMath::Sign(ToTarget.X) * FMath::Sqrt(Discriminant);
				float IntersectY = IntersectX * Inclination;
				ClampedLoc.X = TargetLoc.X - IntersectX;
				ClampedLoc.Y = TargetLoc.Y - IntersectY;
			}
		}

		// Clamp height if above/below cylinder
		if (FMath::Abs(ToTarget.Z) > MaxLag.Z)
			ClampedLoc.Z = TargetLoc.Z - FMath::Sign(ToTarget.Z) * MaxLag.Z;

		DebugPrintMaxLag(PivotLoc, ClampedLoc, MaxLag);
		return ClampedLoc;
	}

	void DebugPrintMaxLag(const FVector& PivotLoc, const FVector& ClampedLoc, const FVector& MaxLag)
	{
		if (User.ShouldDebugDisplay(ECameraDebugDisplayType::SpringArmLag))
		{
			if (!ClampedLoc.Equals(PivotLoc, 0.1f))
				Print(Owner.GetName() + " Spring arm max Lag hit! Local Pivot/Clamped/MaxLag: " + PivotLoc + " / " + ClampedLoc + " / " + MaxLag);
		}
	}

	void SnapPivotLagAxis(bool bSnap, float Target, float& Value, float& Velocity)
	{
		if (!bSnap)
			return;
		Value = Target;
		Velocity = 0.f;
	}

	void UpdatePivotLag(float DeltaTime, const FHazeCameraSpringArmSettings& Settings)
	{
		// Accelerate pivot lag speed, but snap to 0 in either axis
		PivotSpeed.AccelerateTo(Settings.PivotLagSpeed, 0.5f, DeltaTime);
		SnapPivotLagAxis((Settings.PivotLagSpeed.X == 0.f), 0.f, PivotSpeed.Value.X, PivotSpeed.Velocity.X);
		SnapPivotLagAxis((Settings.PivotLagSpeed.Y == 0.f), 0.f, PivotSpeed.Value.Y, PivotSpeed.Velocity.Y);
		SnapPivotLagAxis((Settings.PivotLagSpeed.Z == 0.f), 0.f, PivotSpeed.Value.Z, PivotSpeed.Velocity.Z);

		// Accelerate pivot maximum lag when decreasing, snap when increasing
		const FVector PivotLagMax = GetPivotLagMaxSettingsValue(Settings);
		MaxPivotLag.AccelerateTo(PivotLagMax, 0.5f, DeltaTime);			
		SnapPivotLagAxis((PivotLagMax.X > MaxPivotLag.Value.X), PivotLagMax.X, MaxPivotLag.Value.X, MaxPivotLag.Velocity.X);
		SnapPivotLagAxis((PivotLagMax.Y > MaxPivotLag.Value.Y), PivotLagMax.Y, MaxPivotLag.Value.Y, MaxPivotLag.Velocity.Y);
		SnapPivotLagAxis((PivotLagMax.Z > MaxPivotLag.Value.Z), PivotLagMax.Z, MaxPivotLag.Value.Z, MaxPivotLag.Velocity.Z);
	}

	FVector GetPivotLagMaxSettingsValue(const FHazeCameraSpringArmSettings& Settings)const
	{
		FVector CurrentValue = Settings.PivotLagMax;
		if(Settings.bUsePivotLagMaxMultiplierByPitchCurve)
		{
			float LocalPitch = User.WorldToLocalRotation(GetWorldRotation()).Pitch;
			CurrentValue *= Settings.PivotLagMaxMultiplierByPitchCurve.GetFloatValue(LocalPitch, 1.f);
		}

		return CurrentValue;
	}

	void UpdateTraceBlockedExtension(float DeltaTime, FHazeCameraSpringArmSettings Settings, const FVector& PivotLoc, const FVector& TargetCameraLoc)
	{
		if (TraceBlockedRange.Value < Settings.MinDistance)
			TraceBlockedRange.Value = Settings.MinDistance;

		float TargetDistance = PivotLoc.Distance(TargetCameraLoc);
		bool bIsRotating = RotationDuration > 0.f;
		bool bPastDelay = Time::GetRealTimeSince(TraceBlockedTime) > 0.2f;
		if (bIsRotating || bPastDelay)
		{
			if (TraceBlockedRange.Value > TargetDistance)	
			{
				TraceBlockedRange.Value = Math::BigNumber;
				TraceBlockedRange.Velocity = 0.f;
				TraceBlockedExtensionAccelerationFactor.SnapTo(1.f);
			}
			else
			{	
				// Acceleration outwards, acc depends on view angular velocity.
				FRotator ViewAngularVel = User.WorldToLocalRotation(PlayerUser.GetViewAngularVelocity());
				float YawRotationFactor = FMath::GetMappedRangeValueClamped(FVector2D(60.f, 180.f), FVector2D(1.f, 5.f), FMath::Abs(ViewAngularVel.Yaw));
				float PitchRotationFactor = FMath::GetMappedRangeValueClamped(FVector2D(10.f, 60.f), FVector2D(1.f, 20.f), FMath::Abs(ViewAngularVel.Pitch));
				float RotationFactor = FMath::Max(YawRotationFactor, PitchRotationFactor);
				float AccDuration = (RotationFactor > TraceBlockedExtensionAccelerationFactor.Value) ? 0.2f : 5.f;
				TraceBlockedExtensionAccelerationFactor.AccelerateTo(RotationFactor, AccDuration, DeltaTime);

				float Acc = TargetDistance * RotationFactor;
				float Friction = TraceBlockedRange.Velocity * 0.3f; 
				TraceBlockedRange.Velocity += (Acc - Friction) * DeltaTime;
				TraceBlockedRange.Velocity = FMath::Max(TraceBlockedRange.Velocity, 0.f); // Never shrink 
				TraceBlockedRange.Value += TraceBlockedRange.Velocity * DeltaTime;
			}
		}
		else
		{
			TraceBlockedExtensionAccelerationFactor.SnapTo(1.f);
		}

		// Always allow blocked range to reach as far as the last camera location, in case we're moving away from obstructions.
		if ((TraceBlockedRange.Value < TargetDistance) && !PreviousCameraLocation.IsNear(PivotLoc, TraceBlockedRange.Value))
		 	TraceBlockedRange.Value = PreviousCameraLocation.Distance(PivotLoc); // Note that velocity and blocked time remains the same

#if TEST
		if (TestBlockedRangeFraction < 1.f)
		 	TraceBlockedRange.Value = TargetCameraLoc.Distance(PivotLoc) * TestBlockedRangeFraction;

		float ForceMinBlockedRange = CVar_SpringArmForceMinTraceBlockedRange.Float;
		if (TraceBlockedRange.Value < ForceMinBlockedRange)
			TraceBlockedRange.Value = ForceMinBlockedRange;
#endif
	}

	void SetTraceBlockedRange(float Range)
	{
		TraceBlockedRange.Value = Range;
		TraceBlockedRange.Velocity = 0.f;
		TraceBlockedTime = Time::GetRealTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	void Snap()
	{
		if ((Camera == nullptr) || (User == nullptr) || (PlayerUser == nullptr))
			return;

		FHazeCameraSpringArmSettings Settings;
		GetSettings(Settings);
		TraceBlockedTime = -Math::BigNumber;
		TraceBlockedRange.Value = Math::BigNumber;
		TraceBlockedRange.Velocity = 0.f;
		TraceBlockedExtensionAccelerationFactor.SnapTo(1.f);
		WorldPivotOffset = FVector::ZeroVector;
		WorldPivotOffsetResetSpeed = 0.f;
		
		// To avoid initial pivot lag when camera is snapped (e.g. with flying machine), match pivot velocity with owner velocity
		AccPivotWorldVelocity = Owner.ActorVelocity; 
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		if (HazeOwner != nullptr)
			AccPivotWorldVelocity = HazeOwner.ActualVelocity;
		if (StartPivotVelocity != FVector::ZeroVector)
			AccPivotWorldVelocity = Owner.ActorTransform.TransformVector(StartPivotVelocity);
		PivotOwnerRotation.SnapTo(User.WorldToLocalRotation(Owner.ActorRotation));

		PivotSpeed.SnapTo(Settings.PivotLagSpeed);
		MaxPivotLag.SnapTo(GetPivotLagMaxSettingsValue(Settings));
		PreviousWorldRotation = User.GetDesiredRotation();
		PreviousPivotLocation = GetTargetPivotLocation(Settings);
		PreviousCameraLocation = Camera.GetWorldLocation();
		SnapIdealDistanceByPitchCurve(Settings);
		SnapPivotHeightByPitchCurve(Settings);
		SnapCameraOffsetByPitchCurve(Settings);
		SnapCameraOffsetOwnerSpaceByPitchCurve(Settings);
		UpdateInternal(0.f, Settings);

		bClearPredictions = true;
	}

	UFUNCTION(BlueprintOverride)
	bool CheckPivotLocation(FVector& OutPivotLocation)
	{
		OutPivotLocation = PreviousPivotLocation;
		return true;
	}

	void SetWorldPivotOffset(const FVector& Offset, float AutoResetSpeed = 0.f)
	{
		WorldPivotOffset = Offset;
		WorldPivotOffsetResetSpeed = AutoResetSpeed;
	}

	void UpdateWorldPivotOffset(float DeltaTime)
	{
		if ((WorldPivotOffsetResetSpeed > 0.f) && !WorldPivotOffset.IsZero())
		{
			FVector Delta = WorldPivotOffset.GetSafeNormal() * WorldPivotOffsetResetSpeed * DeltaTime;
			if (WorldPivotOffset.SizeSquared() < Delta.SizeSquared())
				Delta = WorldPivotOffset;
			WorldPivotOffset -= Delta; 

			// Move as if attached
			PreviousPivotLocation -= Delta;	
		}
	}

	void UpdatePredictedTraceBlockage(const FVector& PivotLoc, const FVector& CameraLoc, float DeltaTime)
	{
		if (CVar_SpringArmUsePrediction.Int == 0)
			return;

		if (DeltaTime == 0.f)
			return;

		bool bSkipPrediction = bClearPredictions;
		bClearPredictions = false;
		if (bSkipPrediction)
		{
			// We shall not try to predict this update
			PredictedObstructions.Empty();
			PredictedReturnObstructions.Empty();
			return; 
		}

		if (PredictedCameraLocation.IsNear(CameraLoc, Camera.CameraCollisionParams.ProbeSize))
			return; // We're almost at where we thought we will be in a while, no use adjusting

		float PredictedBlockRange = GetPredictedBlockedRange(PredictedPivotLocation, PredictedCameraLocation);
		if (PredictedBlockRange == BIG_NUMBER)
			return; // Sunny skies ánd no obstructions in the current forecast
		if (TraceBlockedRange.Value < PredictedBlockRange)
			return; // We're currently blocked closer

		// We should move in closer due to prediction. 
		float CurBlockedRange = TraceBlockedRange.Value;
		if (PivotLoc.IsNear(CameraLoc, CurBlockedRange))
			CurBlockedRange = PivotLoc.Distance(CameraLoc);
		float NewBlockedRange = FMath::Lerp(CurBlockedRange, PredictedBlockRange, DeltaTime * 5.f);
		SetTraceBlockedRange(NewBlockedRange);
	}

	FVector GetPredictedCameraLocation(const FVector& PivotLoc, const FVector& CameraLoc, const FRotator& Rotation, const FVector& CameraWorldOffset, const FVector& CameraLocalOffset, FVector& OutPredictedPivotLoc)
	{
		// Use user velocity for prediction		
		FVector PivotVelocity = PlayerUser.GetActualVelocity();
		
		// If there is any movement, we always predict as if we were moving at least at this speed
		float MinSpeed = 0.f;
		if (!PivotVelocity.IsNearlyZero(1.f) && PivotVelocity.IsNearlyZero(MinSpeed))
			PivotVelocity = PivotVelocity.GetClampedToSize(MinSpeed, MinSpeed);

		// Tweak angular velocity to use in user base space
		FRotator AngularVelocity = User.WorldToLocalRotation(PlayerUser.GetViewAngularVelocity());

		// Cap angular velocity at this limit
		float MaxAngularSpeed = 45.f;
		AngularVelocity.Roll = 0.f;
		AngularVelocity.Pitch = FMath::ClampAngle(AngularVelocity.Pitch, -MaxAngularSpeed, MaxAngularSpeed); 
		AngularVelocity.Yaw = FMath::ClampAngle(AngularVelocity.Yaw, -MaxAngularSpeed, MaxAngularSpeed); 

		// If there is any rotation, we always predict as if we're rotating at least this much in yaw only
		float MinYawSpeed = 1.f;
		if (!FMath::IsNearlyZero(AngularVelocity.Yaw, 0.9f) && (FMath::Abs(AngularVelocity.Yaw) < MinYawSpeed))
			AngularVelocity.Yaw = FMath::Sign(AngularVelocity.Yaw) * MinYawSpeed;

		AngularVelocity = User.LocalToWorldRotation(AngularVelocity);

		// How far into the future will we gaze?
		float LookAhead = 0.7f;
		OutPredictedPivotLoc = PivotLoc + PivotVelocity * LookAhead;

		// Predicted rotation is clamped in user base space
		FRotator LocalPredictedRotation = User.WorldToLocalRotation(Rotation + AngularVelocity * LookAhead);
		FRotator PredictedRotation = User.LocalToWorldRotation(User.ClampLocalRotation(LocalPredictedRotation));

		FVector PredictedCamLoc = OutPredictedPivotLoc + CameraWorldOffset;
		PredictedCamLoc += PredictedRotation.RotateVector(CameraLocalOffset);
		return PredictedCamLoc;
	}

	void PreparePredictedTraceBlockage(const FVector& PivotLoc, const FVector& CameraLoc, const FRotator& Rotation, const FVector& CameraWorldOffset, const FVector& CameraLocalOffset)
	{
		PredictedCameraLocation	= GetPredictedCameraLocation(PivotLoc, CameraLoc, Rotation, CameraWorldOffset, CameraLocalOffset, PredictedPivotLocation);	

		FHazeCameraAsyncTraceCompleteDelegate TraceCompleteDelegate;
		TraceCompleteDelegate.BindUFunction(this, n"OnAsyncTraceComplete");
		Camera.AsyncCollisionCheck(this, n"PredictedCollisions", TraceCompleteDelegate, PredictedPivotLocation, PredictedCameraLocation, Camera.CameraCollisionParams.ProbeSize, true);

		FHazeCameraAsyncTraceCompleteDelegate ReturnTraceCompleteDelegate;
		ReturnTraceCompleteDelegate.BindUFunction(this, n"OnAsyncReturnTraceComplete");
		Camera.AsyncCollisionCheck(this, n"PredictedReturnCollisions", ReturnTraceCompleteDelegate, PredictedCameraLocation, PredictedPivotLocation, Camera.CameraCollisionParams.ProbeSize, true);

#if TEST
		//bDebugDrawPrediction = PlayerUser.IsMay();
		if (bDebugDrawPrediction)
		{
			System::DrawDebugSphere(PredictedPivotLocation, 30.f, 4, FLinearColor::Yellow);
			System::DrawDebugSphere(PredictedCameraLocation, 5.f, 12, FLinearColor::Yellow);
			System::DrawDebugLine(PredictedPivotLocation, PredictedCameraLocation, FLinearColor::Yellow);
		}
#endif
	}

	UFUNCTION()
	void OnAsyncTraceComplete(const TArray<FHitResult>& Obstructions)
	{
		PredictedObstructions = Obstructions;
	}

	UFUNCTION()
	void OnAsyncReturnTraceComplete(const TArray<FHitResult>& Obstructions)
	{
		PredictedReturnObstructions = Obstructions;
	}

	float GetPredictedBlockedRange(const FVector& PivotLoc, const FVector& EndLocation)
	{
		// Find all blocking obstructions and first always blocking obstruction, if any.
		bool bAlwaysBlock = false;
		TArray<FSpringArmObstruction> Obstructions;
		TMap<AActor,int> Blockers;
		for (FHitResult Obstruction : PredictedObstructions)
		{
			if (!Obstruction.bBlockingHit)
				continue;
			// Save the blocker with index into ObstructionLocs array
			Blockers.Add(Obstruction.Actor, Obstructions.Num());
			Obstructions.Add(FSpringArmObstruction(Obstruction.Location));
			if (IsAlwaysBlockingObstruction(Obstruction))
			{
				bAlwaysBlock = true;
				break;
			}
		}

#if TEST
		//bDebugDrawPrediction = PlayerUser.IsMay();
		if ((bDebugDrawPrediction) && (Obstructions.Num() == 0))
			System::DrawDebugLine(PredictedPivotLocation, PredictedCameraLocation, FLinearColor::Green);
#endif

		if (Obstructions.Num() == 0)
			return BIG_NUMBER; // No obstructions

		// Find the back side of all blockers
		for (FHitResult ReturnObstruction : PredictedReturnObstructions)
		{
			if (!ReturnObstruction.bBlockingHit)
				continue;
			AActor BacksideActor = ReturnObstruction.Actor;
			if (Blockers.Contains(BacksideActor))
			{
				Obstructions[Blockers[BacksideActor]].Back = ReturnObstruction.Location;
				Blockers.Remove(BacksideActor);
			}
		}

		// Find location we're we might have room to place camera, with index into obstructions list.
		int EndIndex = Obstructions.Num(); // There might be space beyond last blocker
		if (bAlwaysBlock)
			EndIndex = Obstructions.Num() - 1; // Camera is not allowed to extend beyond last blocker
		for (auto Blocker : Blockers)
		{
			// Failed to find a back side, assume we're inside blocker so cannot extend beyond
			EndIndex =	FMath::Min(Blocker.Value, EndIndex);
		}
		FVector EndLoc = EndLocation;
		if (Obstructions.IsValidIndex(EndIndex))
			EndLoc = Obstructions[EndIndex].Front;

		// Check if there's enough room behind obstructions
		float ScaledObstructedClearance = ObstructedClearance * PlayerUser.ActorScale3D.Z;
		for (int i = EndIndex - 1; i >= 0; i--)
		{
			// Is there enough of a gap here or do we need to try from the front of the obstruction instead?
			if (!EndLoc.IsNear(Obstructions[i].Back, ScaledObstructedClearance))	
				break; 
			EndLoc = Obstructions[i].Front;
		}

#if TEST
		//bDebugDrawPrediction = PlayerUser.IsMay();
		if (bDebugDrawPrediction)
		{
			System::DrawDebugSphere(EndLoc, 50, 12, FLinearColor::Green);
			for (int i = 0; i < Obstructions.Num(); i++)
			{
				System::DrawDebugSphere(Obstructions[i].Front, 20, 4, FLinearColor::Red);
				System::DrawDebugSphere(Obstructions[i].Back, 20, 4, FLinearColor::Yellow);
				System::DrawDebugLine(Obstructions[i].Front, Obstructions[i].Back, FLinearColor::Red);
			}	
		}
#endif

		return PivotLoc.Distance(EndLoc);
	}

	void UpdateIdealDistanceByPitchCurve(float DeltaTime, const FHazeCameraSpringArmSettings& Settings)
	{
		UCurveFloat CurrentCurve = Settings.bUseIdealDistanceByPitchCurve ? Settings.IdealDistanceByPitchCurve : nullptr;
		if (!IdealDistanceByPitchCurves.NeedsUpdate(CurrentCurve))
			return;
		FHazeAllCameraSettings Test;
		Test.SpringArmSettings.bUseIdealDistance = true; 
		float BlendTime = GetBlendTimeAffecting(Test);
		IdealDistanceByPitchCurves.SetTargetCurve(CurrentCurve, BlendTime);
		IdealDistanceByPitchCurves.Update(DeltaTime);
	}

	void UpdateCameraOffsetByPitchCurve(float DeltaTime, const FHazeCameraSpringArmSettings& Settings)
	{
		if (!Settings.bUseCameraOffsetByPitchCurve && !CameraOffsetByPitchCurves.NeedsUpdate(nullptr))
			return;
		if (Settings.bUseCameraOffsetByPitchCurve && !CameraOffsetByPitchCurves.NeedsUpdate(Settings.CameraOffsetByPitchCurve))
			return;
		FHazeAllCameraSettings Test;
		Test.SpringArmSettings.bUseCameraOffset = true; // Match blend time to camera offset
		float BlendTime = GetBlendTimeAffecting(Test);
		if (Settings.bUseCameraOffsetByPitchCurve)
			CameraOffsetByPitchCurves.SetTargetRuntimeCurve(Settings.CameraOffsetByPitchCurve, BlendTime);
		else
			CameraOffsetByPitchCurves.SetTargetCurve(nullptr, BlendTime);
		CameraOffsetByPitchCurves.Update(DeltaTime);
	}

	void UpdateCameraOffsetOwnerSpaceByPitchCurve(float DeltaTime, const FHazeCameraSpringArmSettings& Settings)
	{
		if (!Settings.bUseCameraOffsetOwnerSpaceByPitchCurve && !CameraOffsetOwnerSpaceByPitchCurves.NeedsUpdate(nullptr))
			return;
		if (Settings.bUseCameraOffsetOwnerSpaceByPitchCurve && !CameraOffsetOwnerSpaceByPitchCurves.NeedsUpdate(Settings.CameraOffsetOwnerSpaceByPitchCurve))
			return;
		FHazeAllCameraSettings Test;
		Test.SpringArmSettings.bUseCameraOffsetOwnerSpace = true; 
		float BlendTime = GetBlendTimeAffecting(Test);
		if (Settings.bUseCameraOffsetOwnerSpaceByPitchCurve)
			CameraOffsetOwnerSpaceByPitchCurves.SetTargetRuntimeCurve(Settings.CameraOffsetOwnerSpaceByPitchCurve, BlendTime);
		else
			CameraOffsetOwnerSpaceByPitchCurves.SetTargetCurve(nullptr, BlendTime);
		CameraOffsetOwnerSpaceByPitchCurves.Update(DeltaTime);
	}

	void UpdatePivotHeightByPitchCurve(float DeltaTime, const FHazeCameraSpringArmSettings& Settings)
	{
		if (!Settings.bUsePivotHeightByPitchCurve && !PivotHeightByPitchCurves.NeedsUpdate(nullptr))
			return;
		if (Settings.bUsePivotHeightByPitchCurve && !PivotHeightByPitchCurves.NeedsUpdate(Settings.PivotHeightByPitchCurve))
			return;
		FHazeAllCameraSettings Test;
		Test.SpringArmSettings.bUsePivotOffset = true; 
		float BlendTime = GetBlendTimeAffecting(Test);
		if(Settings.bUsePivotHeightByPitchCurve)
			PivotHeightByPitchCurves.SetTargetRuntimeCurve(Settings.PivotHeightByPitchCurve, BlendTime);
		else
			PivotHeightByPitchCurves.SetTargetCurve(nullptr, BlendTime);
		PivotHeightByPitchCurves.Update(DeltaTime);
	}

	float GetBlendTimeAffecting(const FHazeAllCameraSettings& AffectingSettings)
	{
		float BlendTime = User.GetSettingsManager().GetBlendTimeAffecting(AffectingSettings);
		if (BlendTime == FHazeCameraBlendSettings::Invalid.BlendTime)
			BlendTime = CameraBlend::Normal().BlendTime;
		return BlendTime;
	}

	void SnapIdealDistanceByPitchCurve(const FHazeCameraSpringArmSettings& Settings)
	{
		UCurveFloat CurrentCurve = Settings.bUseIdealDistanceByPitchCurve ? Settings.IdealDistanceByPitchCurve : nullptr;
		IdealDistanceByPitchCurves.SetTargetCurve(CurrentCurve, 0.f);
	}

	void SnapPivotHeightByPitchCurve(const FHazeCameraSpringArmSettings& Settings)
	{
		if(Settings.bUsePivotHeightByPitchCurve)
			PivotHeightByPitchCurves.SetTargetRuntimeCurve(Settings.PivotHeightByPitchCurve, 0.f);
		else
			PivotHeightByPitchCurves.SetTargetCurve(nullptr, 0.f);
	}

	void SnapCameraOffsetByPitchCurve(const FHazeCameraSpringArmSettings& Settings)
	{
		if(Settings.bUseCameraOffsetByPitchCurve)
			CameraOffsetByPitchCurves.SetTargetRuntimeCurve(Settings.CameraOffsetByPitchCurve, 0.f);
		else
			CameraOffsetByPitchCurves.SetTargetCurve(nullptr, 0.f);
	}

	void SnapCameraOffsetOwnerSpaceByPitchCurve(const FHazeCameraSpringArmSettings& Settings)
	{
		if(Settings.bUseCameraOffsetOwnerSpaceByPitchCurve)
			CameraOffsetOwnerSpaceByPitchCurves.SetTargetRuntimeCurve(Settings.CameraOffsetOwnerSpaceByPitchCurve, 0.f);
		else
			CameraOffsetOwnerSpaceByPitchCurves.SetTargetCurve(nullptr, 0.f);
	}
};

