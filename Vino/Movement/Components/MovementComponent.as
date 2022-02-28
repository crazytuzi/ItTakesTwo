import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackComponent;
import Vino.Movement.MovementSettings;
import Peanuts.Movement.DefaultDepenetrationSolver;
import Vino.Movement.Jump.CharacterJumpSettings;

event void FOnJumpActivated(FVector InheritedHorizontal, FVector InheritedVertical);

class UHazeMovementComponent : UHazeBaseMovementComponent
{
	UPROPERTY(Category = "HazeMovement", BlueprintHidden)
	UMovementSettings DefaultMovementSettings = nullptr;

    UPROPERTY(BlueprintReadOnly, NotEditable, Category = "HazeMovement")
    float CurrentAirTime = 0.f;
	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "HazeMovement")
    float LastAirTime = 0.f;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "HazeMovement")
    float CurrentGroundTime = 0.f;
	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "HazeMovement")
    float LastGroundTime = 0.f;
	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "HazeMovement")
    float NegativeVerticalAirTime = 0.f;
	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "HazeMovement")
    float LastNegativeVerticalAirTime = 0.f;

	FVector JumpOffInheritedVerticalVelocity = FVector::ZeroVector;
	FVector JumpOffInheritedHorizontalVelocity = FVector::ZeroVector;
 
    FHazeRequestLocomotionData CurrentRequestData;
    FName DebugFinalizer = NAME_None;

	protected float DefaultMovementSpeed = 0.f;

	UMovementSettings ActiveSettings = nullptr;
	UCharacterJumpSettings JumpSettings;

	FOnJumpActivated OnJumpActivated;

	FName ControlSideDefaultCollisionSolver = n"DefaultCharacterCollisionSolver";
	FName RemoteSideDefaultCollisionSolver = n"DefaultCharacterRemoteCollisionSolver";
	FName ControlSideDefaultMoveWithCollisionSolver = n"DefaultCharacterMoveWithCollisionSolver";
	FName RemoteSideDefaultMoveWithCollisionSolver = n"DefaultCharacterRemoteCollisionSolver";

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        UseCollisionSolver(ControlSideDefaultCollisionSolver, RemoteSideDefaultCollisionSolver);
		UseMoveWithCollisionSolver(ControlSideDefaultMoveWithCollisionSolver, RemoteSideDefaultMoveWithCollisionSolver);

		if (DefaultMovementSettings != nullptr)
		{
			HazeOwner.ApplyDefaultSettings(DefaultMovementSettings);
		}
		
		ActiveSettings = UMovementSettings::GetSettings(HazeOwner);
		JumpSettings = UCharacterJumpSettings::GetSettings(HazeOwner);
		DefaultMovementSpeed = ActiveSettings.MoveSpeed;
    }

	UFUNCTION(BlueprintOverride)
    void OnCollisionSolverCreate(UHazeCollisionSolver CreatedSolver)
	{
	}

    UFUNCTION(BlueprintOverride)
    void OnPreImpactsUpdated(FMovementCollisionData NewImpacts)
    {
        const FMovementCollisionData CurrentImpacts = GetPreviousImpacts();
        if (NewImpacts.UpImpact.Actor != CurrentImpacts.UpImpact.Actor)
            CheckAndCallImpactCallback(CurrentImpacts.UpImpact, NewImpacts.UpImpact, EImpactDirection::UpImpact);
        
        if (NewImpacts.ForwardImpact.Actor != CurrentImpacts.ForwardImpact.Actor)
            CheckAndCallImpactCallback(CurrentImpacts.ForwardImpact, NewImpacts.ForwardImpact, EImpactDirection::ForwardImpact);

        if (NewImpacts.DownImpact.Actor != CurrentImpacts.DownImpact.Actor)
            CheckAndCallImpactCallback(CurrentImpacts.DownImpact, NewImpacts.DownImpact, EImpactDirection::DownImpact);
    }

    void CheckAndCallImpactCallback(const FHitResult& PreviousHit, const FHitResult& NewHit, EImpactDirection Direction)
    {
        // Call the previous Hits Callbacks
        if (PreviousHit.Component != nullptr)
        {
            if (PreviousHit.Actor != nullptr)
            {
                UActorImpactedCallbackComponent CallbackComponent = Cast<UActorImpactedCallbackComponent>(PreviousHit.Actor.GetComponentByClass(UActorImpactedCallbackComponent::StaticClass()));
                if (CallbackComponent != nullptr)
                {
                    AHazePlayerCharacter PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
                    if (PlayerOwner != nullptr)
                        CallbackComponent.ActorImpactEndedByPlayer(PlayerOwner, Direction);

                    CallbackComponent.ActorImpactEnded(HazeOwner, Direction);
                }
            }
        }

        // Call new hit Callbacks
        if (NewHit.Component == nullptr)
            return;

        if (NewHit.Actor == nullptr)
            return;

        UActorImpactedCallbackComponent CallbackComponent = Cast<UActorImpactedCallbackComponent>(NewHit.Actor.GetComponentByClass(UActorImpactedCallbackComponent::StaticClass()));
        if (CallbackComponent != nullptr)
        {
            AHazePlayerCharacter PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
            if (PlayerOwner != nullptr)
                CallbackComponent.ActorImpactedByPlayer(PlayerOwner, NewHit, Direction);

            CallbackComponent.ActorImpacted(HazeOwner, NewHit, Direction);
        }
    }

	UFUNCTION()
	float GetDefaultSpeed() property
	{
		return DefaultMovementSpeed;
	}

	UFUNCTION(BlueprintOverride)
	float GetMoveSpeed() const property
	{
		return ActiveSettings.MoveSpeed;
	}

	UFUNCTION()
	float GetHorizontalAirSpeed() const property
	{
		return ActiveSettings.HorizontalAirSpeed;
	}

	UFUNCTION(BlueprintOverride)
	float GetRotationSpeed() const property
	{
		if(IsGrounded())
		{
			return ActiveSettings.GroundRotationSpeed;
		}
		else
		{
			return ActiveSettings.AirRotationSpeed;
		}
	}

	UFUNCTION(BlueprintOverride)
	float GetMaxFallSpeed() const property
	{
		return ActiveSettings.ActorMaxFallSpeed;
	}

	UFUNCTION(BlueprintOverride)
	float GetStepAmount(float WantedAmount) const property
	{
		return WantedAmount < 0.f ? ActiveSettings.StepUpAmount : WantedAmount;
	}

	UFUNCTION(BlueprintOverride)
	float GetWalkableAngle() const property
	{
		return ActiveSettings.WalkableSlopeAngle;
	}

	UFUNCTION(BlueprintOverride)
	float GetCeilingAngle() const property
	{
		return ActiveSettings.CeilingAngle;
	}

	UFUNCTION(BlueprintOverride)
	float GetGravityMultiplier() const property
	{
		return -ActiveSettings.GravityMultiplier;
	}

    UFUNCTION()
    bool IsMovingUpwards(float MovingFasterThenSpeed = 0.f)
    {
        return Velocity.DotProduct(WorldUp) > 0.f && Velocity.ConstrainToDirection(WorldUp).SizeSquared() > FMath::Square(MovingFasterThenSpeed);
    }

    UFUNCTION()
    bool IsMovingDownwards(float MovingFasterThenSpeed = 0.f)
    {
        return Velocity.DotProduct(WorldUp) < 0.f && Velocity.ConstrainToDirection(WorldUp).SizeSquared() > FMath::Square(MovingFasterThenSpeed);
    }

    bool LineTraceGround(FVector Location, FHitResult& OutHit, float DistanceToTrace = 100.f, float DebugDraw = -1)
    {
        const FVector TraceTo = Location + -WorldUp * DistanceToTrace;
		FHazeHitResult Hit;
        LineTrace(Location, TraceTo, Hit, DebugDraw);
		OutHit = Hit.FHitResult;
		return OutHit.bBlockingHit;
    }

	bool TraceGround(FVector Location, FHitResult& OutHit, float DistanceToTrace = -1)
    {
        const FVector TraceTo = Location + -WorldUp * GetStepAmount(DistanceToTrace);
		FVector FoundLocation;
		FHazeHitResult Hit;
        SweepTrace(Location, TraceTo, Hit);
		OutHit = Hit.FHitResult;
		return OutHit.bBlockingHit;
    }

	float GetNormalizedVelocity() const property
	{
		return FMath::Clamp((Velocity.Size() / MoveSpeed), 0.f, 1.f);
	}

	// How much difference there is between current and previous velocity. -- To get between current frame and last you need to wait for after postphysics.
	float GetVelocityDelta() const property
	{
		return Velocity.Size() - PreviousVelocity.Size();
	}

	// How much rotation difference this is between this and previous frame. -- Need to be called after the characers has moved to get correct values.
	float GetRotationDelta() const property
	{
		return Math::DotToRadians(PreviousOwnerRotation.ForwardVector.DotProduct(OwnerRotation.ForwardVector));
	}

	FVector2D GetLocalSpace2DVelocity() const property
	{
		FVector LocalSpaceVelocity = OwnerRotation.UnrotateVector(Velocity);
		return FVector2D(LocalSpaceVelocity.X, LocalSpaceVelocity.Y);
	}

    UFUNCTION(BlueprintOverride)
    void DebugDraw()
    {
        DebugRenderShape(OwnerLocation, FLinearColor::White);
    }

	bool IsWithinJumpGroundedGracePeriod(float GracePeriodOverride = -1.f)
	{
		float GracePeriod = JumpSettings.GroundedGracePeriod;

		if (GracePeriodOverride >= 0.f)
			GracePeriod = GracePeriodOverride;

		if (CurrentAirTime <= GracePeriod)
			return true;

		return false;
	}

	void OnJumpTrigger(FVector InheritedHorizontalVelocity, float InheritedVerticalSpeed)
	{
		JumpOffInheritedVerticalVelocity = WorldUp * InheritedVerticalSpeed;
		JumpOffInheritedHorizontalVelocity = InheritedHorizontalVelocity;

		OnJumpActivated.Broadcast(InheritedHorizontalVelocity, JumpOffInheritedVerticalVelocity);
	}

	void UpdateAirTime(float DeltaTime)
	{
		CurrentAirTime += DeltaTime;
		LastAirTime = CurrentAirTime;

		LastNegativeVerticalAirTime = LastNegativeVerticalAirTime;		
		NegativeVerticalAirTime += DeltaTime;
		if (VerticalVelocity >= 0.f)
			NegativeVerticalAirTime = 0.f;
	}

	void OnGroundedReset()
	{
		CurrentAirTime = 0.f;
		NegativeVerticalAirTime = 0.f;

		JumpOffInheritedHorizontalVelocity = FVector::ZeroVector;
		JumpOffInheritedVerticalVelocity = FVector::ZeroVector; 
	}

	void UpdateGroundTime(float DeltaTime)
	{
		CurrentGroundTime += DeltaTime;
		LastGroundTime = CurrentGroundTime;
	}

	void ResetGroundTime()
	{
		CurrentGroundTime = 0.f;
	}

	bool ThisFrameIsGrounded() const
	{
		if(CanCalculateMovement())
			return false;
		return IsGrounded();
	}

	bool ThisFrameIsAirBorne() const
	{
		if(CanCalculateMovement())
			return false;
		return IsAirborne();
	}
};
