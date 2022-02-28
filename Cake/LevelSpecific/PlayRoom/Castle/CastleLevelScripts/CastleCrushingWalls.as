import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;

class ACastleCrushingWalls : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UStaticMeshComponent CrusherLeft;
	
	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UStaticMeshComponent CrusherRight;
	
	UPROPERTY(DefaultComponent, Attach = CrusherLeft)
	UBoxComponent CrusherLeftCollider;

	UPROPERTY(DefaultComponent, Attach = CrusherRight)
	UBoxComponent CrusherRightCollider;

	TArray<AHazeActor> OverlappingLeftCollider;
	TArray<AHazeActor> OverlappingRightCollider;

	FHazeTimeLike CrusherMovement;	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CrusherLeftCollider.OnComponentBeginOverlap.AddUFunction(this, n"LeftColliderBeginOverlap");
		CrusherRightCollider.OnComponentBeginOverlap.AddUFunction(this, n"RightColliderBeginOverlap");

		CrusherLeftCollider.OnComponentEndOverlap.AddUFunction(this, n"LeftColliderEndOverlap");
		CrusherLeftCollider.OnComponentEndOverlap.AddUFunction(this, n"RightColliderEndOverlap");
	}

	void CrusherBeginOverlap(bool bLeftCollider, AActor OtherActor)
	{
		AHazeActor OtherHazeActor;
		OtherHazeActor = Cast<AHazeActor>(OtherActor);

		// Check and add to the correct array 
		if (Cast<AHazePlayerCharacter>(OtherActor) != nullptr ||
			Cast<ACastleEnemy>(OtherActor) != nullptr)
		{
			if (bLeftCollider)
				OverlappingLeftCollider.Add(Cast<AHazeActor>(OtherActor));
			else
				OverlappingRightCollider.Add(Cast<AHazeActor>(OtherActor));

			Print("Added " + OtherActor, 4);			
		}

		// Check if is overlapped by both colliders
		if (OverlappingLeftCollider.Contains(OtherHazeActor) && OverlappingRightCollider.Contains(OtherHazeActor))
		{
			Print("Hitting both, fam", 10);
			// Kill the actor
		}	
	}

	void CrusherEndOverlap(bool bLeftCollider, AActor OtherActor)
	{
		AHazeActor OtherHazeActor;
		OtherHazeActor = Cast<AHazeActor>(OtherActor);

		// Check and remove from the correct array 
		if (Cast<AHazePlayerCharacter>(OtherActor) != nullptr ||
			Cast<ACastleEnemy>(OtherActor) != nullptr)
		{
			if (bLeftCollider)
				OverlappingLeftCollider.Remove(Cast<AHazeActor>(OtherActor));
			else
				OverlappingRightCollider.Remove(Cast<AHazeActor>(OtherActor));

			Print("Removed " + OtherActor, 4);
		}
	}

	UFUNCTION()
    void LeftColliderBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,UPrimitiveComponent OtherComponent, int OtherBodyIndex,bool bFromSweep, FHitResult& Hit)
    {
		CrusherBeginOverlap(true, OtherActor);
	}
	UFUNCTION()
    void RightColliderBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,UPrimitiveComponent OtherComponent, int OtherBodyIndex,bool bFromSweep, FHitResult& Hit)
    {
		CrusherBeginOverlap(false, OtherActor);
	}
	UFUNCTION()
    void LeftColliderEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		CrusherEndOverlap(true, OtherActor);
	}
	UFUNCTION()
    void RightColliderEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		CrusherEndOverlap(false, OtherActor);		
	}
}