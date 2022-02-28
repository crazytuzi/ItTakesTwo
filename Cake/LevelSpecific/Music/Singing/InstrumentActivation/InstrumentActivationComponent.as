UCLASS(HideCategories = "Activation Cooking Tags AssetUserData Collision")
class UInstrumentActivationComponent : UActorComponent
{
	UPROPERTY()
	FName ActionState;

	void ActivateInstrument(AHazePlayerCharacter Player)
	{
		Player.SetCapabilityActionState(ActionState, EHazeActionState::ActiveForOneFrame);
	}

	void DeactivateInstrument()
	{

	}
}