import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobSettings;
import Vino.Movement.Components.MovementComponent;

import Vino.Camera.Components.CameraDetacherComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Peanuts.Spline.SplineComponent;

UCLASS(Abstract)
class AParentBlob : AHazeCharacter
{
	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;
	default CrumbComp.SyncIntervalType = EHazeCrumbSyncIntervalType::VeryHigh;
	default CrumbComp.IncludeCustomParamsInActorReplication(FVector::ZeroVector, FRotator::ZeroRotator, this);
	default ReplicateAsPlayerCharacter();

	UPROPERTY()
	UParentBlobSettings DefaultSettings;
	UParentBlobSettings Settings;

	/**
	 * This is the current actual wanted movement direction in world space
	 * that the parent blob will be using per player.
	 */
	UPROPERTY()
	TPerPlayer<FVector> PlayerMovementDirection;

	/**
	 * This is the raw input that the players are giving,
	 * which is synced ASAP regardless of extra delays.
	 * This is NOT lerped, so it will be very choppy!
	 */
	TPerPlayer<FVector2D> PlayerRawInput;

	UPROPERTY(NotEditable)
	FVector2D CodyDesiredDirection;
	UPROPERTY(NotEditable)
	FVector2D MayDesiredDirection;

	UPROPERTY(NotEditable)
	FVector2D CodyCurrentMovement;
	UPROPERTY(NotEditable)
	FVector2D MayCurrentMovement;

	bool bBrothersMovementActive = false;

	FVector DesiredVelocity = FVector::ZeroVector;

	FVector DesiredForwardDirecton = FVector::ForwardVector;
	UHazeSplineComponent DesiredForwardDirectionSpline;

	UFUNCTION()
	void SetForwardDirectionSpline(AHazeActor Actor)
	{
		if (Actor == nullptr)
			return;

		UHazeSplineComponent SplineComp = UHazeSplineComponent::Get(Actor);
		if (SplineComp == nullptr)
			return;

		DesiredForwardDirectionSpline = SplineComp;
	}

	UFUNCTION()
	void ClearForwardDirectionSpline()
	{
		DesiredForwardDirectionSpline = nullptr;
	}

	UFUNCTION(BlueprintPure)
	bool HasAnyDirectionInput()
	{
		if (IsMovementInputOpposed())
			return false;

		for (const FVector& Input : PlayerMovementDirection)
		{
			if (Input.Size() > 0.1f)
				return true;
		}
		return false;
	}

	UFUNCTION(BlueprintPure)
	bool IsMovementInputOpposed()
	{
		for (const FVector& Input : PlayerMovementDirection)
		{
			float Size = Input.Size();
			if (Size < 0.1f)
				return false;
		}

		FVector Dir0 = PlayerMovementDirection[0].GetSafeNormal();
		FVector Dir1 = PlayerMovementDirection[1].GetSafeNormal();
		
		if (Dir0.DotProduct(Dir1) < 0.f)
			return true;

		return false;
	}

	UFUNCTION(BlueprintPure)
	float GetOpposeValue()
	{
		FVector Dir0 = PlayerMovementDirection[0].GetSafeNormal();
		FVector Dir1 = PlayerMovementDirection[1].GetSafeNormal();
		
		float Dot = Dir0.DotProduct(Dir1);

		if (Dot == 0.f)
			return 0.f;

		return FMath::GetMappedRangeValueClamped(FVector2D(-1.f, 1.f), FVector2D(1.f, 0.f), Dot);
	}

	UFUNCTION(BlueprintPure)
	bool BothPlayersMoving()
	{
		if (IsMovementInputOpposed())
			return false;

		for (const FVector& Input : PlayerMovementDirection)
		{
			if (Input.Size() == 0.f)
				return false;
		}
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp.Setup(CapsuleComponent);

		ApplyDefaultSettings(DefaultSettings);
		Settings = UParentBlobSettings::GetSettings(this);
	}

