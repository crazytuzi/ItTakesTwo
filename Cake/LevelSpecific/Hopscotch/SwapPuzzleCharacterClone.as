class ASwapPuzzleCharacterClone : AHazeActor 
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UPoseableMeshComponent PoseableMeshComp;

	UPROPERTY()
	USkeletalMesh MaySkelMesh;

	UPROPERTY()
	USkeletalMesh CodySkelMesh;
	
	UPROPERTY()
	bool bShouldFollowCody;

	UPROPERTY()
	AActor PuzzleMiddlePointActor;

	FVector PuzzleMiddlePoint;

	FVector LocationLastTick;
	
	AHazePlayerCharacter PlayerToFollow;

	USkeletalMesh SkelMeshToSet;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		PlayerToFollow = bShouldFollowCody ? Game::GetCody() : Game::GetMay();
		SkelMeshToSet = bShouldFollowCody ? CodySkelMesh : MaySkelMesh;
		PoseableMeshComp.SetSkeletalMesh(SkelMeshToSet);

		PuzzleMiddlePoint = PuzzleMiddlePointActor.GetActorLocation();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float YDelta;
		YDelta = PuzzleMiddlePoint.Y - PlayerToFollow.GetActorLocation().Y;
		
		FVector LocationToSet;
		LocationToSet = FVector(PlayerToFollow.GetActorLocation().X, PlayerToFollow.GetActorLocation().Y + YDelta * 2, PlayerToFollow.GetActorLocation().Z);

		SetActorLocation(LocationToSet);
		SetActorRotation(PlayerToFollow.GetActorRotation() * -1.f);

		PoseableMeshComp.CopyPoseFromSkeletalComponent(PlayerToFollow.Mesh);
	}

	UFUNCTION()
	void InitClone()
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void DisableClone()
	{
		SetActorTickEnabled(false);
	}
}