import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.HarpoonPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetHarpoonActor;
import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetFishActor;
import Vino.Camera.Settings.CameraPointOfInterestBehaviourSettings;

class UHarpoonPlayerAimCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HarpoonPlayerAimCapability");
	default CapabilityTags.Add(n"MagnetHarpoon");
	default CapabilityTags.Add(CapabilityTags::Input);

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UHarpoonPlayerComponent PlayerComp;

	AMagnetHarpoonActor MagnetHarpoon;

	UCameraUserComponent UserComp;

	FHazeAcceleratedRotator AccelRot;

	float TraceDistance = 2500.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UHarpoonPlayerComponent::Get(Player);
		UserComp = UCameraUserComponent::Get(Player);
		MagnetHarpoon = Cast<AMagnetHarpoonActor>(GetAttributeObject(n"MagnetHarpoon"));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		AddAimingWidget();
		FHazePointOfInterest POI;
		
		FHazeTraceParams TraceParams;

		TraceParams.InitWithCollisionProfile(n"BlockAll");
		TraceParams.InitWithTraceChannel(ETraceTypeQuery::WeaponTrace);
		TraceParams.SetToLineTrace();
		TraceParams.IgnoreActor(MagnetHarpoon);

		TraceParams.From = MagnetHarpoon.AimPoint.WorldLocation;
		TraceParams.To = MagnetHarpoon.AimPoint.WorldLocation + MagnetHarpoon.AimPoint.ForwardVector * MagnetHarpoon.ShootDistance;

		FHazeHitResult Hit;

		FVector TraceEndPoint;
		
		if (TraceParams.Trace(Hit))
			TraceEndPoint = Hit.ImpactPoint;
		else
			TraceEndPoint = TraceParams.To;

		POI.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
		POI.FocusTarget.WorldOffset = TraceEndPoint;
		POI.bClearOnInput = true;

		UCameraPointOfInterestBehaviourSettings::SetInputClearAngleThreshold(Player, 20.f, this);
		UCameraPointOfInterestBehaviourSettings::SetInputClearDuration(Player, 0.f, this);
		UCameraPointOfInterestBehaviourSettings::SetInputClearWithinAngleDelay(Player, 0.65f, this);

		Player.ApplyPointOfInterest(POI, this, EHazeCameraPriority::High);
		
		FHazeCameraClampSettings ClampSettings;
		ClampSettings.CenterComponent = MagnetHarpoon.RootComponent;
		ClampSettings.bUseClampYawLeft = true;
		ClampSettings.bUseClampYawRight = true;
		ClampSettings.bUseClampPitchUp = true;
		ClampSettings.bUseClampPitchDown = true;
		ClampSettings.ClampYawLeft = 42.f;
		ClampSettings.ClampYawRight = 34.f;
		ClampSettings.ClampPitchDown = 35.f;
		ClampSettings.ClampPitchUp = 15.f;

		Player.ApplyCameraClampSettings(ClampSettings, CameraBlend::Normal(2.5f), this, EHazeCameraPriority::High);

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.f;
		Player.ApplyCameraSettings(PlayerComp.CamSettings, Blend, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MagnetHarpoon.PitchInput = 0.f;
		MagnetHarpoon.YawInput = 0.f;
		RemoveAimingWidget();
		Player.ClearCameraClampSettingsByInstigator(this);
		Player.ClearSettingsByInstigator(this); 
		Player.ClearCameraSettingsByInstigator(this, 1.f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		PlayerComp.AimWidget.AimWorldLocation = MagnetHarpoon.TraceEndPoint;
		SetHarpoonInputValues();
		CameraAimTrace();
		CameraToSealDot();
	}

	void SetHarpoonInputValues()
	{
		float PitchInput = 0.f;
		float YawInput = 0.f;

		PitchInput += FMath::Clamp(GetAttributeValue(AttributeNames::CameraPitch), -1.f, 1.f);
		YawInput += FMath::Clamp(GetAttributeValue(AttributeNames::CameraYaw), -1.f, 1.f);

		MagnetHarpoon.PitchInput = PitchInput;
		MagnetHarpoon.YawInput = YawInput;
		
		FRotator WorldRot = MagnetHarpoon.HarpoonRotation.Value - MagnetHarpoon.ActorRotation; //Don't use this if you want local rotation //From Anders
		WorldRot.Normalize();

		Player.SetAnimVectorParam(n"HarpoonAimAngles", FVector(WorldRot.Yaw, WorldRot.Pitch, 0.f));
	}

	void AddAimingWidget()
	{
		if (!PlayerComp.AimWidgetClass.IsValid())
			return;

		PlayerComp.AimWidget = Cast<UAimWidgetHarpoon>(Player.AddWidget(PlayerComp.AimWidgetClass));
		PlayerComp.AimWidget.CurrentPlayer = Player;
	}

	void RemoveAimingWidget()
	{
		Player.RemoveWidget(PlayerComp.AimWidget);
	}

	void CameraAimTrace()
	{
		FHazeTraceParams TraceParams;

		TraceParams.InitWithCollisionProfile(n"BlockAll");
		TraceParams.InitWithTraceChannel(ETraceTypeQuery::WeaponTrace);
		TraceParams.SetToLineTrace();
		TraceParams.IgnoreActor(Player);

		TraceParams.From = Player.ViewLocation;
		TraceParams.To = Player.ViewLocation + Player.ViewRotation.Vector() * TraceDistance;

		FHazeHitResult Hit;
		
		if (TraceParams.Trace(Hit))
			MagnetHarpoon.CameraEndPoint = Hit.ImpactPoint;
		else
			MagnetHarpoon.CameraEndPoint = TraceParams.To;

		PlayerComp.AimWidget.CurrentAimLocation = MagnetHarpoon.CameraEndPoint;
	}	

	void CameraToSealDot()
	{
		FVector HarpoonDir = MagnetHarpoon.AimPoint.ForwardVector.ConstrainToPlane(FVector::UpVector);
		HarpoonDir.Normalize();
		FVector SealDir = (MagnetHarpoon.HarpoonSeal.ActorLocation - MagnetHarpoon.AimPoint.WorldLocation).ConstrainToPlane(FVector::UpVector);
		SealDir.Normalize();
		
		MagnetHarpoon.SealCamDot = SealDir.DotProduct(HarpoonDir);
	}
}