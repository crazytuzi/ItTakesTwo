import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Music.Singing.SingingComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraTags;
import Cake.LevelSpecific.Music.MusicTargetingComponent;

class UPowerfulSongAimCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(ActionNames::WeaponAim);
	default CapabilityTags.Add(n"PowerfulSong");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;

	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;
	UCameraUserComponent CameraUser;
	USingingComponent SingingComp;
	UMusicTargetingComponent TargetingComp;

	float LastCameraYaw = 0.0f;
	float Elapsed = 0.0f;

	FQuat CurrentFacingRotation;

	bool bStartedInAir = false;
	bool bWasAirborne = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		SingingComp = USingingComponent::GetOrCreate(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
		TargetingComp = UMusicTargetingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(ActionNames::LedgeGrabbing))
			return EHazeNetworkActivation::DontActivate;

		if (IsActioning(ActionNames::WallSliding))
			return EHazeNetworkActivation::DontActivate;

		if (IsActioning(ActionNames::Dashing))
			return EHazeNetworkActivation::DontActivate;
		
		if (!IsActioning(ActionNames::WeaponAim))
        	return EHazeNetworkActivation::DontActivate;

		if(IsActioning(MovementSystemTags::Dash))
			return EHazeNetworkActivation::DontActivate;

		if(IsActioning(MovementSystemTags::AirDash))
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Elapsed > 0.0f)
			return EHazeNetworkDeactivation::DontDeactivate;

		if (!IsActioning(ActionNames::WeaponAim))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (IsActioning(ActionNames::LedgeGrabbing))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (IsActioning(ActionNames::WallSliding))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(IsActioning(MovementSystemTags::Dash))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(IsActioning(MovementSystemTags::AirDash))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Elapsed = SingingComp.PowerfulSongAimCooldown;
		bWasAirborne = bStartedInAir = ActivationParams.GetActionState(n"IsAirborne");
		CurrentFacingRotation = MoveComp.TargetFacingRotation;
		SingingComp.bIsAiming = true;
		SingingComp.ShuffleRotation = 0.0f;
		LastCameraYaw = Player.GetPlayerViewRotation().Yaw;
		TargetingComp.bIsTargeting = true;
		Player.AddLocomotionAsset(SingingComp.PowerfulSongAimingLocomotion, this);

		Owner.BlockCapabilities(CameraTags::ChaseAssistance, this);
		Owner.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Owner.BlockCapabilities(MovementSystemTags::TurnAround, this);
		Owner.BlockCapabilities(MovementSystemTags::Sprint, this);
		CameraUser.SetAiming(this);

		if(!bStartedInAir)
			SingingComp.ApplyAimCameraSettings();
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		if(MoveComp.IsAirborne())
			ActivationParams.AddActionState(n"IsAirborne");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SingingComp.bIsAiming = false;
		TargetingComp.bIsTargeting = false;
		Player.ClearLocomotionAssetByInstigator(this);
		SingingComp.ClearCameraAimSettings();
		CameraUser.ClearAiming(this);

		Owner.UnblockCapabilities(CameraTags::ChaseAssistance, this);
		Owner.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Owner.UnblockCapabilities(MovementSystemTags::TurnAround, this);
		Owner.UnblockCapabilities(MovementSystemTags::Sprint, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Elapsed -= DeltaTime;
		const bool bIsAirborne = MoveComp.IsAirborne();
		if(bWasAirborne && !bIsAirborne)
		{
			SingingComp.ApplyAimCameraSettings();
		}

		if(HasControl())
		{
			CurrentFacingRotation = FMath::QInterpTo(CurrentFacingRotation, Player.ViewRotation.Quaternion(), DeltaTime, SingingComp.AimLerpSpeed);
			MoveComp.SetTargetFacingRotation(CurrentFacingRotation);

			if(!bIsAirborne && WasActionStarted(ActionNames::AimShoulderSwap))
			{
				FHazeDelegateCrumbParams CrumbParams;
				CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_SwapCameraAimSettings"), CrumbParams);
			}
		}

		const FRotator CameraRotator = Player.GetPlayerViewRotation();

		SingingComp.ShuffleRotation += FRotator::NormalizeAxis(CameraRotator.Yaw - LastCameraYaw);
		SingingComp.ShuffleRotation = FRotator::ClampAxis(SingingComp.ShuffleRotation);
		LastCameraYaw = CameraRotator.Yaw;

		bWasAirborne = bIsAirborne;
	}

	UFUNCTION()
	private void Crumb_SwapCameraAimSettings(FHazeDelegateCrumbData CrumbData)
	{
		SingingComp.SwapCameraAimSettings();
	}
}
