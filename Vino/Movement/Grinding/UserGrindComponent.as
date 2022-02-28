import Vino.Movement.Grinding.GrindSpline;
import Vino.Movement.Grinding.GrindSettings;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Grinding.GrindingReasons;
import Vino.Movement.Grinding.GrindingCustomSpeedRegionComponent;
import Vino.Movement.SplineLock.SplineLockComponent;
import Vino.Movement.Grinding.GrindingForceFeedbackData;

event void FOnGrindSplineAttached(AGrindspline GrindSpline, EGrindAttachReason Reason);
event void FOnGrindSplineTargeted(AGrindspline GrindSpline, EGrindTargetReason Reason);
event void FOnGrindSplineDetached(AGrindspline GrindSpline, EGrindDetachReason Reason);

class UUserGrindComponent : UActorComponent
{
	UPROPERTY(Transient, EditConst)
	TArray<AGrindspline> ValidNearbyGrindSplines;

	UHazeMovementComponent MoveComp;
	UHazeSplineFollowComponent FollowComp;
	USplineLockComponent LockComp;

	AHazeActor HazeOwner;

	TArray<FGrindSplineCooldown> GrindSplineCooldowns;
	TArray<FGrindSplineCooldown> GrindSplineLowPriorities;
	UPROPERTY()
	UGrindingForceFeedbackData GrindingForceFeedbackData;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY(EditConst)
	FGrindSplineData TargetGrindSplineData;

	UPROPERTY()
	float CurrentSpeed = 0.f;
	UPROPERTY()
	float DesiredSpeed = GrindSettings::Speed.BasicSettings.DesiredMinimum;

	UPROPERTY()
	FVector MoveInput;

	UPROPERTY()
	float TimestampGrindingStopped = -1.f;

	UPROPERTY()
	float TimestampGrindingStarted = -1.f;

	UPROPERTY()
	FOnGrindSplineAttached OnGrindSplineAttached;
	UPROPERTY()
	FOnGrindSplineTargeted OnGrindSplineTargeted;
	UPROPERTY()
	FOnGrindSplineDetached OnGrindSplineDetached;

	UPROPERTY(Transient)
	TArray<AActor> ActorsInActiveSystem;

	bool bIsHorizontallyLocked = false;
	bool bStickInputOnlyBrakeLock = false;
	bool bIsHardLocked = false;

	AGrindspline PreviousGrindSpline = nullptr;

