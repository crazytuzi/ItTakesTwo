import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Dash.CharacterDashSettings;
import Vino.Movement.Dash.CharacterDashComponent;

class UCharacterDashCapability : UCharacterMovementCapability
{	
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::MovementAction);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(MovementSystemTags::Dash);
	default CapabilityTags.Add(n"FloorDash");
	default CapabilityTags.Add(n"DashMovement");

	default BlockExclusionTags.Add(BlockExclusionTags::UsableDuringGroundPound);
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 151;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	UCharacterDashSettings DashSettings;
	UCharacterDashComponent DashComp;

	UNiagaraComponent DashEffect;

	// Calculated on activate using distance over duration
	float Deceleration = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		DashComp = UCharacterDashComponent::GetOrCreate(Owner);

		DashSettings = UCharacterDashSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsActive())
			DashComp.DashActiveDuration += DeltaTime;
		else
			DashComp.DashDeactiveDuration += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;			   

		if (MoveComp.IsAirborne())
       		return EHazeNetworkActivation::DontActivate;
	
		if (!WasActionStartedDuringTime(ActionNames::MovementDash, 0.15f))
       		return EHazeNetworkActivation::DontActivate;

		if (DeactiveDuration < DashSettings.Cooldown)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (ActiveDuration >= DashSettings.Duration)
       		return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.SetCapabilityActionState(DashTags::GroundDashing, EHazeActionState::Active);

		DashComp.DashActiveDuration = 0.f;
		DashComp.bDashActive = true;
		DashComp.bFailedPerfectDashWindow = false;

		DashComp.PredictedHit = FHazeHitResult();

		FVector InitialDirection = Math::ConstrainVectorToSlope(MoveComp.TargetFacingRotation.ForwardVector, MoveComp.DownHit.Normal, MoveComp.WorldUp);
		InitialDirection.Normalize();

		FVector Velocity = InitialDirection * DashSettings.StartSpeed;		

		Player.BlockCapabilities(ActionNames::WeaponAim, this);

		Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_Player_Is_Dashing", 1.f);

		Deceleration = (DashSettings.EndSpeed - DashSettings.StartSpeed) / DashSettings.Duration;
	
		if (!ActivationParams.IsStale())
		{
			MoveComp.SetVelocity(Velocity);
			PlayForceFeedback();
			PlayEffect();
			PlayCameraShake();

			Player.SetCapabilityActionState(n"AudioStartedDash", EHazeActionState::Active);
		}	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(ActionNames::WeaponAim, this);
		Player.SetCapabilityActionState(DashTags::GroundDashing, EHazeActionState::Inactive);
		Player.SetCapabilityActionState(n"DashFinished", EHazeActionState::ActiveForOneFrame);

		DashComp.bDashActive = false;
		DashComp.bDashEnded = true;
		DashComp.DashDeactiveDuration = 0.f;

		Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_Player_Is_Dashing", 0.f);

		DestroyEffect();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(MovementSystemTags::Dash);
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveCharacter(FrameMove, DashComp.PredictedHit.bBlockingHit ? FeatureName::DashWallHit : FeatureName::Dash);
			
			CrumbComp.LeaveMovementCrumb();	
		}
	}	

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{			
			FVector Velocity = MoveComp.Velocity;
			FVector MoveDirection = GetMoveDirectionOnSlope(MoveComp.DownHit.Normal);

			if (!MoveDirection.IsNearlyZero())
			{
				FVector TargetVelocity = MoveDirection * Velocity.Size();
				
				//float MoveSpeedMax = (DashSettings.StartSpeed / DashSettings.Duration) * (1 - (ActiveDuration / DashSettings.Duration)) * 2.f;

				if (ActiveDuration < DashSettings.ControlDuration)
					Velocity = TargetVelocity;
				else
					Velocity = FMath::Lerp(Velocity, TargetVelocity, (ActiveDuration / DashSettings.Duration) * 0.125f);
					//Velocity = FMath::VInterpConstantTo(Velocity, TargetVelocity, DeltaTime, MoveSpeedMax);
			}

			Velocity += Velocity.GetSafeNormal() * Deceleration * DeltaTime;
			const FVector DeltaMove = Velocity * DeltaTime;

			if (!MoveComp.Velocity.IsNearlyZero())
				MoveComp.SetTargetFacingDirection(MoveComp.Velocity.GetSafeNormal(), DashSettings.FacingDirectionRotationSpeed);
	
			FrameMove.ApplyDeltaWithCustomVelocity(DeltaMove, Velocity);	
			
			if (MoveComp.IsAirborne())
				FrameMove.ApplyGravityAcceleration();
			
			FrameMove.ApplyAndConsumeImpulses();
				//float GravityMultiplier = FMath::Square(FMath::Lerp(0.f, 1.f, Math::Saturate(ActiveDuration / (DashSettings.Duration * 0.5f))));
				//FrameMove.ApplyVelocity(MoveComp.Gravity * GravityMultiplier * DeltaTime);

			FrameMove.FlagToMoveWithDownImpact();
			FrameMove.ApplyTargetRotationDelta(); 		
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
		if (DashComp.DashForceFeedback != nullptr)
			Player.PlayForceFeedback(DashComp.DashForceFeedback, false, true, n"");
	}

	void PlayCameraShake()
	{
		if (DashComp.DashCameraShake.IsValid())
			Player.PlayCameraShake(DashComp.DashCameraShake);
	}

	void PlayEffect()
	{
		if (DashComp.DashEffect != nullptr)
			DashEffect = Niagara::SpawnSystemAttached(DashComp.DashEffect, Player.Mesh, n"Belly", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
	}

	void DestroyEffect()
	{
		if (DashEffect != nullptr)
			DashEffect.DestroyComponent(Player);
	}
}
