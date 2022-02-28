import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideSettings;
import Vino.Movement.Components.WallSlideCallbackComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.WallSlide.WallSlideNames;

enum EWallSlideLeaveReason
{
	Cancelled,
	Jumped,
	JumpedUp,
	InvalidSlideWall, // We either ran out of wall to slide on or the wall changed to a invalid slide state.
	BlockedOrGrounded,
}

enum EWallSlideJumpOffType
{
	Vertical,
	Horizontal,
}

enum EWallSlideStartType
{
	Normal,
	Dash,
	None,
}

struct FWallSlideJumpOffData
{
	FVector JumpOffLocation = FVector::ZeroVector;
	FVector WallNormal = FVector::ZeroVector;
	EWallSlideJumpOffType Type;

	void Reset()
	{
		JumpOffLocation = FVector::ZeroVector;
		WallNormal = FVector::ZeroVector;
	}
	
	bool IsValid() const
	{
		return !WallNormal.IsZero();
	}
}

class UCharacterWallSlideComponent : UActorComponent
{
	// Only used on the control side.
	UPrimitiveComponent PrimitiveWeWantToSlideOn = nullptr;
	EWallSlideStartType WantedStartType = EWallSlideStartType::None;

	// Is nullptr if sliding on a wall that is not networked.
	UPrimitiveComponent PrimitiveSlidingOn = nullptr;
	FVector WorldOrRelativeNormal = FVector::ZeroVector;

	FHazeHitResult TargetWallHit;
	FHazeHitResult ActiveWallHit;

	bool bSlidingIsActive = false;

	float DisabledTimer = 0.f;
	float JumpUpCounterTimer = 0.f;
	int JumpedUpCounter = 0;

	FCharacterWallSlideSettings Settings;

	AHazePlayerCharacter PlayerOwner;
	FWallSlideJumpOffData JumpOffData;

	UWallSlideDynamicSettings DynamicSettings;

	UPROPERTY()
	TArray<UObject> ActiveWallJumpVolumes;

	// Used in the ABP for when the player fits the criteria for dashing by pressing A
	UPROPERTY()
	bool bReadyToDash = false;

	UPROPERTY()
	UAkAudioEvent FootSlideStopEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		DynamicSettings = UWallSlideDynamicSettings::GetSettings(PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		bSlidingIsActive = false;
		DisabledTimer = 0.f;
		JumpOffData.Reset();
		JumpedUpCounter = 0;
		JumpUpCounterTimer = 0.f;
	}

	void TickDisableTimer(float DeltaTime)
	{
		if (DisabledTimer > 0.f)
			DisabledTimer = FMath::Max(DisabledTimer - DeltaTime, 0.f);
		
		if (JumpedUpCounter > 0)
		{
			JumpUpCounterTimer -= DeltaTime;
			if (JumpUpCounterTimer <= 0.f)
				JumpedUpCounter = 0;
		}
	}

	bool WallSlidingIsDisabled() const
	{
		return DisabledTimer > 0.f;
	}

	// Get the normal of the wall we want to start sliding on but haven't yet.
	FVector GetTargetWallNormal() const property
	{
		if (!ensure(PrimitiveWeWantToSlideOn != nullptr))
			return FVector::ZeroVector;		
			
		if (PrimitiveWeWantToSlideOn.IsNetworked())
			return PrimitiveWeWantToSlideOn.ComponentQuat.RotateVector(WorldOrRelativeNormal);

		return WorldOrRelativeNormal;
	}

	FVector GetNormalPointingAwayFromWall() const property
	{
		ensure(!WorldOrRelativeNormal.IsNearlyZero());

		// If we are sliding on a wall that is not networked then the normal will be in worldspace.
		// If we are on a networked wall then the normal is relative since we allow it to move.

		if (PrimitiveSlidingOn != nullptr)
			return PrimitiveSlidingOn.ComponentQuat.RotateVector(WorldOrRelativeNormal);

		return WorldOrRelativeNormal;
	}

	void StartSliding(UPrimitiveComponent Primitive, FVector Normal, FHazeHitResult WallHit)
	{		
		if (HasControl())
		{
			// confirm control use using correct data
			ensure(NormalPointingAwayFromWall.Equals(Normal));
			ensure(WantedStartType != EWallSlideStartType::None);
		}
		else
		{
			// Set data synced from crumb
			WorldOrRelativeNormal = Normal;
		}

		bSlidingIsActive = true;
		PrimitiveSlidingOn = Primitive;
		PrimitiveWeWantToSlideOn = nullptr;
		ActiveWallHit = WallHit;

		PlayerOwner.SetCapabilityActionState(WallslideActivationEvents::Wallsliding, EHazeActionState::Active);

		WantedStartType = EWallSlideStartType::None;
		TriggerWallSlideCallback(true, EWallSlideLeaveReason::InvalidSlideWall);
	}

	void SetSlidingTarget(FHazeHitResult WallHit, bool bFromDash = false)
	{
		if (!ensure(HasControl()))
			return;

		if (!ensure(PrimitiveWeWantToSlideOn == nullptr))
			return;

		TargetWallHit = WallHit;
		PrimitiveWeWantToSlideOn = WallHit.Component;
		WorldOrRelativeNormal = WallHit.ImpactNormal;
		WantedStartType = bFromDash ? EWallSlideStartType::Dash : EWallSlideStartType::Normal;

		PlayerOwner.SetCapabilityActionState(WallslideActivationEvents::Wallsliding, EHazeActionState::Active);

		if (PrimitiveWeWantToSlideOn.IsNetworked())
			WorldOrRelativeNormal = PrimitiveWeWantToSlideOn.ComponentQuat.UnrotateVector(WorldOrRelativeNormal);
	}

