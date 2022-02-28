import Vino.Interactions.DoubleInteractionActor;

class ALighthouseSwitch : ADoubleInteractionActor
{
	UPROPERTY(DefaultComponent, Attach = LeftInteraction)
	UStaticMeshComponent LeftSwitch;

	UPROPERTY(DefaultComponent, Attach = RightInteraction)
	UStaticMeshComponent RightSwitch;
}