	FVector TargetPointLocation = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		ensure(HazeOwner != nullptr);

		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		FollowComp = UHazeSplineFollowComponent::GetOrCreate(Owner);
		LockComp = USplineLockComponent::GetOrCreate(Owner);
	}

	void UpdateTargetGrindSpline(FGrindSplineData GrindSplineLocationData)
	{
		ensure(GrindSplineLocationData.IsValid());

		HazeOwner.SetCapabilityActionState(GrindingActivationEvents::TargetGrind, EHazeActionState::Active);
		TargetGrindSplineData = GrindSplineLocationData;
		bStickInputOnlyBrakeLock = false;
	}

	void StartGrinding(AGrindspline GrindSpline, EGrindAttachReason AttachReason, FVector InputVector = FVector::ZeroVector)
	{
		if (HasControl())
			ensure(GrindSpline == TargetGrindSplineData.GrindSpline);

		FHazeSplineSystemPosition SplineSystemPosition = GrindSpline.Spline.GetPositionClosestToWorldLocation(Owner.ActorLocation, true);

		if (GrindSpline.TravelDirection == EGrindSplineTravelDirection::Bidirectional)
		{
			FVector SplineForward = SplineSystemPosition.WorldForwardVector;

			FVector CompareVector;
			FVector HorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
			if (HorizontalVelocity.Size() > 300.f)
				CompareVector = HorizontalVelocity;
			else if (InputVector.Size() > 0.5f)
				CompareVector = InputVector.GetSafeNormal();
			else
				CompareVector = Owner.ActorForwardVector;

			CompareVector.Normalize();

			float DirectionSplineDot = SplineForward.DotProduct(CompareVector);

			// Update the spline direction to match the velocity
			if (DirectionSplineDot < 0.f)
				SplineSystemPosition.Reverse();
		}		

		FGrindSplineData GrindSplineData(GrindSpline, SplineSystemPosition);
		StartGrinding(GrindSplineData, AttachReason);
	}

	void StartGrinding(FGrindSplineData GrindSplineData, EGrindAttachReason AttachReason)
	{
		FGrindSplineData NewActiveGrindSplineData = GrindSplineData;
		if (GrindSplineData.GrindSpline.TravelDirection != EGrindSplineTravelDirection::Bidirectional)
		{
			EGrindSplineTravelDirection SplineDirection = GrindSplineData.SystemPosition.IsForwardOnSpline() ? EGrindSplineTravelDirection::Forwards : EGrindSplineTravelDirection::Backwards;

			if (SplineDirection != GrindSplineData.GrindSpline.TravelDirection)
				NewActiveGrindSplineData.SystemPosition.Reverse();
		}

		FollowComp.ActivateSplineMovement(NewActiveGrindSplineData.SystemPosition);
		FollowComp.IncludeSplineInActorReplication(this);

		HazeOwner.SetCapabilityActionState(GrindingActivationEvents::Grinding, EHazeActionState::Active);

		// Broadcast attach events
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		if (Player != nullptr)
			GrindSplineData.GrindSpline.OnPlayerAttached.Broadcast(Player, AttachReason);
		OnGrindSplineAttached.Broadcast(GrindSplineData.GrindSpline, AttachReason);

		TargetGrindSplineData.SystemPosition.GetActorsInSystem(ActorsInActiveSystem);
		ActorsInActiveSystem.Add(GrindSplineData.GrindSpline.IgnoreActorWhileGrinding);
		MoveComp.StartIgnoringActors(ActorsInActiveSystem);

		ResetTargetGrindSpline();

		for (FName CapabilityTag : ActiveGrindSpline.CapabilityBlocks)
		{
			Player.BlockCapabilities(CapabilityTag, this);
		}

		TimestampGrindingStarted = Time::GetGameTimeSeconds();
		UnlockHorizontalSplineLock();
	}

	void LeaveActiveGrindSpline(EGrindDetachReason DetachReason)
	{
		// Fire detach events for player and grind spline
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		if (Player != nullptr)
			ActiveGrindSpline.OnPlayerDetached.Broadcast(Player, DetachReason);
		OnGrindSplineDetached.Broadcast(ActiveGrindSpline, DetachReason);

		HazeOwner.SetCapabilityActionState(GrindingActivationEvents::Grinding, EHazeActionState::Inactive);

		ensure(ActiveGrindSpline != nullptr);

		for (FName CapabilityTag : ActiveGrindSpline.CapabilityBlocks)
		{
			Player.UnblockCapabilities(CapabilityTag, this);
		}
		PreviousGrindSpline = ActiveGrindSpline;

		MoveComp.StopIgnoringActors(ActorsInActiveSystem);
		FollowComp.RemoveSplineFromActorReplication(this);
		FollowComp.DeactivateSplineMovement();

		TimestampGrindingStopped = Time::GetGameTimeSeconds();
	}
	
	bool ShouldLockToSpline(FVector InputVector) const
	{
		/*
			If you have no input, you should spline lock
			If you have input, check the angle between input and angle to see if you should spline lock
		*/

		if (ActiveGrindSpline != nullptr && ActiveGrindSpline.bHardSplineLock)
			return true;

		FVector MoveDirection = InputVector;
		if (MoveDirection.IsNearlyZero(0.4f))
			return true;		

		FVector Tangent;
		if (bIsHorizontallyLocked)
			Tangent = LockComp.Constrainer.CurrentSplineLocation.WorldForwardVector;
		else
			Tangent = SplinePosition.WorldForwardVector;

		MoveDirection.Normalize();
		Tangent = Tangent.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

		float TangentMoveDot = Tangent.DotProduct(MoveDirection);		
		float AngleDifference = Math::DotToDegrees(TangentMoveDot);

		// Clamp the angle between the shortest direction to the tangent
		if (AngleDifference > 90.f)
			AngleDifference = 180.f - AngleDifference;

		return AngleDifference <= GrindSettings::Jump.SplineLockInputTangentAngle;
	}

	bool IsSplineLocked() const
	{
		return bIsHorizontallyLocked && LockComp.IsActiveltyConstraining();
	}

	void LockHorizontallyToActiveSpline()
	{
		if (!HasControl())
			return;

		if (!ensure(HasActiveGrindSpline()))
			return;

		if (!ensure(!IsSplineLocked()))
			return;

		FConstraintSettings Settings;
		Settings.bLockToEnds = false;
		Settings.ConstrainType = EConstrainCollisionHandlingType::FreeVertical;
		Settings.SplineToLockMovementTo = ActiveGrindSpline.LockSpline;
		LockComp.LockOwnerToSpline(Settings, ESplineLockType::Normal);
		bIsHorizontallyLocked = true;
		bStickInputOnlyBrakeLock = ActiveGrindSpline.bOnlyStickInputBreakLock;
		bIsHardLocked = ActiveGrindSpline.bHardSplineLock;
	}

	bool IsStickOnlyLocked() const
	{
		return bStickInputOnlyBrakeLock || IsHardLocked();
	}

	bool IsHardLocked() const
	{
		return bIsHardLocked;
	}

	void UnlockHorizontalSplineLock()
	{
		LockComp.StopLocking();
		bIsHorizontallyLocked = false;
		bStickInputOnlyBrakeLock = false;
	}

	void ResetTargetGrindSpline()
	{
		TargetGrindSplineData.Reset();
		HazeOwner.SetCapabilityActionState(GrindingActivationEvents::TargetGrind, EHazeActionState::Inactive);
  	}

	bool IsValidToStartGrinding() const
	{
		return HasTargetGrindSpline() && !HasActiveGrindSpline();
	}

	bool HasTargetGrindSpline() const
	{
		return TargetGrindSplineData.IsValid();
	}

	bool HasActiveGrindSpline() const
	{
		const AGrindspline CurrentSpline = GetActiveGrindSpline();
		if (CurrentSpline == nullptr)
			return false;

		if(!CurrentSpline.bGrindingAllowed)
			return false;

		return true;
	}

	bool HasPotentionalSplines() const
	{
		return ValidNearbyGrindSplines.Num() > 0;
	}

	FVector GetCurrentHeigtOffset() const property
	{
		return SplinePosition.WorldUpVector * ActiveGrindSpline.HeightOffset;
	}

	UFUNCTION(BlueprintPure)
	bool IsGrindingActive() const
	{
		return HasTargetGrindSpline() || HasActiveGrindSpline();
	}

	/* 	
		Add/Update the cooldown of the specified grind spline
			- If no spline was given, try to use active grind spline
		Update the cooldown if found
		Add new cooldown if not found
	*/
	bool StartGrindSplineCooldown(AGrindspline GrindSpline = nullptr)
	{
		AGrindspline GrindSplineForCooldown;
		if (GrindSpline != nullptr)
			GrindSplineForCooldown = GrindSpline;
		else if (ActiveGrindSplineData.GrindSpline != nullptr)
			GrindSplineForCooldown = ActiveGrindSplineData.GrindSpline;
		else
			return false;
	
		for (int Index = 0; Index < GrindSplineCooldowns.Num(); Index++)
		{
			if (GrindSplineCooldowns[Index] == GrindSpline)
			{
				GrindSplineCooldowns[Index].Cooldown = GrindSettings::GrindSplineCooldown;
				return true;
			}
		}

		FGrindSplineCooldown NewGrindSplineCooldown;
		NewGrindSplineCooldown.Cooldown = GrindSettings::GrindSplineCooldown;
		NewGrindSplineCooldown.GrindSpline = GrindSpline;
		GrindSplineCooldowns.Add(NewGrindSplineCooldown);

		return true;
	}

	bool StartGrindSplineLowPriority(AGrindspline GrindSpline = nullptr)
	{
		AGrindspline GrindSplineForLowPriority;
		if (GrindSpline != nullptr)
			GrindSplineForLowPriority = GrindSpline;
		else if (ActiveGrindSplineData.GrindSpline != nullptr)
			GrindSplineForLowPriority = ActiveGrindSplineData.GrindSpline;
		else
			return false;
	
		for (int Index = 0; Index < GrindSplineLowPriorities.Num(); Index++)
		{
			if (GrindSplineLowPriorities[Index] == GrindSpline)
			{
				GrindSplineLowPriorities[Index].Cooldown = GrindSettings::GrindSplineLowPriorityDuration;
				return true;
			}
		}

		FGrindSplineCooldown NewGrindSplineCooldown;
		NewGrindSplineCooldown.Cooldown = GrindSettings::GrindSplineLowPriorityDuration;
		NewGrindSplineCooldown.GrindSpline = GrindSpline;
		GrindSplineLowPriorities.Add(NewGrindSplineCooldown);

		return true;
	}

	FGrindSplineData GetGrindSplineDataFromDistanceAlongSpline(AGrindspline GrindSpline, float DistanceAlongSpline)
	{
		FHazeSplineSystemPosition SystemPosition;
		SystemPosition.FromData(GrindSpline.Spline, DistanceAlongSpline, true);

		return FGrindSplineData(GrindSpline, SystemPosition);		
	}

	const FHazeSplineSystemPosition& GetTargetPosition() const property
	{
		return TargetGrindSplineData.SystemPosition;
	}

	void UpdateRemoteSplineLocation(FHazeActorReplicationFinalized ReplicationParams)
	{
		FollowComp.UpdateReplicatedSplineMovement(ReplicationParams);
	}

	void OverrideCurrentSpeed(float Speed)
	{
		CurrentSpeed = Speed;
	}

	void UpdateTargetPointLocation(FVector Location)
	{
		TargetPointLocation = Location;
	}

	float CalculateInitialSpeed(FGrindSplineData& GrindSplineLocationData, FVector Velocity)
	{
		FVector Forward = GrindSplineLocationData.SystemPosition.WorldForwardVector;
		float ForwardVelocityDot = Forward.DotProduct(Velocity);

		float ForwawrdVelocity = FMath::Max(ForwardVelocityDot, 0.f);

		return ForwardVelocityDot;
	}

	UFUNCTION(BlueprintPure)
	FGrindSpeedSettings GetSpeedSettings() property
	{
		return GrindSettings::Speed;
	}

	FString GetDebugString() const
	{
		FString Output;
		return Output;
	}

	USplineMeshComponent GetCurrentSplineMesh() const property
	{
		if (FollowComp.ActiveSpline == nullptr)
			return nullptr;

		UHazeSplineComponentBase DummyComp;
		float Distance = 0;
		bool bDummyForward = true;
		FollowComp.Position.BreakData(DummyComp, Distance, bDummyForward);

		return ActiveGrindSpline.SplineMeshContainer.GetMeshAtDistance(Distance);
	}
	
	AGrindspline GetActiveGrindSpline() const property
	{
		if (FollowComp.ActiveSpline == nullptr)
			return nullptr;
		
		return Cast<AGrindspline>(FollowComp.ActiveSpline.Owner);
	}

	AGrindspline GetPreviousActiveGrindSpline() const property
	{
		return PreviousGrindSpline;
	}

	FHazeSplineSystemPosition GetSplinePosition() const property
	{
		return FollowComp.Position;
	}

	UFUNCTION(BlueprintPure)
	FGrindSplineData GetActiveGrindSplineData() const property
	{
		FGrindSplineData ActiveData;
		ActiveData.GrindSpline = ActiveGrindSpline;

		if (ActiveGrindSpline != nullptr)
			ActiveData.SystemPosition = FollowComp.Position;

		return ActiveData;
	}

	UFUNCTION(BlueprintPure)
	float GetSpeedPercentageIncludingBoost() property
	{
		float MinSpeed = BasicSpeedSettings.DesiredMinimum;
		float MaxSpeed = BasicSpeedSettings.DesiredMaximum + GrindSettings::Dash.Impulse;
		return Math::Saturate(Math::NormalizeToRange(CurrentSpeed, MinSpeed, MaxSpeed));
	}

	UFUNCTION(BlueprintPure)
	float GetSpeedPercentage() property
	{
		float MinSpeed = BasicSpeedSettings.DesiredMinimum;
		float MaxSpeed = BasicSpeedSettings.DesiredMaximum;
		return Math::Saturate(Math::NormalizeToRange(CurrentSpeed, MinSpeed, MaxSpeed));
	}

	FGrindBasicSpeedSettings GetBasicSpeedSettings() const property
	{
		if (ActiveGrindSpline != nullptr)
		{
			UGrindingCustomSpeedRegionComponent SpeedRegion = Cast<UGrindingCustomSpeedRegionComponent>(ActiveGrindSpline.RegionContainer.GetActiveRegionTypeForActor(UGrindingCustomSpeedRegionComponent::StaticClass(), HazeOwner));
			if (SpeedRegion != nullptr)
				return SpeedRegion.CustomSpeed;

			return ActiveGrindSpline.CustomSpeed;
		}

		return GrindSettings::Speed.BasicSettings;
	}

	float GetTimeSinceGrindingStopped() const
	{
		return Time::GetGameTimeSince(TimestampGrindingStopped);
	}

	float GetTimeSinceGrindingStarted() const
	{
		return Time::GetGameTimeSince(TimestampGrindingStarted);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		TargetGrindSplineData.Reset();
		ValidNearbyGrindSplines.Reset();
		GrindSplineCooldowns.Reset();
		PreviousGrindSpline = nullptr;
		ActorsInActiveSystem.Reset();
		bIsHorizontallyLocked = false;
		bStickInputOnlyBrakeLock = false;
		CurrentSpeed = 0.f;
	}
}