	void UpdateTarget(FHazeHitResult WallHit)
	{
		ensure(WallHit.bBlockingHit);
		UPrimitiveComponent Primitive = WallHit.Component;
		FVector Normal = WallHit.Normal;

		FQuat ParentRotation = FQuat::Identity;

		if (IsSliding())
		{
			PrimitiveSlidingOn = nullptr;
			if (Primitive != nullptr && Primitive.IsNetworked())
				PrimitiveSlidingOn = Primitive;

			if (PrimitiveSlidingOn != nullptr)
				ParentRotation = PrimitiveSlidingOn.ComponentQuat;

			ActiveWallHit = WallHit;
		}
		else
		{
			ensure(PrimitiveWeWantToSlideOn != nullptr);
			PrimitiveWeWantToSlideOn = Primitive;
			TargetWallHit = WallHit;

			if (PrimitiveWeWantToSlideOn.IsNetworked())
				ParentRotation = PrimitiveWeWantToSlideOn.ComponentQuat;
		}

		WorldOrRelativeNormal = ParentRotation.UnrotateVector(Normal);
	}

	void SetJumpOffData(FVector JumpOffLocation, EWallSlideJumpOffType JumpOffType)
	{
		if (!HasControl())
			return;

		if (!ensure(IsSliding()))
			return;

		JumpOffData.JumpOffLocation = JumpOffLocation;
		JumpOffData.WallNormal = NormalPointingAwayFromWall;
		JumpOffData.Type = JumpOffType;
	}

	bool HasSlidingTarget() const
	{
		return WantedStartType != EWallSlideStartType::None;
	}

	void InvalidateJumpOffData()
	{
		JumpOffData.JumpOffLocation = FVector::ZeroVector;
		JumpOffData.WallNormal = FVector::ZeroVector;
	}

	void InvalidatePendingSlide()
	{
		PlayerOwner.SetCapabilityActionState(WallslideActivationEvents::Wallsliding, EHazeActionState::Inactive);
		PrimitiveWeWantToSlideOn = nullptr;
	}

	void StopSliding(EWallSlideLeaveReason Reason)
	{
		if (Reason == EWallSlideLeaveReason::Cancelled)
			DisabledTimer = Settings.CancelDisableDuration;
		else if (Reason == EWallSlideLeaveReason::JumpedUp)
		{
			DisabledTimer = Settings.JumpUpDisableDuration;		
			JumpedUpCounter += 1;

			if (JumpedUpCounter > Settings.NormalMaxVerticalJumps)
				DisabledTimer += Settings.JumpUpDisableBonusDuration;
			
			JumpUpCounterTimer = DisabledTimer + Settings.JumpUpCounterResetTime;
		}

		PlayerOwner.SetCapabilityActionState(WallslideActivationEvents::Cooldown, EHazeActionState::Active);

		PlayerOwner.SetCapabilityActionState(WallslideActivationEvents::Wallsliding, EHazeActionState::Inactive);
		TriggerWallSlideCallback(false, Reason);

		WantedStartType = EWallSlideStartType::None;
		PrimitiveWeWantToSlideOn = nullptr;
		PrimitiveSlidingOn = nullptr;
		bSlidingIsActive = false;
		bReadyToDash = false;
		WorldOrRelativeNormal = FVector::ZeroVector;	
	}

	void WallSlideEnterDone()
	{
		ensure(WantedStartType == EWallSlideStartType::Dash);
		WantedStartType = EWallSlideStartType::Normal;
	}

	bool ShouldSlide() const
	{
		return PrimitiveWeWantToSlideOn != nullptr;
	}

	bool ShouldDashSlide() const
	{
		return ShouldSlide() && WantedStartType == EWallSlideStartType::Dash;
	}

	bool IsSliding() const
	{
		return bSlidingIsActive;
	}

	void TriggerWallSlideCallback(bool bStartedSliding, EWallSlideLeaveReason LeaveReason)
	{
		if (PrimitiveSlidingOn == nullptr)
			return;

		AHazeActor CallbackActor = Cast<AHazeActor>(PrimitiveSlidingOn.Owner);
		if (CallbackActor == nullptr)
			return;

		UPlayerWallSlidingOnCallbackComponent CallbackComp = UPlayerWallSlidingOnCallbackComponent::Get(CallbackActor);
		if (CallbackComp == nullptr)
			return;

		AHazePlayerCharacter PlayerSliding = Cast<AHazePlayerCharacter>(Owner);
		if (!ensure(PlayerSliding != nullptr))
			return;

		const bool bJumpedOff = LeaveReason == EWallSlideLeaveReason::Jumped || LeaveReason == EWallSlideLeaveReason::JumpedUp;
		if (bStartedSliding)
			CallbackComp.PlayerStartedSlidingOnActor(PlayerSliding, PrimitiveSlidingOn);
		else
			CallbackComp.PlayerStoppedSlidingOnActor(PlayerSliding, PrimitiveSlidingOn, bJumpedOff);
	}

	void EnteredWallJumpVolume(UObject Volume)	
	{
		ActiveWallJumpVolumes.Add(Volume);
	}

	void LeftWallJumpVolume(UObject Volume)
	{
		ActiveWallJumpVolumes.Remove(Volume);
	}

	UFUNCTION(BlueprintPure)
	bool IsInsideWallJumpVolume()
	{
		return ActiveWallJumpVolumes.Num() > 0;
	}
}

