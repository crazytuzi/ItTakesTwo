event void FSelfieThrowAnimComplete(AHazePlayerCharacter Player);

class USelfiePlayerImageComponent : UActorComponent
{
	UPROPERTY(Category = "Animations")
	TPerPlayer<UAnimSequence> IdleAnim;

	UPROPERTY(Category = "Animations")
	TPerPlayer<UAnimSequence> ThrowAnimation;

	UObject ImageRef;

	FSelfieThrowAnimComplete OnSelfieThrowAnimCompleteEvent;
}