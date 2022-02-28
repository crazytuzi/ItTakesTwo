import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Dash.CharacterDashComponent;
import Vino.Movement.Capabilities.Sprint.CharacterSprintComponent;
import Vino.Movement.Jump.AirJumpsComponent;
import Vino.Movement.LongJump.CharacterLongJumpSettings;

class UCharacterLongJumpCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Jump);
	default CapabilityTags.Add(n"LongJump");

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	default CapabilityDebugCategory = CapabilityTags::Movement;	

	AHazePlayerCharacter Player;
	UCharacterDashComponent DashComp;
	UCharacterSprintComponent SprintComp;
	UCharacterAirJumpsComponent AirJumpsComp;

	FCharacterLongJumpSettings LongJumpSettings;
	UMovementSettings MoveSettings;

	UNiagaraComponent DashJumpEffect;
	float GravityMultiplierOriginal = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		DashComp = UCharacterDashComponent::Get(Owner);
		SprintComp = UCharacterSprintComponent::GetOrCreate(Owner);
		AirJumpsComp = UCharacterAirJumpsComponent::GetOrCreate(Owner);

		MoveSettings = UMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.IsWithinJumpGroundedGracePeriod())
			return EHazeNetworkActivation::DontActivate;

		if (WasActionStarted(ActionNames::MovementDash) && WasActionStartedDuringTime(ActionNames::MovementJump, LongJumpSettings.JumpDashSyncedInputGracePeriod))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		if (WasActionStarted(ActionNames::MovementJump) && WasActionStartedDuringTime(ActionNames::MovementDash, LongJumpSettings.DashJumpSyncedInputGracePeriod))
			return EHazeNetworkActivation::ActivateUsingCrumb;
		
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		float DownwardsSpeed = MoveComp.Velocity.DotProduct(-MoveComp.WorldUp);
		if (DownwardsSpeed >= MoveComp.MaxFallSpeed)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (ActiveDuration >= LongJumpSettings.Duration)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(ActionNames::WeaponAim, this);

		if (ActivationParams.IsStale())
			return;	

		FVector Direction = GetAttributeVector(AttributeVectorNames::MovementDirection);
		if (Direction.IsNearlyZero())
			Direction = Owner.ActorForwardVector;
		Direction.Normalize();

		GravityMultiplierOriginal = MoveSettings.GravityMultiplier;

		FVector Velocity;
		Velocity += Direction * MoveComp.JumpSettings.LongJumpImpulses.Horizontal;
		Velocity += MoveComp.WorldUp * MoveComp.JumpSettings.LongJumpImpulses.Vertical;

		FVector InheritedVelocity = MoveComp.GetInheritedVelocity();
		Velocity += InheritedVelocity;

		MoveComp.OnJumpTrigger(InheritedVelocity.ConstrainToPlane(MoveComp.WorldUp), InheritedVelocity.ConstrainToDirection(MoveComp.WorldUp).Size());

    	MoveComp.SetVelocity(Velocity);

		Player.ApplyPivotLagSpeed(FVector(0.5f, 0.5f, 0.f), this, EHazeCameraPriority::Low);
		Player.ApplyPivotLagMax(FVector(200.f, 200.f, 400.f), this, EHazeCameraPriority::Low);

		UMovementSettings::SetAirControlLerpSpeed(Player, LongJumpSettings.OverrideAirControlLerpSpeed, Instigator = this);

		AirJumpsComp.ConsumeJumpAndDash();

		PlayForceFeedback();
		PlayCameraShake();
		PlayEffect();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(ActionNames::WeaponAim, this);
		Player.ClearCameraSettingsByInstigator(this);
		Player.ClearSettingsByInstigator(this);
		
		DestroyEffect();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"LongJump");
		CalculateFrameMove(FrameMove, DeltaTime);
		MoveCharacter(FrameMove, n"LongJump");
		
		CrumbComp.LeaveMovementCrumb();
	}	

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{			
			FVector MoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
			float MoveSpeed = MoveComp.MoveSpeed;

			FrameMove.ApplyDelta(GetHorizontalAirDeltaMovement(DeltaTime, MoveDirection, MoveSpeed));
			FrameMove.ApplyAndConsumeImpulses();
			FrameMove.ApplyActorVerticalVelocity();

			float Alpha =  Math::Saturate(ActiveDuration / LongJumpSettings.GravityLerpDuration);
			float GravityMultiplierNew = FMath::Lerp(MoveComp.JumpSettings.LongJumpStartGravityMultiplier, GravityMultiplierOriginal, Alpha);
			FrameMove.ApplyAcceleration(-MoveComp.WorldUp * 980.f * GravityMultiplierNew * MoveComp.JumpSettings.JumpGravityScale);

			MoveComp.SetTargetFacingDirection(MoveComp.Velocity.GetSafeNormal(), 3.f);

			FrameMove.ApplyTargetRotationDelta();
			FrameMove.OverrideStepDownHeight(0.f);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}
	}	

	void PlayForceFeedback()
	{
		if (DashComp.DashJumpForceFeedback != nullptr)
			Player.PlayForceFeedback(DashComp.DashJumpForceFeedback, false, true, n"");
	}
	
	void PlayCameraShake()
	{
		if (DashComp.DashJumpCameraShake.IsValid())
			Player.PlayCameraShake(DashComp.DashJumpCameraShake);
	}

	void PlayEffect()
	{
		if (DashComp.DashJumpEffect != nullptr)
			DashJumpEffect = Niagara::SpawnSystemAttached(DashComp.DashJumpEffect, Player.Mesh, n"Belly", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
	}

	void DestroyEffect()
	{
		if (DashJumpEffect != nullptr)
			DashJumpEffect.DestroyComponent(Player);
	}
}
