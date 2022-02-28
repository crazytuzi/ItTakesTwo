
import Cake.LevelSpecific.SnowGlobe.Magnetic.SnowCannon.SnowCannonActor;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;

class USnowCannonHorizontalAimCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetCapability");
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

    UPrimitiveComponent MeshComponent;
	UMagnetSnowCanonComponent MagnetComponent;
	ASnowCannonActor SnowCannon;

	float AngularVelocity = 0.0f;
	float Drag = 15.0f;
	float Acceleration = 30.0f;

	float AddedRotation = 0.0f;	

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        MagnetComponent = UMagnetSnowCanonComponent::Get(Owner);
        MeshComponent = Cast<UPrimitiveComponent>(Owner.RootComponent);
		SnowCannon = Cast<ASnowCannonActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (IsActioning(n"PullingSnowCannon"))
			return EHazeNetworkActivation::ActivateFromControl;

		if (IsActioning(n"PushingSnowCannon"))
			return EHazeNetworkActivation::ActivateFromControl;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WasActionStopped(n"PullingSnowCannon"))
            return EHazeNetworkDeactivation::DeactivateFromControl;

		if (WasActionStopped(n"PushingSnowCannon"))
            return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TArray<AHazePlayerCharacter> Players;
		MagnetComponent.GetInfluencingPlayers(Players);

		for(AHazePlayerCharacter Player : Players)
		{
			FVector ToMagnetDir = MagnetComponent.WorldLocation - MagnetComponent.Owner.ActorLocation;
			FVector ToPlayerDir = Player.ActorLocation - MagnetComponent.WorldLocation;

			FVector Forward = MagnetComponent.Owner.ActorUpVector.CrossProduct(ToMagnetDir).GetSafeNormal();
			float Force = ToPlayerDir.DotProduct(Forward);

			// Flip and reduce force vector if we're pushing
			if(MagnetComponent.HasEqualPolarity(UMagneticComponent::Get(Player)))
				Force = -Force * 0.05f;

			AngularVelocity += Force * Acceleration * DeltaTime;
			AngularVelocity -= AngularVelocity * Drag * DeltaTime;
		}

		// Only add angular velocity if it angle is within valid yaw constraint
		float AngleDelta = AngularVelocity * DeltaTime;
		if(SnowCannon.YawConstraints.IsInRange(SnowCannon.Base.RelativeRotation.Yaw + AngleDelta))
		{
			SnowCannon.Base.AddLocalRotation(FRotator(0.f, AngleDelta, 0.f));
			AddedRotation += AngleDelta;

			// Read by SnowCannonAudio capability
			SnowCannon.SetCapabilityAttributeValue(n"DeltaYaw", AngleDelta);
		}
	}
}