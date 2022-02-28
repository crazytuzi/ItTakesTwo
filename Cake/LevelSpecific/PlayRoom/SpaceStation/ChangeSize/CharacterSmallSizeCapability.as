import Vino.Movement.Components.MovementComponent;
import Vino.Characters.PlayerCharacter;
import Vino.Camera.Capabilities.DebugCameraCapability;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeStatics;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideSettings;
import Vino.Movement.Capabilities.LedgeVault.LedgeVaultSettings;
import Vino.Movement.Dash.CharacterDashSettings;
import Vino.Movement.Capabilities.Sprint.CharacterSprintSettings;
import Vino.Movement.Capabilities.Standard.CharacterFloorMoveCapability;
import Vino.Movement.Capabilities.GroundPound.GroundPoundSettings;
import Vino.PlayerHealth.PlayerRespawnComponent;

settings CodySmallMovementSettings for UMovementSettings
{
	CodySmallMovementSettings.MoveSpeed = 120.f;
	CodySmallMovementSettings.HorizontalAirSpeed = 120.f;
	CodySmallMovementSettings.AirControlLerpSpeed = 250.f;
	CodySmallMovementSettings.StepUpAmount = 4.f;
	CodySmallMovementSettings.GravityMultiplier = 0.61f;
}

settings CodySmallWallSlideSettings for UWallSlideDynamicSettings
{
	CodySmallWallSlideSettings.MaxUpwardsSpeedToStart = 25.f;
	CodySmallWallSlideSettings.NumberOfCenterTracingSegments = 2;
	CodySmallWallSlideSettings.SideDistanceCheck = 64.f;
	CodySmallWallSlideSettings.WallSlideSpeed = 10.f;
	CodySmallWallSlideSettings.FastWallSlideSpeed = 52.5f;
	CodySmallWallSlideSettings.SidesExtraWidth = 1.2f;
	CodySmallWallSlideSettings.WallSlideInterpSpeed = 2.f;
}

settings CodySmallJumpSettings for UCharacterJumpSettings
{
	CodySmallJumpSettings.FloorJumpImpulse = 130.0f;	
	CodySmallJumpSettings.JumpGravityScale = 1.f;

	CodySmallJumpSettings.AirJumpImpulse = 162.0f;

	CodySmallJumpSettings.WallSlideJumpUpImpulses.Horizontal = 25.0f;
	CodySmallJumpSettings.WallSlideJumpUpImpulses.Vertical = 125.0f;

	CodySmallJumpSettings.WallSlideJumpAwayImpulses.Horizontal = 95.0f;
	CodySmallJumpSettings.WallSlideJumpAwayImpulses.Vertical = 145.0f;

	CodySmallJumpSettings.LedgeGrabJumpUpImpulse = 145.0f;

	CodySmallJumpSettings.LedgeGrabJumpAwayImpulses.Horizontal = 95.0f;
	CodySmallJumpSettings.LedgeGrabJumpAwayImpulses.Vertical = 145.0f;

	CodySmallJumpSettings.LedgeNodeJumpUpImpulse = 145.0f; 

	CodySmallJumpSettings.LedgeNodeJumpAwayImpulses.Horizontal = 95.0f;
	CodySmallJumpSettings.LedgeNodeJumpAwayImpulses.Vertical = 145.0f;

	CodySmallJumpSettings.LongJumpImpulses.Horizontal = 155.0f;	
	CodySmallJumpSettings.LongJumpImpulses.Vertical = 130.0f;

	CodySmallJumpSettings.LongJumpStartGravityMultiplier = 0.1f;

	CodySmallJumpSettings.GroundPoundJumpImpulse = 255.f;
}

settings CodySmallLedgeVaultSettings for ULedgeVaultDynamicSettings
{
	CodySmallLedgeVaultSettings.FindTopHeight = 35.0f;
	CodySmallLedgeVaultSettings.FindTopDepth = 3.5f;
	CodySmallLedgeVaultSettings.MaxiumDistanceToTop = 19.5f;
	CodySmallLedgeVaultSettings.LerpTime = 0.2f;
}

settings CodySmallDashSettings for UCharacterDashSettings
{
	CodySmallDashSettings.StartSpeed = 205.f;
    CodySmallDashSettings.EndSpeed = 150.f;
}

settings CodySmallPerfectDashSettings for UCharacterPerfectDashSettings
{
	CodySmallPerfectDashSettings.StartSpeed = 360.f;
    CodySmallPerfectDashSettings.EndSpeed = 180.f;
}

