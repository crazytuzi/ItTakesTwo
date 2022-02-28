import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetPickupComponent;
import Vino.Pickups.PickupActor;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PickUp.MagneticPickupActor;

class UMagneticPickupAttractionCapability : UHazeCapability
{
	default CapabilityTags.Add(FMagneticTags::MagneticCapabilityTag);
	default CapabilityTags.Add(FMagneticTags::MagneticPickupCapability);
	default CapabilityTags.Add(FMagneticTags::MagneticPickupAttractionCapability);

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 199;

	default CapabilityDebugCategory = n"LevelSpecific";

	AHazePlayerCharacter PlayerCharacter;
	UMagneticPlayerComponent MagneticPlayerComponent;
	UPlayerPickupComponent PickupComponent;

	UMagnetPickupComponent MagneticPickup;

	UCameraShakeBase CameraShake;

	FVector PickupStartLocation;
	FVector PickupEndLocation;

	const float AttractionDuration = 0.1f;

	float ElapsedTime = 0.f;
	float LerpAlpha = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerCharacter = Cast<AHazePlayerCharacter>(Owner);
		MagneticPlayerComponent = UMagneticPlayerComponent::Get(Owner);
		PickupComponent = UPlayerPickupComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		UObject MagneticPickupObject = GetAttributeObject(n"MagneticPickupToAttract");
		if(MagneticPickupObject == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Get magnetic pickup
		UObject MagneticPickupObject;
		ConsumeAttribute(n"MagneticPickupToAttract", MagneticPickupObject);
		MagneticPickup = Cast<UMagnetPickupComponent>(MagneticPickupObject);

		// Setup lerping variables
		FVector PlayerToPickup = (MagneticPickup.Owner.GetActorLocation() - PlayerCharacter.GetActorLocation()).GetSafeNormal();
		PickupStartLocation = MagneticPickup.Owner.GetActorLocation();
		PickupEndLocation = PlayerCharacter.GetActorLocation() + PlayerToPickup * Cast<AMagneticPickupActor>(MagneticPickup.Owner).PickupExtents;

		// Shake dat booty
		CameraShake = PlayerCharacter.PlayCameraShake(MagneticPickup.MagneticPickupDataAsset.AttractionCameraShakeClass);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		LerpAlpha = 1.f - MagneticPickup.MagneticPickupDataAsset.AttractionAccelerationCurve.GetFloatValue(ElapsedTime / AttractionDuration);
		MagneticPickup.Owner.SetActorLocation(FMath::Lerp(PickupStartLocation, PickupEndLocation, LerpAlpha));

		PlayerCharacter.SetFrameForceFeedback(1.f, 1.f);

		ElapsedTime += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(FMath::IsNearlyEqual(LerpAlpha, 1.f, 0.05f))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Restore normal collision profile and pick up magnetic object
		AMagneticPickupActor MagneticPickupActor = Cast<AMagneticPickupActor>(MagneticPickup.Owner);
		MagneticPickup.RestorePickupMeshCollision();

		if(!PickupComponent.IsHoldingObject())
			UPlayerPickupComponent::Get(PlayerCharacter).ForcePickUp(MagneticPickupActor, true);

		// Enough with the shaking
		PlayerCharacter.StopCameraShake(CameraShake, true);

		// Cleanup
		MagneticPickup = nullptr;
		CameraShake = nullptr;
		LerpAlpha = 0.f;
		ElapsedTime = 0.f;
	}
}