
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideComponent;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideSettings;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.WallSlide.WallSlideNames;
import Vino.Movement.Capabilities.WallSlide.WallCheckFunctions;

class UCharacterWallSlideEvalutationCapability : UHazeCapability
{
	default RespondToEvent(MovementActivationEvents::Airbourne);
	default RespondToEvent(WallslideActivationEvents::Cooldown);
	default RespondToEvent(WallslideActivationEvents::JumpCheck);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::WallSlide);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::WallSlideEvaluation);

	default CapabilityDebugCategory = CapabilityTags::Movement;

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 50;

	UHazeMovementComponent MoveComp;
	UCharacterWallSlideComponent WallData;

	FCharacterWallSlideSettings Settings;
	FWallSlideChecker Checker;

	float TargetAqcuireTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		ensure(MoveComp != nullptr);

		WallData = UCharacterWallSlideComponent::GetOrCreate(Owner);

		Checker.MoveComp = MoveComp;
		Checker.WallDataComp = WallData;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick_EventBased()
	{
		if (MoveComp.IsGrounded())
			WallData.InvalidateJumpOffData();

		if (!WallData.JumpOffData.IsValid())
			ConsumeAction(WallslideActivationEvents::JumpCheck);

		WallData.TickDisableTimer(Owner.ActorDeltaSeconds);
		if (!WallData.WallSlidingIsDisabled())
			ConsumeAction(WallslideActivationEvents::Cooldown);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.IsAirborne())
			return EHazeNetworkActivation::DontActivate;

		if (WallData.WallSlidingIsDisabled())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.IsAirborne())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (WallData.WallSlidingIsDisabled())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Parans)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Parans)
	{
		WallData.StopSliding(EWallSlideLeaveReason::BlockedOrGrounded);

		TargetAqcuireTime = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName BlockTag)
	{
		WallData.StopSliding(EWallSlideLeaveReason::BlockedOrGrounded);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (WallData.ShouldSlide() || WallData.IsSliding())
		{
			// We are either sliding and want to make sure we are still infront of a wall.
			// Or we want to slide but something interupted us from starting, make sure that starting to slide is still valid.
			FHazeHitResult TargetHit;
			if (DoesCharacterStillWantToSlide(TargetHit))
			{
				WallData.UpdateTarget(TargetHit);
			}
			else
			{
				if (WallData.IsSliding())
					WallData.StopSliding(EWallSlideLeaveReason::InvalidSlideWall);
				else
					WallData.InvalidatePendingSlide();
			}
		}
		else
		{
			// Check for impact.
			FHazeHitResult WallHit;
			if (EvaluteWallImpact(MoveComp.Impacts.ForwardImpact, WallHit))
				WallData.SetSlidingTarget(WallHit);
		}
	}

	bool EvaluteWallImpact(FHitResult WallImpact, FHazeHitResult& OutWallHit) const
	{
		if (WallImpact.Component == nullptr)
			return false;

		// Check Input or velocity towards wall
		const FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
		const FVector HorizontalVelocity = MoveComp.PreviousVelocity.ConstrainToPlane(MoveComp.WorldUp);

		FVector CheckVecktor = HorizontalVelocity.GetSafeNormal();
		if (!IsActioning(WallSlideActions::HorizontalJump) && Input.SizeSquared() > Settings.InputMinSizeSquared)
			CheckVecktor = Input.GetSafeNormal();

		FVector WallNormal = WallImpact.ImpactNormal;
		
		if (CheckVecktor.IsNearlyZero())
			return false;

		if (CheckVecktor.DotProduct(WallNormal) >= 0.f)
			return false;
		
		// Check if we are infront a solid wall
		FTransform WallHitRotationTransform = Math::ConstructTransformWithCustomRotation(MoveComp.OwnerLocation, -WallNormal, MoveComp.WorldUp);
		if (!Checker.IsFrontSolid(WallHitRotationTransform, OutWallHit))
			return false;

		return true;
	}

	bool DoesCharacterStillWantToSlide(FHazeHitResult& OutHit) const
	{
		FVector WallNormal;
		if (WallData.IsSliding())
		{
			WallNormal = WallData.NormalPointingAwayFromWall;
		}
		else
		{
			// If we haven't started sliding yet then we do a time check.
			// TODO:
			WallNormal = WallData.TargetWallNormal;
		}

		// Make sure we are still infront a solid wall.
		FHazeHitResult WallHit;
		FTransform WallHitRotationTransform = Math::ConstructTransformWithCustomRotation(MoveComp.OwnerLocation, -WallNormal, MoveComp.WorldUp);
		if (Checker.IsFrontSolid(WallHitRotationTransform, WallHit))
		{
			// If we are still infront a solid wall but have a new target we need to update the target.
			OutHit = WallHit;
			return true;			
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString Output;
		Output = "DisableTimer: " + WallData.DisabledTimer + "\n";
		Output += "JumpUpCounterTimer: " + WallData.JumpUpCounterTimer + "\n";
		Output += "JumpUpCounterTimer: " + WallData.JumpedUpCounter;

		return Output;
	}
}
