import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Dash.CharacterDashSettings;
import Vino.Movement.Dash.CharacterDashComponent;
import Vino.Movement.LongJump.CharacterLongJumpSettings;
import Peanuts.SpeedEffect.SpeedEffectStatics;

class UCharacterPerfectDashCapability : UCharacterMovementCapability
{	
	default RespondToEvent(MovementActivationEvents::Grounded);

	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::MovementAction);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(MovementSystemTags::Dash);
	default CapabilityTags.Add(n"PerfectDash");
	default CapabilityTags.Add(n"PerfectDashMovement");
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 150;
	//default SeperateInactiveTick(ECapabilityTickGroups::ActionMovement, 110);

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	UCharacterDashSettings DashSettings;
	UCharacterPerfectDashSettings PerfectDashSettings;
	UCharacterDashComponent DashComp;

	UNiagaraComponent PerfectDashEffect;

	// Calculated on activate using distance over duration
	float Deceleration = 0.f;

	bool bEffectsTriggered = false;
	FCharacterLongJumpSettings LongJumpSettings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		DashComp = UCharacterDashComponent::GetOrCreate(Owner);

		DashSettings = UCharacterDashSettings::GetSettings(Owner);
		PerfectDashSettings = UCharacterPerfectDashSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick_EventBased()
	{
		if (WasActionStarted(ActionNames::MovementDash) && !IsInsidePerfectDashWindow())
       		DashComp.bFailedPerfectDashWindow = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsAirborne())
       		return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::MovementDash))
       		return EHazeNetworkActivation::DontActivate;

		if (MoveComp.CurrentGroundTime <= 0.2f)
			return EHazeNetworkActivation::ActivateUsingCrumb;

		// If you activate within the post activation time of the 
		if (!IsInsidePerfectDashWindow())
			return EHazeNetworkActivation::DontActivate;

		if (DashComp.bFailedPerfectDashWindow)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return RemoteLocalControlCrumbDeactivation();

		if (ActiveDuration >= PerfectDashSettings.Duration)
       		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(ActionNames::WeaponAim, this);
		Player.SetCapabilityActionState(DashTags::GroundDashing, EHazeActionState::Active);
		Player.SetCapabilityActionState(n"PerfectDash", EHazeActionState::Active);

		DashComp.DashActiveDuration = 0.f;
		DashComp.bDashActive = true;

		Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_Player_Is_Dashing", 1.f);
		
		if (ActivationParams.IsStale())
			return;

		FVector HorizontalVelocity = Owner.ActorForwardVector * PerfectDashSettings.StartSpeed;
		FVector Velocity = HorizontalVelocity ;
        MoveComp.SetVelocity(Velocity);

		Deceleration = (PerfectDashSettings.EndSpeed - PerfectDashSettings.StartSpeed) / PerfectDashSettings.Duration;

		bEffectsTriggered = false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(ActionNames::WeaponAim, this);
		Player.SetCapabilityActionState(DashTags::GroundDashing, EHazeActionState::Inactive);
		Player.SetCapabilityActionState(n"PerfectDash", EHazeActionState::Inactive);
		Player.SetCapabilityActionState(n"DashFinished", EHazeActionState::ActiveForOneFrame);

		DashComp.bDashEnded = true;

		Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_Player_Is_Dashing", 1.f);
		
		DestroyEffect();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"PerfectDash");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveCharacter(FrameMove, n"PerfectDash");
			
			CrumbComp.LeaveMovementCrumb();	
		}

		if (!bEffectsTriggered && ActiveDuration > LongJumpSettings.DashJumpSyncedInputGracePeriod)
		{
			bEffectsTriggered = true;
			PlayForceFeedback();
			PlayEffect();
		}
	}	

	bool IsInsidePerfectDashWindow() const
	{	
		if (DashComp.DashDeactiveDuration <= PerfectDashSettings.PostDashActivationTime)
			return true;

		if (!DashComp.bDashActive)
			return false;

		float RemainingDashDuration = DashSettings.Duration - DashComp.DashActiveDuration;
		if (RemainingDashDuration >= PerfectDashSettings.ActivationTimeFromEnd)
			return false;

		return true;
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{	
			FVector Velocity = MoveComp.Velocity;
			FVector MoveDirection = GetMoveDirectionOnSlope(MoveComp.DownHit.Normal);

			if (!MoveDirection.IsNearlyZero())
			{
				FVector TargetVelocity = MoveDirection.GetSafeNormal() * Velocity.Size();
				
				if (ActiveDuration < PerfectDashSettings.ControlDuration)
					Velocity = TargetVelocity;
				else
					Velocity = FMath::Lerp(Velocity, TargetVelocity, (ActiveDuration / PerfectDashSettings.Duration) * 0.125f);
			}

			Velocity += Velocity.GetSafeNormal() * Deceleration * DeltaTime;

			if (MoveComp.IsAirborne())
				FrameMove.ApplyVelocity(MoveComp.Gravity * 0.8f * DeltaTime);
			
			FrameMove.ApplyVelocity(Velocity);
			FrameMove.ApplyAndConsumeImpulses();
			FrameMove.FlagToMoveWithDownImpact();
			FrameMove.ApplyTargetRotationDelta();

			if (!Velocity.IsNearlyZero())
				MoveComp.SetTargetFacingDirection(Velocity.GetSafeNormal(), PerfectDashSettings.FacingDirectionRotationSpeed);
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
		if (DashComp.PerfectDashForceFeedback != nullptr)
			Player.PlayForceFeedback(DashComp.PerfectDashForceFeedback, false, true, NAME_None);
	}

	void PlayEffect()
	{
		if (DashComp.PerfectDashEffect != nullptr)
			PerfectDashEffect = Niagara::SpawnSystemAttached(DashComp.PerfectDashEffect, Player.CapsuleComponent, NAME_None, -MoveComp.WorldUp * 70.f, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
	}

	void DestroyEffect()
	{
		if (PerfectDashEffect != nullptr)
			PerfectDashEffect.DestroyComponent(Player);
	}
}
