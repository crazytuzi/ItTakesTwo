import Vino.Interactions.DoubleInteractionActor;

class AFrogPondWindowDoubleInteract : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UStaticMeshComponent HandleMeshComp;

	UPROPERTY(Category = "Setup")
	ADoubleInteractionActor DoubleInteractActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(DoubleInteractActor != nullptr)
		{
			DoubleInteractActor.OnBothPlayersLockedIntoInteraction.AddUFunction(this, n"OnBothPlayersLockedIn");
			DoubleInteractActor.LeftInteraction.SetExclusiveForPlayer(EHazePlayer::May);
			DoubleInteractActor.RightInteraction.SetExclusiveForPlayer(EHazePlayer::Cody);
		}
	}

	UFUNCTION()
	void OnBothPlayersLockedIn()
	{
		
	}
}

