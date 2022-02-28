
/**
 * A billboard component that only shows up when the actor it
 * is on has been disabled.
 */
class UBillboardWhenDisabledComponent : UBillboardComponent
{
	default bHiddenInGame = true;

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		if (Owner.bHidden)
			devEnsure(!Owner.bHidden, "UBillboardWhenDisabledComponent "+GetPathName()+":\nActor rendering was disabled by disable component. Set bDisableAllActorRendering to false on disable component to allow billboard to show.");
		SetHiddenInGame(false);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		SetHiddenInGame(true);
	}
};
