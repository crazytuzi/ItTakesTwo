import Peanuts.Animation.AnimationStatics;
import Peanuts.Animation.Features.LocomotionFeatureGrind;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.GrindSettings;
import Vino.Movement.Grinding.Capabilities.CharacterGrindingTransferComponent;
import Vino.Movement.Grinding.GrindingInteractionRegion;

class UGrindingAnimInstance : UHazeFeatureSubAnimInstance
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UUserGrindComponent GrindingComponent;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UHazeCharacterSkeletalMeshComponent PlayerMesh;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FRotator MeshRotation;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FRotator GrappleFlyingRotation;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FVector2D BlendspaceValues;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FVector2D StickInput;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bSkipEnter;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bPlayGrindTurnAround;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bPlayTurnAroundBoost;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FRotator ActorRotation;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FRotator Banking;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bEnableBanking;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bGrindTransferAvaliable;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FVector2D GrindTransferBlendspaceValues;

	UPROPERTY()
	bool bGrappleEnter;

	UPROPERTY()
	bool bPlayJumpAnimation;

	UPROPERTY()
	bool bRotateCharacterToFollowSpline;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bDashRequested;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bExitDash;

	const float DEFAULT_BLEND_TIME = 0.06;

	float CustomBlendTime;
	UCharacterGrindingTransferComponent GrindTransferComponent;

	// On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;

		GrindingComponent = Cast<UUserGrindComponent>(OwningActor.GetComponentByClass(UUserGrindComponent::StaticClass()));
		GrindTransferComponent = Cast<UCharacterGrindingTransferComponent>(OwningActor.GetComponentByClass(UCharacterGrindingTransferComponent::StaticClass()));

		Player = Cast<AHazePlayerCharacter>(OwningActor);
		if (Player != nullptr)
			PlayerMesh = Player.Mesh;

		ActorRotation = OwningActor.ActorRotation;

		bGrappleEnter = (GetLocomotionSubAnimationTag() == n"Grapple");
		bSkipEnter = GetAnimBoolParam(n"SkipGrindEnter", true);

		bPlayJumpAnimation = false;

		CustomBlendTime = GetAnimFloatParam(n"BlendToGrind", true, -1.f);

		bEnableBanking = true;

		Banking.Roll = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		if (CustomBlendTime != -1)
			return CustomBlendTime;
		else if (bSkipEnter)
			return 0.35f;
		else if (bGrappleEnter)
			return 0.f;
		return DEFAULT_BLEND_TIME;
	}

	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Player == nullptr)
			return;

		const FName SubAnimationTag = GetLocomotionSubAnimationTag();

		if (bGrappleEnter)
		{
			GrappleFlyingRotation = GetSwimmingRotationValue(OwningActor, GrappleFlyingRotation, DeltaTime, 99.f);
			bRotateCharacterToFollowSpline = false;
			return;
		}

		if (SubAnimationTag == n"Jump")
			bPlayJumpAnimation = true;
		bPlayGrindTurnAround = (SubAnimationTag == n"TurnAround");
		bPlayTurnAroundBoost = (SubAnimationTag == n"TurnAroundCompleted");
		if (bPlayTurnAroundBoost)
			Banking.Roll *= -1;
		bDashRequested = (SubAnimationTag == n"Dash");

		bRotateCharacterToFollowSpline = !bPlayJumpAnimation;

		// Get blendspace values
		FRotator Rotation = (OwningActor.ActorRotation - ActorRotation);
		Rotation.Normalize();
		ActorRotation = OwningActor.ActorRotation;

		const float DeltaTurnValue = ((Rotation.Yaw / DeltaTime));
		
		BlendspaceValues.X = FMath::Clamp(DeltaTurnValue / 70.f, -1.f, 1.f);
		BlendspaceValues.Y = GrindingComponent.SpeedPercentage;

		Banking.Roll = FMath::FInterpTo(Banking.Roll, BlendspaceValues.X * 25.f, DeltaTime, 2.f);

		const FVector MoveInput = ActorRotation.UnrotateVector(GrindingComponent.MoveInput);
		StickInput = FVector2D(MoveInput.X, MoveInput.Y);

		if (bRotateCharacterToFollowSpline)
			MeshRotation = Math::MakeRotFromXZ(GrindingComponent.ActiveGrindSplineData.SystemPosition.WorldForwardVector, GrindingComponent.ActiveGrindSplineData.SystemPosition.WorldUpVector);

		const FVector TransferGrindTargetLocation = GrindTransferComponent.GetHeightOffsetedEvaluationWorldLocation();
		bGrindTransferAvaliable = (TransferGrindTargetLocation != FVector::ZeroVector);
		if (bGrindTransferAvaliable)
		{
			// Calculate the look direction based on the target location
			FTransform GrindTransferTransform;
			GrindTransferTransform.Location = TransferGrindTargetLocation;
			GrindTransferTransform.SetToRelativeTransform(OwningActor.ActorTransform);
			
			GrindTransferTransform.Location = FVector(0.f, GrindTransferTransform.Location.Y, GrindTransferTransform.Location.Z);
			
			FVector TransferTargetDirection = GrindTransferTransform.Location;
			TransferTargetDirection.Normalize();

			if (StickInput.Y < 0.f && TransferTargetDirection.Y < 0.f ||
				StickInput.Y > 0.f && TransferTargetDirection.Y > 0.f)
			{
				GrindTransferBlendspaceValues.X = (StickInput.Y);
			}
			else
			{
				bGrindTransferAvaliable = false;
				GrindTransferBlendspaceValues.X = 0.f;
			}
			GrindTransferBlendspaceValues.Y = TransferTargetDirection.Z;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (LocomotionAnimationTag == n"GrindTransfer")
		{
			SetAnimVectorParam(n"RootRotation", FVector(MeshRotation.Pitch, MeshRotation.Yaw, MeshRotation.Roll));
		}
	}

	UFUNCTION()
	void AnimNotify_DashFinishedPlaying()
	{
		if (GetLocomotionSubAnimationTag() != n"Dash")
			bExitDash = true;
	}

	UFUNCTION()
	void AnimNotify_LeftDashState()
	{
		bExitDash = false;
	}


}
