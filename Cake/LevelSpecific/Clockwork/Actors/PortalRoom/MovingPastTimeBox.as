import Vino.Interactions.InteractionComponent;

event void FMovingPastTimeBoxInteractionStateChangedSignature(AHazePlayerCharacter player);

class AMovingPastTimeBox : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UInteractionComponent InteractionComp;
	default InteractionComp.RelativeLocation = FVector(0.f, 0.f, 0.f);
	default InteractionComp.RelativeRotation = FRotator(0.f, 0.f, 0.f);

	UPROPERTY()
	FMovingPastTimeBoxInteractionStateChangedSignature PlayerLeft;

	UPROPERTY()
	FMovingPastTimeBoxInteractionStateChangedSignature PlayerStartedInteracting;

	UPROPERTY()
	AStaticMeshActor PresentBox;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"BoxActivated");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float Delta)
	{

	}

	UFUNCTION()
	void BoxActivated(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		Player.AddCapability(n"MovingPastTimeBoxCapability");
		Player.SetCapabilityAttributeObject(n"PastTimeBox", this);
		Player.SetCapabilityAttributeObject(n"PresentTimeBox", PresentBox);
		InteractionComp.Disable(n"IsInteractedWith");
	}

	UFUNCTION()
	void LeverDeActivated()
	{
		InteractionComp.Enable(n"IsInteractedWith");
	}

}