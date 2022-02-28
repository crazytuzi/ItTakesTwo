class AMixingTableKnob : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent KnobMesh;

	float TargetMoveAlpha = 0.f;
	float CurrentMoveAlpha = 0.f;
	float MaxDist = 2000.f;

	bool bWasMoving = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentMoveAlpha = FMath::FInterpTo(CurrentMoveAlpha, TargetMoveAlpha, DeltaSeconds, 2.f);
		MeshRoot.SetRelativeLocation(FMath::Lerp(FVector::ZeroVector, FVector(800.f, 0.f, 0.f), CurrentMoveAlpha));
		GetDistanceToCharacter();		
	}

	void GetDistanceToCharacter()
	{
		float CodyDist = (FVector2D(Game::GetCody().ActorLocation.X, Game::GetCody().ActorLocation.Y) - FVector2D(ActorLocation.X, ActorLocation.Y)).Size(); 
		float MayDist = (FVector2D(Game::GetMay().ActorLocation.X, Game::GetMay().ActorLocation.Y) - FVector2D(ActorLocation.X, ActorLocation.Y)).Size(); 

		if (CodyDist < MaxDist || MayDist < MaxDist)
		{
			float DistToUse = CodyDist <= MayDist ? CodyDist : MayDist;
			TargetMoveAlpha = FMath::GetMappedRangeValueClamped(FVector2D(MaxDist, 750.f), FVector2D(0.f, 1.f), DistToUse);
		}
	}
}