import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetPickupComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PickUp.MagneticPickupActor;

class UMagneticPickupLevitationCapability : UHazeCapability
{
	default CapabilityTags.Add(FMagneticTags::MagneticCapabilityTag);
	default CapabilityTags.Add(FMagneticTags::MagneticPickupCapability);
	default CapabilityTags.Add(FMagneticTags::MagneticPickupLevitationCapability);

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 100;

	default CapabilityDebugCategory = n"LevelSpecific";

	AHazePlayerCharacter PlayerCharacter;
	UMagneticPlayerComponent MagneticPlayerComponent;

	UPlayerPickupComponent PickupComponent;
	UPlayerPickupComponent OtherPlayerPickupComponent;

	UMagnetPickupComponent MagneticPickup;
	UMeshComponent MagneticPickupMesh;

	UCameraShakeBase CameraShake;

	FVector MagneticPickupStartLocation;
	FVector LevitationPoint;

	FRotator DeltaRotation;

	float LevitationDuration = 0.35f;
	float ElapsedTime = 0.f;

	bool bLevitationCompleted;
	bool bOtherPlayerHasPickupable;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerCharacter = Cast<AHazePlayerCharacter>(Owner);
		MagneticPlayerComponent = UMagneticPlayerComponent::Get(Owner);
		PickupComponent = UPlayerPickupComponent::Get(Owner);
		OtherPlayerPickupComponent = UPlayerPickupComponent::Get(PlayerCharacter.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(PlayerCharacter.IsAnyCapabilityActive(FMagneticTags::MagneticPickupAttractionCapability))
			return EHazeNetworkActivation::DontActivate;

		UMagnetPickupComponent MagnetPickupComponent = Cast<UMagnetPickupComponent>(MagneticPlayerComponent.GetTargetedMagnet());
		if(MagnetPickupComponent == nullptr)
			return EHazeNetworkActivation::DontActivate;

		// Don't activate if attraction was cancelled and magnet is lerping back to its start position
		if(Cast<AHazeActor>(MagnetPickupComponent.Owner).IsAnyCapabilityActive(FMagneticTags::MagneticPickupCancelCapability))
			return EHazeNetworkActivation::DontActivate;

		if(MagnetPickupComponent.GetInfluencerNum() != 1)
			return EHazeNetworkActivation::DontActivate;

		if(PickupComponent.IsHoldingObject())
			return EHazeNetworkActivation::DontActivate;

		if(OtherPlayerPickupComponent.IsPuttingDownObject())
			return EHazeNetworkActivation::DontActivate;

		if(!CanPlayerPickupMagnet(MagnetPickupComponent))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControlWithValidation;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{
		SyncParams.EnableTransformSynchronizationWithTime(0.2f);
		SyncParams.AddObject(n"MagneticPickup", Cast<UMagnetPickupComponent>(MagneticPlayerComponent.GetTargetedMagnet()));
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(const FCapabilityRemoteValidationParams& ActivationParams) const
	{
		UMagnetPickupComponent MagnetPickupComponent = Cast<UMagnetPickupComponent>(ActivationParams.GetObject(n"MagneticPickup"));
		return CanPlayerPickupMagnet(MagnetPickupComponent) && !MagnetPickupComponent.IsInfluencedBy(PlayerCharacter.OtherPlayer) && !OtherPlayerPickupComponent.IsPuttingDownObject();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerCharacter.BlockCapabilities(n"Putdown", this);

		MagneticPickup = Cast<UMagnetPickupComponent>(ActivationParams.GetObject(n"MagneticPickup"));
		MagneticPickupMesh = UMeshComponent::Get(MagneticPickup.Owner);
		Cast<AMagneticPickupActor>(MagneticPickup.Owner).StartInteractionWithPlayer(PlayerCharacter, MagneticPickup);

		// Check if other player is holding same magnet pickupable and force drop it
		NetSetOtherPlayerHasPickupable(OtherPlayerIsHoldingPickupable(MagneticPickup.Owner));
		if(bOtherPlayerHasPickupable)
			OtherPlayerPickupComponent.ForceDrop(false);

		// Turn off magnetic pickup collisions
		MagneticPickup.DisablePickupMeshCollision();

		// Play some eye candy
		CameraShake = PlayerCharacter.PlayCameraShake(MagneticPickup.MagneticPickupDataAsset.LevitationCameraShakeClass);

		// Setup levitation params
		MagneticPickupStartLocation = MagneticPickup.Owner.GetActorLocation();
		LevitationPoint = MagneticPickup.Owner.GetActorLocation() + FVector::UpVector * MagneticPickup.MagneticPickupDataAsset.LevitationHeight;
		DeltaRotation = FRotator((FMath::Rand() % 200) - 100, (FMath::Rand() % 200) - 100, (FMath::Rand() % 200) - 100);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float LevitationSpeed = MagneticPickup.MagneticPickupDataAsset.LevitationAccelerationCurve.GetFloatValue(ElapsedTime / LevitationDuration);
		
		// Update fx stuff
		PlayerCharacter.SetFrameForceFeedback(LevitationSpeed, LevitationSpeed);
		CameraShake.ShakeScale = LevitationSpeed;

		// Update magnetic pickup transform
		float LerpAlpha = FMath::Min(ElapsedTime / LevitationDuration * LevitationSpeed * 2.f, 1.f);
		MagneticPickup.Owner.SetActorLocation(FMath::Lerp(MagneticPickupStartLocation, LevitationPoint, LerpAlpha));
		MagneticPickup.Owner.AddActorLocalRotation(DeltaRotation * DeltaTime);

		ElapsedTime += DeltaTime;
		if(ElapsedTime >= LevitationDuration)
			bLevitationCompleted = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bLevitationCompleted)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& SyncParams)
	{
		if(bLevitationCompleted)
			SyncParams.AddActionState(n"LevitationCompleted");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerCharacter.UnblockCapabilities(n"Putdown", this);

		// Activate pickup attraction state if levitation was completed
		if(DeactivationParams.GetActionState(n"LevitationCompleted"))
		{
			PlayerCharacter.SetCapabilityAttributeObject(n"MagneticPickupToAttract", MagneticPickup);
			MagneticPickup.SetRelativeRotation(FRotator::ZeroRotator);
		}
		else
		{
			// Stahp interaction and put pickupable back in its place
			Cast<AMagneticPickupActor>(MagneticPickup.Owner).StopInteractionWithPlayer(PlayerCharacter);

			MagneticPickup.RestorePickupMeshCollision();
			
			if(bOtherPlayerHasPickupable)
				PlayerCharacter.OtherPlayer.SetCapabilityAttributeObject(n"MagneticPickupToAttract", MagneticPickup);
			else
				MagneticPickup.CancelPickupLevitation(MagneticPickupStartLocation);
		}

		PlayerCharacter.StopCameraShake(CameraShake);

		// Cleanup
		MagneticPickupMesh = nullptr;
		MagneticPickup = nullptr;
		CameraShake = nullptr;

		ElapsedTime = 0.f;

		bLevitationCompleted = false;
		bOtherPlayerHasPickupable = false;
	}

	bool CanPlayerPickupMagnet(UMagnetPickupComponent& MagnetPickupComponent) const
	{
		UMagneticPlayerComponent OtherPlayerMagneticComponent = UMagneticPlayerComponent::Get(PlayerCharacter.OtherPlayer);
		OtherPlayerMagneticComponent.QueryMagnets();

		// Perform further checks if other player is also targeting a pickupable magnet
		UMagnetPickupComponent OtherPlayerTargetedMagnet = Cast<UMagnetPickupComponent>(OtherPlayerMagneticComponent.GetTargetedMagnet());
		if(OtherPlayerTargetedMagnet != nullptr)
		{
			bool bIsOtherPlayerUsingMagnet = IsNetworked() ?
				OtherPlayerTargetedMagnet.GetInfluencerNum() != 0 :
				PlayerCharacter.OtherPlayer.IsAnyCapabilityActive(FMagneticTags::MagneticPickupCapability);

			// If both players are targeting the same magnet and attempting to use it, bail!
			if(bIsOtherPlayerUsingMagnet && MagnetPickupComponent.Owner == OtherPlayerTargetedMagnet.Owner)
				return false;
		}

		AMagneticPickupActor MagneticPickupActor = Cast<AMagneticPickupActor>(MagnetPickupComponent.Owner);
		return MagneticPickupActor.CanPlayerPickUp(PlayerCharacter);
	}

	bool OtherPlayerIsHoldingPickupable(AActor PickupableActor)
	{
		return OtherPlayerPickupComponent.CurrentPickup == PickupableActor;
	}

	UFUNCTION(NetFunction)
	void NetSetOtherPlayerHasPickupable(bool bNetOtherPlayerHasPickupable)
	{
		bOtherPlayerHasPickupable = bNetOtherPlayerHasPickupable;
	}
}