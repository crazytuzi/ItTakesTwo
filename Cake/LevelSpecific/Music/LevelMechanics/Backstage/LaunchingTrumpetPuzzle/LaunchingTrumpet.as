import Cake.LevelSpecific.Music.Singing.SongReactionComponent;

class ALaunchingTrumpet : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent TrumpetMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent LaunchCollision;
	
	UPROPERTY(DefaultComponent)
	USongReactionComponent SongReaction;

	UPROPERTY()
	AActor ActorToLaunchTo;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SongReaction.OnPowerfulSongImpact.AddUFunction(this, n"PowerfulSongImpact");
	}

	UFUNCTION(NotBlueprintCallable)
	void PowerfulSongImpact(FPowerfulSongInfo Info)
	{
		TArray<AActor> ActorArray;
		LaunchCollision.GetOverlappingActors(ActorArray);

		AHazePlayerCharacter Player;

		if (ActorArray.Num() <= 0)
			return;

		for (AActor Actor : ActorArray)
		{
			Player = Cast<AHazePlayerCharacter>(Actor);
			if (Player != nullptr)
				break;
		}

		FHazeJumpToData JumpData;
		JumpData.Transform = ActorToLaunchTo.GetActorTransform();
		JumpData.AdditionalHeight = 2500.f;
		JumpTo::ActivateJumpTo(Player, JumpData);
	}
}