    void SendAnimationRequest(const FHazeFrameMovement& MoveData, FName AnimationRequestTag, FName SubAnimationRequestTag = NAME_None)
    {        
        FHazeRequestLocomotionData AnimationRequest;
        AnimationRequest.LocomotionAdjustment.DeltaTranslation = MoveData.MovementDelta;
        AnimationRequest.LocomotionAdjustment.WorldRotation = MoveData.Rotation;
 		AnimationRequest.WantedVelocity = MoveData.Velocity;
        AnimationRequest.WantedWorldTargetDirection = MoveData.MovementDelta;
        AnimationRequest.WantedWorldFacingRotation = MoveComp.GetTargetFacingRotation();
		AnimationRequest.MoveSpeed = MoveComp.MoveSpeed;

		if (MoveComp.IsGrounded())
			AnimationRequest.WantedVelocity.Z = 0.f;
		
		AnimationRequest.AnimationTag = AnimationRequestTag;
		AnimationRequest.SubAnimationTag = SubAnimationRequestTag;

		RequestLocomotion(AnimationRequest);
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector DesiredRight;

		if (DesiredForwardDirectionSpline != nullptr)
		{
			FVector ClosestSplineLoc;
			float ClosestSplineDistance = 0.f;
			DesiredForwardDirectionSpline.FindDistanceAlongSplineAtWorldLocation(ActorLocation, ClosestSplineLoc, ClosestSplineDistance);

			FVector ClosestSplineForward = DesiredForwardDirectionSpline.GetDirectionAtDistanceAlongSpline(ClosestSplineDistance, ESplineCoordinateSpace::World);
			ClosestSplineForward = Math::ConstrainVectorToPlane(ClosestSplineForward, MoveComp.WorldUp);
			DesiredForwardDirecton = ClosestSplineForward;

			FVector ClosestSplineRight = DesiredForwardDirectionSpline.GetRightVectorAtDistanceAlongSpline(ClosestSplineDistance, ESplineCoordinateSpace::World);
			ClosestSplineRight = Math::ConstrainVectorToPlane(ClosestSplineRight, MoveComp.WorldUp);
			DesiredRight = ClosestSplineRight;
		}
		else
		{
			FRotator CameraRot = Game::GetMay().ViewRotation;
			CameraRot.Roll = 0.f;
			FVector CameraForward = CameraRot.ForwardVector;
			CameraForward = Math::ConstrainVectorToPlane(CameraForward, MoveComp.WorldUp);
			DesiredForwardDirecton = CameraForward;

			DesiredRight = CameraRot.RightVector;
			DesiredRight = Math::ConstrainVectorToPlane(DesiredRight, MoveComp.WorldUp);
		}

		// Desired direction always comes from raw input,
		// that way the arm pointing updates immediately
		for (auto Player : Game::Players)
		{
			// Update current movement that the player is doing
			FVector2D& CurrentMovement = Player.IsCody() ? CodyCurrentMovement : MayCurrentMovement;
			FVector MovementDirection = PlayerMovementDirection[Player];
			CurrentMovement.X = DesiredRight.DotProduct(MovementDirection);
			CurrentMovement.Y = DesiredForwardDirecton.DotProduct(MovementDirection);

			// Update desired direction (arm pointing)
			FVector2D& DesiredDirection = Player.IsCody() ? CodyDesiredDirection : MayDesiredDirection;
			FVector2D RawInput = PlayerRawInput[Player];
			FVector2D WantedDirection = FVector2D(RawInput.Y, RawInput.X);
			if (Player.HasControl())
			{
				DesiredDirection = WantedDirection;
			}
			else
			{
				// On the player's remote, do some minor lerping here so
				// the direction of the hand isn't so choppy.
				if (WantedDirection.Equals(DesiredDirection, 0.1f))
				{
					DesiredDirection = WantedDirection;
				}
				else if (WantedDirection.IsNearlyZero() || DesiredDirection.IsNearlyZero())
				{
					DesiredDirection.X = FMath::FInterpConstantTo(DesiredDirection.X, WantedDirection.X, DeltaTime, 5.f);
					DesiredDirection.Y = FMath::FInterpConstantTo(DesiredDirection.Y, WantedDirection.Y, DeltaTime, 5.f);
				}
				else
				{
					FQuat FromRot = FRotator::MakeFromX(FVector(DesiredDirection.X, DesiredDirection.Y, 0.f).GetSafeNormal()).Quaternion();
					FQuat ToRot = FRotator::MakeFromX(FVector(WantedDirection.X, WantedDirection.Y, 0.f).GetSafeNormal()).Quaternion();
					FQuat ResultRot = FMath::QInterpConstantTo(FromRot, ToRot, DeltaTime, PI);
					FVector ResultForward = ResultRot.ForwardVector;

					float FromMag = DesiredDirection.Size();
					float ToMag = WantedDirection.Size();
					float ResultMag = FMath::FInterpConstantTo(FromMag, ToMag, DeltaTime, 5.f);
					ResultForward.GetClampedToMaxSize(ResultMag);

					DesiredDirection.X = ResultForward.X;
					DesiredDirection.Y = ResultForward.Y;
				}
			}
		}
	}

	void UpdatePlayerMovementDirection(AHazePlayerCharacter Player, FVector2D RawInput)
	{
		FRotator CameraRot = Game::GetMay().ViewRotation;

		FVector Forward = CameraRot.ForwardVector.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		FVector Up = MoveComp.WorldUp;
		FVector Right = Up.CrossProduct(Forward) * FMath::Sign(ControlRotation.UpVector.DotProduct(Up));

		PlayerMovementDirection[Player] = (Forward * RawInput.X) + (Right * RawInput.Y);
	}
};