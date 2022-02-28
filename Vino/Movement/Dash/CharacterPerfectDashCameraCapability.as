import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Dash.CharacterDashSettings;
import Vino.Movement.Dash.CharacterDashComponent;
import Vino.Movement.LongJump.CharacterLongJumpSettings;
import Peanuts.SpeedEffect.SpeedEffectStatics;

class UCharacterPerfectDashCameraCapability : UHazeCapability
{
	default RespondToEvent(n"PerfectDash");

	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(MovementSystemTags::Dash);
	default CapabilityTags.Add(n"PerfectDash");
	default CapabilityTags.Add(n"PerfectDashCamera");
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 200;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	UCharacterDashSettings DashSettings;
	UCharacterPerfectDashSettings PerfectDashSettings;
	UCharacterDashComponent DashComp;
	UHazeMovementComponent MoveComp;

	// Calculated on activate using distance over duration
	float Deceleration = 0.f;

	bool bEffectsTriggered = false;
	FCharacterLongJumpSettings LongJumpSettings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		DashComp = UCharacterDashComponent::GetOrCreate(Owner);

		DashSettings = UCharacterDashSettings::GetSettings(Owner);
		PerfectDashSettings = UCharacterPerfectDashSettings::GetSettings(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!Player.IsAnyCapabilityActive(n"PerfectDashMovement"))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Player.IsAnyCapabilityActive(n"PerfectDashMovement"))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bEffectsTriggered = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this, 0.5f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!bEffectsTriggered && ActiveDuration > LongJumpSettings.DashJumpSyncedInputGracePeriod)
		{
			bEffectsTriggered = true;
			PlayCameraShake();
		}

		FSpeedEffectRequest SpeedEffect;
		SpeedEffect.Instigator = this;
		SpeedEffect.Value = FMath::GetMappedRangeValueClamped(FVector2D(PerfectDashSettings.EndSpeed * 1.2f, PerfectDashSettings.StartSpeed), FVector2D(0.f, 1.f), MoveComp.HorizontalVelocity);
		SpeedEffect.bSnap = false;
		SpeedEffect::RequestSpeedEffect(Player, SpeedEffect);

		float FoV = FMath::GetMappedRangeValueClamped(FVector2D(PerfectDashSettings.EndSpeed, PerfectDashSettings.StartSpeed), FVector2D(0.75f, 2.f), MoveComp.HorizontalVelocity);
		FHazeCameraBlendSettings Blend;
		Blend.Type = EHazeCameraBlendType::Additive;
		Blend.BlendTime = 0.25f;
		Player.ApplyFieldOfView(FoV, Blend, this, EHazeCameraPriority::Low);
	}

	void PlayCameraShake()
	{
		if (DashComp.PerfectDashCameraShake.IsValid())
			Player.PlayCameraShake(DashComp.PerfectDashCameraShake);
	}
}