import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetWheelComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Wheel.MagneticWheelActor;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Wheel.WheelPlatformActor;

class UWheelPlatformMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"LevelSpecific");
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	AWheelPlatformActor WheelPlatform;
    AMagneticWheelActor MagneticWheel;

	FVector MinCameraOffset = FVector(0,0 , 250.0f);

	float IdealCameraDistance = 1000.0f;
	float MinCameraDistance = 250.0f;

	float MinPercentage = 0.3f;

	float MaxZToAdd = 300.0f;	
	float MaxDistanceToAdd = 500.0f;	

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		WheelPlatform = Cast<AWheelPlatformActor>(Owner);
		MagneticWheel = WheelPlatform.Wheel;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (MagneticWheel == nullptr)
            return EHazeNetworkActivation::DontActivate;

        if (MagneticWheel.ActiveMagneticComponents.Num() <= 0)
            return EHazeNetworkActivation::DontActivate;
			        
        else
			return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (MagneticWheel.ActiveMagneticComponents.Num() > 0)
            return EHazeNetworkDeactivation::DontDeactivate;
		if (MagneticWheel != nullptr)
            return EHazeNetworkDeactivation::DontDeactivate;
        else
            return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	}


	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		
		float Percentage = MagneticWheel.AddedRotation / MagneticWheel.WheelSettings.MaxRotation;

		for (UMagnetGenericComponent ActiveComp : MagneticWheel.ActiveMagneticComponents)
		{
			TArray<AHazePlayerCharacter> InflueningPlayers;
			ActiveComp.GetInfluencingPlayers(InflueningPlayers);
			for(AHazePlayerCharacter Player : InflueningPlayers)
			{
				FVector PivotOffset = MinCameraOffset;
				float Distance = IdealCameraDistance;

				if(Percentage > MinPercentage)
				{
					float AddPivot = MaxZToAdd * Percentage;
					PivotOffset.Z += AddPivot;
					float AddDistance = MaxDistanceToAdd * Percentage;
					Distance += AddDistance;
				}

				FHazeCameraSpringArmSettings Settings;
				Settings.bUseIdealDistance = true;
				Settings.IdealDistance = Distance;
				Settings.MinDistance = MinCameraDistance;
				Settings.bUsePivotOffset = true;
				Settings.PivotOffset = PivotOffset;

				Player.ApplyCameraSpringArmSettings(Settings, FHazeCameraBlendSettings(1.0f), ActiveComp, EHazeCameraPriority::Maximum);

				FHazePointOfInterest PoISettings;
				PoISettings.Blend.BlendTime = 0.1f;
				PoISettings.FocusTarget.Actor = WheelPlatform;
				Player.ApplyPointOfInterest(PoISettings, ActiveComp);
			}
		}


		if(MagneticWheel.CurrentVelocity == 0.0f)
			return;
			
		FVector DeltaMovement = FVector(0, 0, MagneticWheel.CurrentVelocity * 3.1f) * DeltaTime;
		WheelPlatform.AddActorWorldOffset(DeltaMovement);

	}
}