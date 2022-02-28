import Vino.Pickups.PlayerPickupComponent;
import Vino.Audio.Movement.PlayerMovementAudioComponent;

// Will be active for as long as the player is holding a pickup,
// UPlayerVelocityDataUpdateCapability will set travesal type to HeavyWalk for as long as this capability is active
class UPickupAudioCapability : UHazeCapability
{
	default CapabilityTags.Add(PickupTags::PickupSystem);
	default CapabilityTags.Add(PickupTags::PickupAudioCapability);

	AHazePlayerCharacter PlayerOwner;
	UPlayerPickupComponent PlayerPickupComponent;
	UHazeAkComponent HazeAkComponent;

	APickupActor PickupActor;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PlayerPickupComponent = UPlayerPickupComponent::Get(Owner);
		HazeAkComponent = UHazeAkComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!PlayerPickupComponent.IsHoldingObject())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PickupActor = PlayerPickupComponent.CurrentPickup;
		if(PickupActor.PickUpAudioEvent != nullptr)
			HazeAkComponent.HazePostEvent(PickupActor.PickUpAudioEvent);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!PlayerPickupComponent.IsHoldingObject())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(PickupActor == nullptr)
			return;

		if(PickupActor.PutDownAudioEvent != nullptr && PlayerPickupComponent.ConsumeShouldPlayPutdownSound())
			HazeAkComponent.HazePostEvent(PickupActor.PutDownAudioEvent);

		// Cleanup
		PickupActor = nullptr;
	}
}