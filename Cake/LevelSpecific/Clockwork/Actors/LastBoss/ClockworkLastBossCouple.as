import Vino.Interactions.InteractionComponent;

event void FInteractedWithCouple();

class AClockworkLastBossCouple : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionComp;

	UPROPERTY()
	FInteractedWithCouple InteractedWithCouple;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"Interacted");
	}

	UFUNCTION()
	void Interacted(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		Player.BlockCapabilities(n"GameplayAction", this);
    	Player.BlockCapabilities(n"Interaction", this);
    	Player.BlockCapabilities(n"Movement", this);
    	Player.BlockCapabilities(n"Falling", this);

		InteractedWithCouple.Broadcast();
	}
}