event void FOnBounce(AHazePlayerCharacter Player, bool bGroundPounded);
event void FOnRemove();

class UBouncePadResponseComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY()
	FOnBounce OnBounce;

	UPROPERTY()
	bool bPlayBounceAnimation = true;
}