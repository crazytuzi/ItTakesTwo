import Vino.Pickups.PickupActor;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetPickupComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;

class AMagneticPickupActor : APickupActor
{
	UPROPERTY(DefaultComponent)
	UMagnetPickupComponent MagnetPickupComponentMay;

	UPROPERTY(DefaultComponent)
	UMagnetPickupComponent MagnetPickupComponentCody;

	bool bIsBeingInteractedWith = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	void StartInteractionWithPlayer(AHazePlayerCharacter PlayerCharacter, UMagnetPickupComponent& MagnetPickupComponent)
	{
		bIsBeingInteractedWith = true;

		UMagneticPlayerComponent MagneticPlayerComponent = UMagneticPlayerComponent::Get(PlayerCharacter);
		MagneticPlayerComponent.ActivateMagnetLockon(MagnetPickupComponent, this);
	}

	void StopInteractionWithPlayer(AHazePlayerCharacter PlayerCharacter)
	{
		System::SetTimer(this, n"EnableOtherPlayerInteraction", 0.5f, false);

		UMagneticPlayerComponent MagneticPlayerComponent = UMagneticPlayerComponent::Get(PlayerCharacter);
		MagneticPlayerComponent.DeactivateMagnetLockon(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnPickedUp(AHazePlayerCharacter PlayerCharacter)
	{
		MagnetPickupComponentCody.DisabledForObjects.Add(PlayerCharacter);
		MagnetPickupComponentMay.DisabledForObjects.Add(PlayerCharacter);

		StopInteractionWithPlayer(PlayerCharacter);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnPutDown(AHazePlayerCharacter PlayerCharacter)
	{
		MagnetPickupComponentCody.DisabledForObjects.Remove(PlayerCharacter);
		MagnetPickupComponentMay.DisabledForObjects.Remove(PlayerCharacter);
	}

	UFUNCTION()
	void EnableOtherPlayerInteraction()
	{
		bIsBeingInteractedWith = false;
	}

	bool CanPlayerPickUp(AHazePlayerCharacter PlayerCharacter)
	{
		return !bIsBeingInteractedWith;
	}
}