import Cake.LevelSpecific.SnowGlobe.Magnetic.SnowCannon.SnowCannonActor;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;

class USnowCannonVerticalAimCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetCapability");
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

    UPrimitiveComponent MeshComponent;
	UMagnetSnowCanonComponent MagnetComponent;
	ASnowCannonActor SnowCannon;

	FRotator StartRotation;

	float MaxPitchRotation = 5.f;
	float MinPitchRotation = -40.f;

	float MinDistance = 700.f;
	float MaxDistance = 1300.67f;

	float DistancePercentage;

	float RotationSpeed;
	float CurrentPitch = 0.0f;

	float Acceleration = 25.0f;
	float Friction = 15.0f;

	float FacingSpeed = 50.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        MagnetComponent = UMagnetSnowCanonComponent::Get(Owner);
        MeshComponent = Cast<UPrimitiveComponent>(Owner.RootComponent);
		SnowCannon = Cast<ASnowCannonActor>(Owner);

		StartRotation = SnowCannon.AimRail.RelativeRotation;
		MaxDistance = MagnetComponent.GetDistance(EHazeActivationPointDistanceType::Selectable);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (IsActioning(n"PullingSnowCannon"))
			return EHazeNetworkActivation::ActivateFromControl;
        
        else
            return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsActioning(n"PullingSnowCannon"))
            return EHazeNetworkDeactivation::DontDeactivate;

        else
            return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TArray<AHazePlayerCharacter> Players;
		MagnetComponent.GetInfluencingPlayers(Players);
		if(Players.Num() <= 0)
			return;

		for(AHazePlayerCharacter Player : Players)
		{
			if(!MagnetComponent.HasOppositePolarity(UMagneticComponent::Get(Player)))
				return;

			FVector CannonBase = SnowCannon.ActorLocation - Player.MovementWorldUp * 500;
			float Distance = FMath::Max(CannonBase.Distance(Player.ActorLocation), 900.f);

			DistancePercentage = Math::Saturate((Distance - MinDistance) / (MaxDistance - MinDistance));

			float WantedPitch = -FMath::Lerp(MaxPitchRotation, MinPitchRotation, Math::Saturate(DistancePercentage));
			SnowCannon.SetCapabilityAttributeValue(n"DeltaPitch", WantedPitch - SnowCannon.AimRail.RelativeRotation.Pitch); // Read by SnowCannonAudio capbility

			SnowCannon.AimRail.SetRelativeRotation(FRotator(WantedPitch, 0.f, 0.f));
		}
	}
}