import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetPickupComponent;

class UMagneticPickupCancelCapability : UHazeCapability
{
	default CapabilityTags.Add(FMagneticTags::MagneticCapabilityTag);
	default CapabilityTags.Add(FMagneticTags::MagneticPickupCancelCapability);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazeActor HazeOwner;
	UMagnetPickupComponent MagneticPickupComponent;

	FVector StartLocation;
	FVector RevertLocation;

	FQuat StartRotation;

	const float CancelDuration = 0.1f;
	float ElapsedTime;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		MagneticPickupComponent = Cast<UMagnetPickupComponent>(SetupParams.OwningComponent);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		StartLocation = HazeOwner.GetActorLocation();
		ConsumeAttribute(n"LevitationRevertLocation", RevertLocation);

		StartRotation = Owner.RootComponent.GetRelativeTransform().Rotation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float LerpAlpha = ElapsedTime / CancelDuration;
		HazeOwner.SetActorLocation(FMath::Lerp(StartLocation, RevertLocation, LerpAlpha));
		HazeOwner.SetActorRelativeRotation(FQuat::FastLerp(StartRotation, FQuat::Identity, LerpAlpha * 1.2f).Rotator(), false, FHitResult(), true);

		ElapsedTime += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ElapsedTime >= CancelDuration)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		HazeOwner.SetActorLocation(RevertLocation);
		HazeOwner.SetActorRelativeRotation(FRotator::ZeroRotator, false, FHitResult(), true);

		HazeOwner.RemoveCapability(UMagneticPickupCancelCapability::StaticClass());
	}
}