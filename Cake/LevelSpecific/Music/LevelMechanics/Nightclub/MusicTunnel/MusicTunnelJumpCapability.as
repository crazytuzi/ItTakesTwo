import Cake.LevelSpecific.Music.LevelMechanics.Nightclub.MusicTunnel.MusicTunnelVehicle;
import Peanuts.Outlines.Outlines;

class UMusicTunnelJumpCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"MusicTunnelJump");

	default CapabilityDebugCategory = n"AudioSurf";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	FHazeAcceleratedRotator CameraEndRotation;

	AHazePlayerCharacter Player;
	AMusicTunnelVehicle Vehicle;
	UHazeActiveCameraUserComponent CamUserComp;

	float TargetJumpLocation = -450.f;
	bool IsJumping = false;
	float Alpha = 0.f;
	float AlphaMultiplier = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CamUserComp = UHazeActiveCameraUserComponent::Get(Owner);
		Vehicle = Cast<AMusicTunnelVehicle>(GetAttributeObject(n"Vehicle"));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WasActionStarted(ActionNames::MovementJump) && !IsJumping && Vehicle.JumpAllowed)
        	return EHazeNetworkActivation::ActivateUsingCrumb;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsJumping)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AlphaMultiplier = 3.f;
		IsJumping = true;
		Player.ApplyPivotLagSpeed(FVector(1.f, 1.f, 0.f), this, EHazeCameraPriority::High);
		Player.ApplyPivotLagMax(FVector(200.f, 200.f, 400.f), this, EHazeCameraPriority::High);
		Player.SetAnimBoolParam(n"Jump", true);
		Vehicle.SetCapabilityActionState(n"MusicTunnelVehicleJumpAudioEvent", EHazeActionState::ActiveForOneFrame);
		Vehicle.SetCapabilityAttributeValue(n"MusicTunnelVehicleAudioIsJumping", 1.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this);
		Vehicle.SetCapabilityActionState(n"MusicTunnelVehicleLandAudioEvent", EHazeActionState::ActiveForOneFrame);
		Vehicle.SetCapabilityAttributeValue(n"MusicTunnelVehicleAudioIsJumping", 0.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
	
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (Vehicle != nullptr && IsJumping)
		{
			Alpha += AlphaMultiplier * DeltaTime;
			Alpha = FMath::Clamp(Alpha, 0.f, 1.f);
			float JumpAlpha = Vehicle.JumpCurve.GetFloatValue(Alpha);
			float NewZLocation = FMath::Lerp(-600.f, TargetJumpLocation, JumpAlpha);


			Vehicle.VehicleRoot.SetRelativeLocation(FVector(0.f, 0.f, NewZLocation));
			
			if (Alpha >= 1.f)
			{
				AlphaMultiplier = -3.f;
			}

			if (Alpha <= 0.f && IsJumping)
			{
				IsJumping = false;
			}
		}
	}
}