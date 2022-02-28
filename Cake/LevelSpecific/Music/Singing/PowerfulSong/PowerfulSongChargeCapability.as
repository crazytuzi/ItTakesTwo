import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongChargeBaseCapability;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;

class UPowerfulSongChargeCapability : UPowerfulSongChargeBaseCapability
{
	default CapabilityTags.Add(n"PowerfulSongCharge");
	
	UCameraUserComponent CameraUser;
	UHazeMovementComponent MoveComp;

	bool bAllowActivation = true;

	bool bWasButtonDown = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		CameraUser = UCameraUserComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{		
		if(FMath::IsNearlyZero(SingingComp.SongOfLifeCurrent))
			return EHazeNetworkActivation::DontActivate;
		
		if (!IsActioning(ActionNames::PowerfulSongCharge))
			return EHazeNetworkActivation::DontActivate;

		if(Cooldown > 0.0f)
			return EHazeNetworkActivation::DontActivate;

		if(!bAllowActivation)
			return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		CameraUser.SetAiming(this);
		FHazeCameraBlendSettings CamBlend;
		CamBlend.BlendTime = 5.0f;
		Player.ApplyCameraSettings(SingingComp.PowerfulSongAimCamSettings, CamBlend, this, EHazeCameraPriority::High);

		FHazePlayOverrideAnimationParams AnimParams;
		AnimParams.Animation = SingingComp.PowerfulSongFeature.AimMH.Sequence;
		AnimParams.bLoop = true;
		AnimParams.BoneFilter = EHazeBoneFilterTemplate::BoneFilter_UpperBody;
		Player.PlayOverrideAnimation(FHazeAnimationDelegate(), AnimParams);

		Player.PlayAimSpace(SingingComp.PowerfulSongFeature.AimBlendSpace);
		Player.AddLocomotionAsset(SingingComp.PowerfulSongAimingLocomotion, this);

		Owner.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Owner.BlockCapabilities(MovementSystemTags::TurnAround, this);
		bAllowActivation = false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bChargeFinished)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!IsActioning(ActionNames::PowerfulSongCharge))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(Cooldown > 0.0f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);

		CameraUser.ClearAiming(this);
		Player.ClearCameraSettingsByInstigator(this, 1.f);
		Player.StopAllOverrideAnimations();
		Player.StopAimSpace(SingingComp.PowerfulSongFeature.AimBlendSpace);
		Player.ClearLocomotionAssetByInstigator(this);

		Owner.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Owner.UnblockCapabilities(MovementSystemTags::TurnAround, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		UpdateAimSpace(Player.ViewRotation);
		MoveComp.SetTargetFacingRotation(Player.ViewRotation);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		Super::PreTick(DeltaTime);

		const bool bIsButtonDown = IsActioning(ActionNames::PowerfulSongCharge);

		if(!bIsButtonDown && bWasButtonDown)
		{
			bAllowActivation = true;
		}

		bWasButtonDown = bIsButtonDown;
	}

	void UpdateAimSpace(FRotator LookRotation)
	{
		const float X = 0.f;
		const float Y = Player.GetPlayerViewRotation().Pitch;
		Player.SetAimSpaceValues(SingingComp.PowerfulSongFeature.AimBlendSpace, X, Y);
	}
}