struct FGrindSplineCooldown
{
	AGrindspline GrindSpline;
	float Cooldown = 0.f;

	FGrindSplineCooldown(AGrindspline InGrindSpline, float InCooldown = 0.f)
	{
		GrindSpline = InGrindSpline;
		Cooldown = InCooldown;
	}

	bool opEquals(AGrindspline InGrindSpline)
	{
		return InGrindSpline == GrindSpline;
	}

	bool opEquals(FGrindSplineCooldown InGrindSplineCooldown)
	{
		return InGrindSplineCooldown.GrindSpline == GrindSpline;
	}
}

struct FGrindSplineData
{	
	UPROPERTY()
	FHazeSplineSystemPosition SystemPosition;
	AGrindspline GrindSpline;

	FGrindSplineData(AGrindspline InGrindSpline, FHazeSplineSystemPosition InSystemPosition)
	{
		GrindSpline = InGrindSpline;
		SystemPosition = InSystemPosition;
	}

	FGrindSplineData(AGrindspline InGrindSpline, UHazeSplineComponentBase SplineComp, float Distance, bool bForward)
	{
		FHazeSplineSystemPosition InSystemPosition;
		InSystemPosition.FromData(SplineComp, Distance, bForward);

		GrindSpline = InGrindSpline;
		SystemPosition = InSystemPosition;
	}

