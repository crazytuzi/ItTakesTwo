import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;
import Vino.Movement.Dash.CharacterDashComponent;
import Vino.Movement.Dash.CharacterDashSettings;
import Peanuts.SpeedEffect.SpeedEffectStatics;

class UCharacterGroundPoundDashCapability : UCharacterMovementCapability
{
	default RespondToEvent(GroundPoundEventActivation::Landed);

	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(MovementSystemTags::GroundPound);
	default CapabilityTags.Add(GroundPoundTags::Dash);
	default CapabilityTags.Add(MovementSystemTags::Dash);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 5;
	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter PlayerOwner;
	UCharacterDashComponent DashComp;
	UGroundPoundDashSettings DashSettings;

	float DurationAlpha = 0.f;
	float Deceleration = 0.f;
	FVector Direction;

	UCharacterGroundPoundComponent GroundPoundComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		GroundPoundComp = UCharacterGroundPoundComponent::GetOrCreate(Owner);
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		DashComp = UCharacterDashComponent::GetOrCreate(Owner);
		DashSettings = UGroundPoundDashSettings::GetSettings(PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::MovementDash))
			return EHazeNetworkActivation::DontActivate;

		if (!GroundPoundComp.IsAllowLandedAction(0.f))
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (ActiveDuration >= DashSettings.Duration)
       		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(ActionNames::WeaponAim, this);

		DashComp.DashActiveDuration = 0.f;
		DashComp.bDashActive = true;
		DashComp.bFailedPerfectDashWindow = false;

		GroundPoundComp.ChangeToState(EGroundPoundState::Dashing);

		DurationAlpha = 0.f;
		Deceleration = (DashSettings.EndSpeed - DashSettings.StartSpeed) / DashSettings.Duration;

		Direction = GetAttributeVector(AttributeVectorNames::MovementDirection);
		if (Direction.IsNearlyZero())
			Direction = Owner.ActorForwardVector;
		Direction.Normalize();

		MoveComp.Velocity = FVector::ZeroVector;

		PlayerOwner.PlayForceFeedback(GroundPoundComp.DashForceFeedbackEffect, false, false, n"GroundPoundDash");

		// PlayerOwner.CurrentlyUsedCamera.field
		FHazeCameraBlendSettings Blend;
		Blend.Type = EHazeCameraBlendType::Additive;
		Blend.BlendTime = 0.1f;
		// PlayerOwner.ApplyFieldOfView(5.f, Blend, this, EHazeCameraPriority::Low);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(ActionNames::WeaponAim, this);
		GroundPoundComp.ResetState();
		DashComp.bDashActive = false;
		DashComp.bDashEnded = true;
		DashComp.DashDeactiveDuration = 0.f;

		PlayerOwner.ClearFieldOfViewByInstigator(this, 0.25f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement DashMove = MoveComp.MakeFrameMovement(GroundPoundTags::Dash);

			if (HasControl())
				CalculateControlMove(DashMove, DeltaTime);
			else
				CalculateRemoteMove(DashMove, DeltaTime);

			MoveCharacter(DashMove, n"Dash");
			CrumbComp.LeaveMovementCrumb();

			float FoV = FMath::Lerp(3.f, 0.f, ActiveDuration * 2.5f);

			FHazeCameraBlendSettings Blend;
			Blend.Type = EHazeCameraBlendType::Additive;
			Blend.BlendTime = 0.25f;
			PlayerOwner.ApplyFieldOfView(FoV, Blend, this, EHazeCameraPriority::Low);

			FSpeedEffectRequest SpeedEffect;
			SpeedEffect.Instigator = this;
			SpeedEffect.Value = FMath::GetMappedRangeValueClamped(FVector2D(DashSettings.EndSpeed, DashSettings.StartSpeed), FVector2D(0.f, 1.f), MoveComp.Velocity.Size());
			SpeedEffect.bSnap = false;
			SpeedEffect::RequestSpeedEffect(PlayerOwner, SpeedEffect);
		}	
	}	

	void CalculateControlMove(FHazeFrameMovement& OutMove, float DeltaTime)
	{
		DurationAlpha = Math::Saturate(ActiveDuration / DashSettings.Duration);

		FVector TargetMoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		if (TargetMoveDirection.IsNearlyZero())
			TargetMoveDirection = Owner.ActorForwardVector;
		TargetMoveDirection.Normalize();

		RotateDashDirectionTowardsTarget(DeltaTime, TargetMoveDirection);

		FVector Velocity;
		if (MoveComp.IsGrounded())
		{
			FVector SlopedDirection = Math::ConstrainVectorToSlope(Direction, MoveComp.DownHit.Normal, MoveComp.WorldUp);

			Velocity = SlopedDirection.GetSafeNormal() * GetDashSpeed();				
			OutMove.ApplyVelocity(Velocity);
		}
		else
		{
			Velocity = Direction.GetSafeNormal() * GetDashSpeed();

			OutMove.ApplyVelocity(Velocity);

			FVector VerticalVelocity = MoveComp.VerticalVelocity;
			if (VerticalVelocity.DotProduct(MoveComp.WorldUp) > 0.f)
			{
				if (VerticalVelocity.Size() > DashSettings.AirborneMaxVertical)
					VerticalVelocity = VerticalVelocity.SafeNormal * DashSettings.AirborneMaxVertical;

				OutMove.ApplyVelocity(VerticalVelocity);
			}
			else
			{
				OutMove.ApplyActorVerticalVelocity();
			}

			float MinGravityScale = 0.4f;
			float MaxGravityScale = 1.f;
			float GravScale = FMath::Clamp((DurationAlpha - MinGravityScale) / (1.f - MinGravityScale), 0.f, 1.f);
			OutMove.ApplyAcceleration(MoveComp.Gravity * FMath::Lerp(0.4f, 1.f, DurationAlpha));
		}

		OutMove.OverrideStepDownHeight(5.f);
		MoveComp.SetTargetFacingDirection(Direction.GetSafeNormal());
		OutMove.ApplyTargetRotationDelta();	
	}

	void CalculateRemoteMove(FHazeFrameMovement& OutMove, float DeltaTime)
	{	
		FHazeActorReplicationFinalized ConsumedParams;
		CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
		OutMove.ApplyConsumedCrumbData(ConsumedParams);
	}

	void RotateDashDirectionTowardsTarget(float DeltaTime, FVector TargetDirection)
	{
		float TurnAlpha = FMath::Pow(DurationAlpha, DashSettings.TurnRatePow);
		float TurnRate = DashSettings.MaxTurnRate * TurnAlpha;

		Direction = RotateVectorTowardsAroundAxis(Direction, TargetDirection, MoveComp.WorldUp, TurnRate * DeltaTime);
	}

	float GetDashSpeed()
	{
		float SpeedAlpha = FMath::Pow(DurationAlpha, DashSettings.SpeedPow);
		return FMath::Lerp(DashSettings.StartSpeed, DashSettings.EndSpeed, SpeedAlpha);
	}

	float GetGravityScale()
	{
		return FMath::Pow(DurationAlpha, DashSettings.GravityPow);
	}
}
