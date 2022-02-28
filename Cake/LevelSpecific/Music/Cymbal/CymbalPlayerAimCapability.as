import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;
import Vino.Time.ActorTimeDilationStatics;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraTags;
import Cake.LevelSpecific.Music.MusicTargetingComponent;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;
import Vino.Movement.Grinding.UserGrindComponent;

class UCymbalPlayerAimCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(ActionNames::WeaponAim);
	default CapabilityTags.Add(n"Cymbal");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 9;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;
	UCameraUserComponent CameraUser;
	UCymbalComponent CymbalComp;
	UHazeSmoothSyncFloatComponent SyncedYawRotation;
	UMusicTargetingComponent TargetingComp;
	UCharacterGroundPoundComponent GroundPoundComp;
	UUserGrindComponent GrindComp;
	UCymbalSettings CymbalSettings;

	FQuat CurrentFacingRotation;
	float Elapsed = 0.0f;
	bool bStartedInAir = false;
	bool bWasAirborne = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CymbalComp = UCymbalComponent::GetOrCreate(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		TargetingComp = UMusicTargetingComponent::Get(Owner);
		SyncedYawRotation = UHazeSmoothSyncFloatComponent::GetOrCreate(Owner, n"CymbalAimYaw");
		GroundPoundComp = UCharacterGroundPoundComponent::Get(Owner);
		GrindComp = UUserGrindComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(ActionNames::WeaponAim))
        	return EHazeNetworkActivation::DontActivate;

		if(CymbalComp.bThrowWithoutAim)
			return EHazeNetworkActivation::DontActivate;
		
		if (!CymbalComp.bCymbalEquipped)
			return EHazeNetworkActivation::DontActivate;

		if (CymbalComp.bShieldActive)
			return EHazeNetworkActivation::DontActivate;

		if(IsActioning(MovementSystemTags::Dash))
			return EHazeNetworkActivation::DontActivate;

		if(IsActioning(MovementSystemTags::AirDash))
			return EHazeNetworkActivation::DontActivate;
	
		if(GroundPoundComp.ActiveState != EGroundPoundState::None)
			return EHazeNetworkActivation::DontActivate;

		if(GrindComp.HasActiveGrindSpline())
			return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		if(IsAirborne())
			ActivationParams.AddActionState(n"IsAirborne");
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Elapsed = CymbalComp.AimCooldown;
		CymbalComp.ResetOffset();
		TargetingComp.bIsTargeting = true;
		bWasAirborne = bStartedInAir = ActivationParams.GetActionState(n"IsAirborne");
		CymbalSettings = UCymbalSettings::GetSettings(CymbalComp.CymbalActor);
		CurrentFacingRotation = MoveComp.TargetFacingRotation;
		CameraUser.SetAiming(this);
		
		CymbalComp.bAiming = true;
		CymbalComp.bTargeting = true;
		FHazePlayOverrideAnimationParams AnimParams;
		
		if(!bStartedInAir)
		{
			Player.AddLocomotionAsset(CymbalComp.CymbalStrafe, this);
		}
		
		CymbalComp.AttachCymbalToHands();

		Owner.BlockCapabilities(CameraTags::ChaseAssistance, this);
		Owner.BlockCapabilities(MovementSystemTags::Jump, this);
		Owner.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Owner.BlockCapabilities(MovementSystemTags::TurnAround, this);
		Owner.BlockCapabilities(MovementSystemTags::Sprint, this);

		FHazeCameraBlendSettings CamBlend;


		if (Player.IsAnyCapabilityActive(MovementSystemTags::WallSlide))
			return;

		if (!bStartedInAir || !CymbalComp.ShouldPlayCatchAnimation())
		{	
			//CamBlend.BlendTime = 0.05f;
			//Player.ApplyCameraSettings(CymbalComp.AimAirCameraSettings, CamBlend, this, EHazeCameraPriority::High);
			CymbalComp.ApplyCymbalAimCameraSetting();
		}
		else
		{
			
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
		if(Elapsed > 0.0f)
			return EHazeNetworkDeactivation::DontDeactivate;

		if (!IsActioning(ActionNames::WeaponAim))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!CymbalComp.bCymbalEquipped)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(IsActioning(MovementSystemTags::Dash))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(IsActioning(MovementSystemTags::AirDash))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(GroundPoundComp.ActiveState != EGroundPoundState::None)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(GrindComp.HasActiveGrindSpline())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
		if(CymbalComp.bCymbalWasThrown)
		{
			DeactivationParams.AddActionState(n"CymbalWasThrown");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		TargetingComp.bIsTargeting = false;
		CameraUser.ClearAiming(this);
		CymbalComp.StopAiming();
		CymbalComp.bAiming = false;
		CymbalComp.bCymbalWasThrown = false;
		Player.ClearLocomotionAssetByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this, 1.f);
		CymbalComp.ClearCymbalAimCameraSetting();

		if(!DeactivationParams.GetActionState(n"CymbalWasThrown"))
		{
			CymbalComp.AttachCymbalToBack();
		}
		
		Owner.UnblockCapabilities(CameraTags::ChaseAssistance, this);
		Owner.UnblockCapabilities(MovementSystemTags::Jump, this);
		Owner.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Owner.UnblockCapabilities(MovementSystemTags::TurnAround, this);
		Owner.UnblockCapabilities(MovementSystemTags::Sprint, this);

		CymbalComp.bTargeting = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Elapsed -= DeltaTime;
		const bool bIsAirborne = IsAirborne();

		if(bWasAirborne && !bIsAirborne)
		{
			Player.AddLocomotionAsset(CymbalComp.CymbalStrafe, this);
			Player.ClearCameraSettingsByInstigator(this, 0);
			FHazeCameraBlendSettings CamBlend;
			CamBlend.BlendTime = 0.5f;
			CymbalComp.ApplyCymbalAimCameraSetting();
		}

		if(bIsAirborne && CymbalComp.ShouldPlayCatchAnimation())
		{
			MoveComp.SetAnimationToBeRequested(n"CymbalAirAim");
		}

		// facing rotation
		if(HasControl())
		{
			FVector2D VerticalInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
			const FVector ViewRotationVector = Player.ViewRotation.Vector();
			FVector TargetRotation = ViewRotationVector.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
			const float AngularDistance = FMath::Sign(Owner.ActorForwardVector.AngularDistanceForNormals(TargetRotation)) * VerticalInput.X;
			CurrentFacingRotation = FMath::QInterpTo(CurrentFacingRotation, TargetRotation.ToOrientationQuat(), DeltaTime, CymbalComp.AimLerpSpeed);
			MoveComp.SetTargetFacingRotation(CurrentFacingRotation);
			CymbalComp.CurrentAimRotationSpeed = AngularDistance;
			SyncedYawRotation.Value = CymbalComp.CurrentAimRotationSpeed;

			if(WasActionStarted(ActionNames::AimShoulderSwap))
			{
				FHazeDelegateCrumbParams CrumbParams;
				CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_SwapCameraAimSettings"), CrumbParams);
			}
		}
		else
		{
			CymbalComp.CurrentAimRotationSpeed = SyncedYawRotation.Value;
		}

		bWasAirborne = bIsAirborne;
	}

	private bool IsAirborne() const
	{
		return MoveComp.IsAirborne();
	}

	UFUNCTION()
	private void Crumb_SwapCameraAimSettings(FHazeDelegateCrumbData CrumbData)
	{
		CymbalComp.SwapCameraAimSettings();
	}
}
