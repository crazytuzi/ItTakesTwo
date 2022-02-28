class APortableSpeakerRoomGuitarAmp : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent AmpMesh;

	UPROPERTY(DefaultComponent, Attach = AmpMesh)
	UBoxComponent BoxCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent NoteFX;
	default NoteFX.bAutoActivate = false;
	
	UPROPERTY()
	AActor ActorToJumpTo;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION()
	void LaunchPlayer()
	{
		TArray<AActor> ActorArray;  
		BoxCollision.GetOverlappingActors(ActorArray);

		for (AActor Actor : ActorArray)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
			
			if (Player != nullptr)
			{
				FHazeJumpToData JumpData;
				JumpData.Transform = ActorToJumpTo.ActorTransform;
				JumpData.AdditionalHeight = 500.f;
				JumpTo::ActivateJumpTo(Player, JumpData);
			}
		}
	}

	UFUNCTION()
	void SetNoteFXActive(bool bActivate)
	{
		bActivate ? NoteFX.Activate() : NoteFX.Deactivate(); 	
	}
}