settings CodySmallAirDashSettings for UCharacterAirDashSettings
{
	CodySmallAirDashSettings.StartSpeed = 190.f;
    CodySmallAirDashSettings.EndSpeed = 110.f;
	CodySmallAirDashSettings.StartUpwardsSpeed = 40.f;
}

settings CodySmallGroundPoundDashSettings for UGroundPoundDashSettings
{
	CodySmallGroundPoundDashSettings.StartSpeed = 650.f;
	CodySmallGroundPoundDashSettings.EndSpeed = 170.f;
}

settings CodySmallSprintSettings for USprintSettings
{
	CodySmallSprintSettings.MoveSpeed = 260.f;
	CodySmallSprintSettings.Acceleration = 650.f;
	CodySmallSprintSettings.TurnRate = 450.f;
	CodySmallSprintSettings.Deceleration = 400.f;
	CodySmallSprintSettings.SlowdownDuration = 0.1f;
	CodySmallSprintSettings.SpeedupDuration = 0.15f;
}

settings CodySmallGroundPoundSettings for UGroundPoundDynamicSettings
{
	CodySmallGroundPoundSettings.MinHeight = 15.f;
}

class UCharacterSmallSizeCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Gravity");
	default CapabilityTags.Add(n"ChangeSize");
	default CapabilityTags.Add(n"SmallSize");
	default CapabilityTags.Add(n"MutuallyExclusiveSize");

	default CapabilityDebugCategory = n"ChangeSize";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 75;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UCharacterChangeSizeComponent ChangeSizeComp;

	float TargetScale = 0.1f;

	float ForceFeedbackIntensity = 0.05f;

	UPROPERTY()
	FHazeTimeLike ChangeSizeTimeLike;
	default ChangeSizeTimeLike.Duration = 1.f;

	bool bChangingScale = false;
	bool bForceReset = false;
	bool bForceSmallSize = false;
	bool bSnapSmallSize = false;

	float TargetMovementSpeed = 200.f;

	FCharacterSizeValues MovementModifierValues;
	default MovementModifierValues.Small = 0.1f;
	default MovementModifierValues.Medium = 1.f;
	default MovementModifierValues.Large = 4.f;

	float ScaleDuration = 0.25f;

	float StartScale = 1.f;

	UPROPERTY()
	UMaterialParameterCollection MaterialParamCollection;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Player);
		ChangeSizeComp = UCharacterChangeSizeComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (bSnapSmallSize)
			return EHazeNetworkActivation::ActivateFromControl;

		if (bForceSmallSize)
			return EHazeNetworkActivation::ActivateUsingCrumb;

		if (!WasActionStarted(ActionNames::SecondaryLevelAbility))
			return EHazeNetworkActivation::DontActivate;

		if(IsActioning(n"HasPendingPickup"))
			return EHazeNetworkActivation::DontActivate;

		if (Player.IsPlayingAnimAsSlotAnimation(ChangeSizeComp.ObstructedAnimation))
			return EHazeNetworkActivation::DontActivate;

		if (!Player.IsAnyCapabilityActive(UCharacterFloorMoveCapability::StaticClass()))
			return EHazeNetworkActivation::DontActivate;

		if (Player.IsAnyCapabilityActive(n"ValidationMovement"))
			return EHazeNetworkActivation::DontActivate;

		if (ChangeSizeComp.bChangingSize)
			return EHazeNetworkActivation::DontActivate;

		if (Player.IsAnyCapabilityActive(UDebugCameraCapability::StaticClass()))
			return EHazeNetworkActivation::DontActivate;
			
		if (!MoveComp.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if (ChangeSizeComp.CurrentSize != ECharacterSize::Medium)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ChangeSizeComp.CurrentSize != ECharacterSize::Small)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
    void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
    {

    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bForceSmallSize = false;

		if (!bSnapSmallSize)
		{
			Player.PlayCameraShake(ChangeSizeComp.CameraShakes.MediumToSmall);

			if (HasControl())
			{
				Player.BlockCapabilities(CapabilityTags::Interaction, this);
				Player.BlockCapabilities(CapabilityTags::MovementAction, this);
			}

			ChangeSizeComp.bChangingSize = true;
			bChangingScale = true;
		}

		StartScale = Player.ActorScale3D.Z;

		float CameraBlendTime = bSnapSmallSize ? 0.f : 0.5f;
		Player.ApplyCameraSettings(ChangeSizeComp.SmallCameraSettings, FHazeCameraBlendSettings(CameraBlendTime), this, EHazeCameraPriority::High);

		ChangeSizeComp.SetSize(ECharacterSize::Small);

		Player.AddCapabilitySheet(ChangeSizeComp.SmallSheet, EHazeCapabilitySheetPriority::Normal, this);
		Player.ApplySettings(CodySmallWallSlideSettings, Instigator = this);
		Player.ApplySettings(CodySmallJumpSettings, Instigator = this);
		Player.ApplySettings(CodySmallLedgeVaultSettings, Instigator = this);
		Player.ApplySettings(CodySmallDashSettings, Instigator = this);
		Player.ApplySettings(CodySmallMovementSettings, Instigator = this);
		Player.ApplySettings(CodySmallPerfectDashSettings, Instigator = this);
		Player.ApplySettings(CodySmallAirDashSettings, Instigator = this);
		Player.ApplySettings(CodySmallSprintSettings, Instigator = this);
		Player.ApplySettings(CodySmallGroundPoundDashSettings, Instigator = this);
		Player.ApplySettings(CodySmallGroundPoundSettings, Instigator = this);

		Player.ApplySettings(ChangeSizeComp.SmallHealthSettings, this);

		if (bSnapSmallSize)
		{
			bSnapSmallSize = false;
			MoveComp.SetControlledComponentScale(0.1f);
		}

		UHazeCameraComponent CamComp = UHazeCameraComponent::Get(Player);
		CamComp.CameraCollisionParams.ProbeSize = 2.f;

		FHazeCameraImpulse CamImpulse;
		CamImpulse.WorldSpaceImpulse =  -30.f;
		CamImpulse.Dampening = 0.1f;
		CamImpulse.ExpirationForce = 15.f;
		SetPlayerGroundPoundLandCameraShake(Player, CamImpulse, ChangeSizeComp.SmallGroundPoundCameraShake);

		if (ChangeSizeComp.SmallRespawnEffect != nullptr)
			SetRespawnSystem(Player, ChangeSizeComp.SmallRespawnEffect);

		MoveComp.SetAnimationMaxMoveSpeed(120.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this, 0.5f);
		Player.ClearSettingsByInstigator(this);
		
		Player.RemoveCapabilitySheet(ChangeSizeComp.SmallSheet, this);

		if (bChangingScale)
		{
			UnblockCapabilities();
			bChangingScale = false;
			ChangeSizeComp.bChangingSize = false;
		}

		UHazeCameraComponent CamComp = UHazeCameraComponent::Get(Player);
		CamComp.CameraCollisionParams.ProbeSize = FHazeCameraCollisionParams().ProbeSize;

		ResetRespawnSystem(Player);

		MoveComp.SetAnimationMaxMoveSpeed(800.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.ClearSettingsByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this, 0.4f);
		MoveComp.SetControlledComponentScale(FVector::OneVector);
		MoveComp.SetAnimationMaxMoveSpeed(800.f);
		ResetPlayerGroundPoundLandCameraImpulse(Player);
    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsActioning(n"ForceSmallSize"))
		{
			Player.SetCapabilityActionState(n"ForceSmallSize", EHazeActionState::Inactive);
			if (ChangeSizeComp.CurrentSize != ECharacterSize::Small)
				bForceSmallSize = true;
		}

		if (IsActioning(n"SnapSmallSize"))
		{
			Player.SetCapabilityActionState(n"SnapSmallSize", EHazeActionState::Inactive);
			if (ChangeSizeComp.CurrentSize != ECharacterSize::Small)
				bSnapSmallSize = true;
		}
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (bChangingScale)
		{
			Player.SetFrameForceFeedback(ForceFeedbackIntensity, ForceFeedbackIntensity);
			float CurAlpha = FMath::GetMappedRangeValueClamped(FVector2D(0.f, ScaleDuration), FVector2D(0.f, 1.f), ActiveDuration);
			CurAlpha = FMath::Clamp(CurAlpha, 0.f, 1.f);
			float CurScale = FMath::Lerp(StartScale, 0.1f, CurAlpha);
			MoveComp.SetControlledComponentScale(CurScale);

			if (FVector(CurScale).Equals(FVector(TargetScale)))
			{
				bChangingScale = false;
				UnblockCapabilities();
				ChangeSizeComp.bChangingSize = false;
			}
		}
	}

	void UnblockCapabilities()
	{
		if (HasControl())
		{
			Player.UnblockCapabilities(CapabilityTags::Interaction, this);
			Player.UnblockCapabilities(CapabilityTags::MovementAction, this);
		}
	}
}
