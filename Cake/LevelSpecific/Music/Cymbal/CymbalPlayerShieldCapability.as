import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;
import Cake.LevelSpecific.Music.MusicTargetingComponent;
import Vino.Movement.Components.LedgeGrab.LedgeGrabComponent;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;
import Vino.Movement.Grinding.UserGrindComponent;

class UCymbalPlayerShieldCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"Cymbal");
	default CapabilityTags.Add(n"CymbalShield");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UCymbalComponent CymbalComp;
	UHazeSmoothSyncFloatComponent SyncedYawRotation;
	UMusicTargetingComponent TargetingComp;
	ULedgeGrabComponent LedgeGrabComp;
	UCharacterGroundPoundComponent GroundPoundComp;
	UUserGrindComponent GrindComp;

	FQuat CurrentFacingRotation;

	bool bHasAppliedCameraSettings = false;
	bool bAirborneOnActivation = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CymbalComp = UCymbalComponent::GetOrCreate(Owner);
		TargetingComp = UMusicTargetingComponent::Get(Owner);
		SyncedYawRotation = UHazeSmoothSyncFloatComponent::GetOrCreate(Owner, n"CymbalShieldAimYaw");
		LedgeGrabComp = ULedgeGrabComponent::Get(Owner);
		GroundPoundComp = UCharacterGroundPoundComponent::Get(Owner);
		GrindComp = UUserGrindComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!CymbalComp.bCymbalEquipped)
			return EHazeNetworkActivation::DontActivate;

		if (CymbalComp.bAiming)
			return EHazeNetworkActivation::DontActivate;

		if (Player.IsAnyCapabilityActive(MovementSystemTags::Dash))
			return EHazeNetworkActivation::DontActivate;

		const bool bIsLedgeGrabbing = LedgeGrabComp.CurrentState != ELedgeGrabStates::None;

		if (bIsLedgeGrabbing)
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(ActionNames::CymbalShield))
			return EHazeNetworkActivation::DontActivate;

		if(TargetingComp.bIsTargeting)
			return EHazeNetworkActivation::DontActivate;

		if(GroundPoundComp.ActiveState != EGroundPoundState::None)
			return EHazeNetworkActivation::DontActivate;

		if(GrindComp.HasActiveGrindSpline())
			return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		if(MoveComp.IsAirborne())
		{
			OutParams.AddActionState(n"IsAirborne");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{		
		bHasAppliedCameraSettings = false;
		bAirborneOnActivation = ActivationParams.GetActionState(n"IsAirborne");

		if(!bAirborneOnActivation)
		{
			CymbalComp.ApplyShieldCameraSettings();
			bHasAppliedCameraSettings = true;
		}

		
		Player.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.BlockCapabilities(MovementSystemTags::TurnAround, this);
		Player.BlockCapabilities(ActionNames::WeaponAim, this);
		Player.BlockCapabilities(MovementSystemTags::Sprint, this);
		Player.BlockCapabilities(MovementSystemTags::Crouch, this);

		Player.AddLocomotionAsset(CymbalComp.CymbalStrafe, this);

		CymbalComp.StartShielding();
		CymbalComp.ActivateShield();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(CymbalComp.bAiming)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		const bool bIsLedgeGrabbing = LedgeGrabComp.CurrentState != ELedgeGrabStates::None;

		if(bIsLedgeGrabbing)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!CymbalComp.bThrowWithoutAim)
		{
			if (!IsActioning(ActionNames::CymbalShield))
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}
		else
		{
			if(!IsActioning(ActionNames::WeaponAim))
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		if (Player.IsAnyCapabilityActive(MovementSystemTags::Dash))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(GroundPoundComp.ActiveState != EGroundPoundState::None)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(GrindComp.HasActiveGrindSpline())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CymbalComp.ClearShieldCameraSettings();
		Player.ClearLocomotionAssetByInstigator(this);

		CymbalComp.StopShielding();
		CymbalComp.AttachCymbalToBack();

		Player.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.UnblockCapabilities(MovementSystemTags::TurnAround, this);
		Player.UnblockCapabilities(ActionNames::WeaponAim, this);
		Player.UnblockCapabilities(MovementSystemTags::Sprint, this);
		Player.UnblockCapabilities(MovementSystemTags::Crouch, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(HasControl())
		{
			FVector2D VerticalInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
			const FVector ViewRotationVector = Player.ViewRotation.Vector();
			FVector TargetRotation = ViewRotationVector.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
			const float AngularDistance = FMath::Sign(Owner.ActorForwardVector.AngularDistanceForNormals(TargetRotation)) * VerticalInput.X;
			CurrentFacingRotation = FMath::QInterpTo(CurrentFacingRotation, TargetRotation.ToOrientationQuat(), DeltaTime, CymbalComp.ShieldRotationSpeed);
			CymbalComp.CurrentAimRotationSpeed = AngularDistance;
			SyncedYawRotation.Value = CymbalComp.CurrentAimRotationSpeed;

			MoveComp.ForceActorRotationWithoutUpdatingMovement(CurrentFacingRotation.Rotator());
		}
		else
		{
			CymbalComp.CurrentAimRotationSpeed = SyncedYawRotation.Value;
		}

		if(bAirborneOnActivation && !bHasAppliedCameraSettings && !MoveComp.IsAirborne())
		{
			CymbalComp.ApplyShieldCameraSettings();
			bHasAppliedCameraSettings = true;
		}
	}
}
