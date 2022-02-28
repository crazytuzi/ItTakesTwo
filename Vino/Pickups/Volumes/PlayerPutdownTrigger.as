import Peanuts.Triggers.PlayerTrigger;
import Vino.Pickups.PlayerPickupComponent;

class APlayerPutdownTrigger : APlayerTrigger
{
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");

	UPROPERTY()
	bool bPlayPutdownAnimation = true;

	UPROPERTY()
	bool bPlayPutdownSound = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEntered");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeft");
		Super::BeginPlay();
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerEntered(AHazePlayerCharacter PlayerCharacter)
	{
		UPlayerPickupComponent PlayerPickupComponent = UPlayerPickupComponent::Get(PlayerCharacter);
		PlayerPickupComponent.bPlayerIsStandingInPutdownVolume = true;
		if(!PlayerPickupComponent.IsHoldingObject())
			return;

		// Consume some inputs
		PlayerCharacter.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);
		PlayerCharacter.ConsumeButtonInputsRelatedTo(ActionNames::MovementSprint);

		// Drop that shit like a sick tune on a friday night!
		PlayerPickupComponent.ForceDrop(bPlayPutdownAnimation, bPlayPutdownSound);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerLeft(AHazePlayerCharacter PlayerCharacter)
	{
		UPlayerPickupComponent PlayerPickupComponent = UPlayerPickupComponent::Get(PlayerCharacter);
		PlayerPickupComponent.bPlayerIsStandingInPutdownVolume = false;
	}
}