	// Generate data based off of the closest position to a world location
	FGrindSplineData(AGrindspline InGrindSpline, FVector FromLocation)
	{
		FHazeSplineSystemPosition InSystemPosition = InGrindSpline.Spline.GetPositionClosestToWorldLocation(FromLocation, true);

		GrindSpline = InGrindSpline;
		SystemPosition = InSystemPosition;
	}

	FVector GetHeightOffsetedWorldLocation() const property
	{
		if (!SystemPosition.IsOnValidSpline())
			return FVector::ZeroVector;

		return SystemPosition.WorldLocation + SystemPosition.WorldUpVector * GrindSpline.HeightOffset;
	}

	bool ReverseTowardsTravelDirection()
	{
		if (GrindSpline.TravelDirection == EGrindSplineTravelDirection::Bidirectional)
			return false;
	
		EGrindSplineTravelDirection WantedTravelDirection = SystemPosition.IsForwardOnSpline() ? EGrindSplineTravelDirection::Forwards : EGrindSplineTravelDirection::Backwards;
		if (WantedTravelDirection != GrindSpline.TravelDirection)
		{
			SystemPosition.Reverse();
			return true;
		}		

		return false;
	}

	// Reverse towards the direction, only if travel direction allows
	FVector ReverseTowardsDirection(FVector Direction)
	{
		float Dot = Direction.DotProduct(SystemPosition.WorldForwardVector);

		// Already facing the correct direction, no need to reverse
		if (Dot > 0.f)
			return SystemPosition.WorldForwardVector;

		// Facing the wrong direction and it is allowed to swap
		if (GrindSpline.TravelDirection == EGrindSplineTravelDirection::Bidirectional)
			SystemPosition.Reverse();

		return SystemPosition.WorldForwardVector;
	}

	void Reset()
	{
		GrindSpline = nullptr;
		SystemPosition = FHazeSplineSystemPosition();
	}	

	bool opEquals(AGrindspline OtherGrindSpline)	
	{
		return GrindSpline == OtherGrindSpline;
	}

	bool opEquals(FGrindSplineData OtherGrindSplineLocationData)	
	{
		return GrindSpline == OtherGrindSplineLocationData.GrindSpline;
	}

	bool IsValid() const
	{
		return GrindSpline != nullptr && GrindSpline.bGrindingAllowed;
	}
};
