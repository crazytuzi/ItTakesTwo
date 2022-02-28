import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Crane.MagneticPlatformCraneActor;

class UMagneticCraneHorizontalAimCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetCapability");
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	//AActor Player;
	AMagneticPlatformCraneActor Crane;
    UPrimitiveComponent MeshComponent;
	UMagnetGenericComponent MagnetComponent;

	USceneComponent HorizontalAimComponent;

	float AngularVelocity = 0.0f;
	float Drag = 5.f; //10.0f;
	float Acceleration = 4.5f; //2.5f;

	float AddedRotation = 0.0f;	

	TArray<AHazePlayerCharacter> ActivePlayers;

	

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Crane = Cast<AMagneticPlatformCraneActor>(Owner);
        MagnetComponent = UMagnetGenericComponent::Get(Owner);
        MeshComponent = Cast<UPrimitiveComponent>(Owner.RootComponent);
		HorizontalAimComponent = Crane.RotatingBase;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (IsActioning(n"MagneticInteraction"))
			return EHazeNetworkActivation::ActivateFromControl;
        
        else
            return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsActioning(n"MagneticInteraction"))
            return EHazeNetworkDeactivation::DontDeactivate;

		if(!FMath::IsNearlyZero(AngularVelocity, 0.1f))
            return EHazeNetworkDeactivation::DontDeactivate;

		if (ActivePlayers.Num() > 0)
            return EHazeNetworkDeactivation::DontDeactivate;

        else
            return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// if(HorizontalAimComponent == nullptr)
		// 	HorizontalAimComponent = MagnetComponent.HorizontalAimComponent;
	}


	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			TArray<AHazePlayerCharacter> Players;
			MagnetComponent.GetInfluencingPlayers(Players);
			AddOrRemoveCameraSettingsToPlayers(Players);

			TArray<FMagnetInfluencer> Influencers;
			MagnetComponent.GetInfluencers(Influencers);
			for (const FMagnetInfluencer Influencer : Influencers)
			{
				FVector ToMagnetDir = MagnetComponent.WorldLocation - Crane.ActorLocation;
				FVector ToPlayerDir = Influencer.Influencer.ActorLocation - MagnetComponent.WorldLocation;

				FVector Forward = Crane.ActorUpVector.CrossProduct(ToMagnetDir);
				Forward.Normalize();
				float Force = ToPlayerDir.DotProduct(Forward);

				if(!MagnetComponent.HasOppositePolarity(UMagneticComponent::Get(Influencer.Influencer)))
				{
					Force = -Force * 1.5f;
				}
					
				AngularVelocity += Force * Acceleration * DeltaTime;
			}

			AngularVelocity -= AngularVelocity * Drag * DeltaTime;

			// if (HorizontalAimComponent.RelativeRotation.Yaw > 0 && AngularVelocity * DeltaTime > 0)
			// {
			// 	return;
			// }
			// //-160
			// if (HorizontalAimComponent.RelativeRotation.Yaw < -90 && AngularVelocity * DeltaTime < 0)
			// {
			// 	return;
			// }

			HorizontalAimComponent.AddLocalRotation(FRotator(0,  AngularVelocity *  DeltaTime, 0));
			AddedRotation += AngularVelocity *  DeltaTime;

			Crane.RotationSync.Value = HorizontalAimComponent.RelativeRotation;
		}
		else
		{
			HorizontalAimComponent.SetRelativeRotation(Crane.RotationSync.Value);
		}
	}

	void AddOrRemoveCameraSettingsToPlayers(TArray<AHazePlayerCharacter> Players)
	{	
		if(Players.Num() > 0)
		{
			if(ActivePlayers.Num() > 0)
			{
				for(AHazePlayerCharacter ActivePlayer : ActivePlayers)
				{
					if(Players.Contains(ActivePlayer))
						return;
					else
						ActivePlayers.Remove(ActivePlayer);
				}
			}

			for(AHazePlayerCharacter Player : Players)
			{
				if(ActivePlayers.Contains(Player))
					return;
				
				else
				{
					FHazeCameraBlendSettings CamBlend;
					CamBlend.BlendTime = 0.5f;
					
					if (MagnetComponent.HasOppositePolarity(UMagneticComponent::Get(Player)))
					{
						Player.ApplyCameraSettings(Crane.CameraSettings, CamBlend, MagnetComponent, EHazeCameraPriority::Medium);

						FHazePointOfInterest PoISettings;
						PoISettings.Blend.BlendTime = 1.f;
						PoISettings.FocusTarget.Component = Crane.PointOfInterest;
						Player.ApplyPointOfInterest(PoISettings, MagnetComponent);
					}

					ActivePlayers.Add(Player);
				}
			}

		}
		else
		{
			if(ActivePlayers.Num() > 0)
				ActivePlayers.Empty();
		}
	}

}