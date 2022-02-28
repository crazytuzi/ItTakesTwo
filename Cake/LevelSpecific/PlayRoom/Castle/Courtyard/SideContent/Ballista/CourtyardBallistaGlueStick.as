import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.Ballista.CourtyardGlueStickPool;
class ACourtyardBallistaGlueStick : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	TSubclassOf<ACourtyardGlueStickPool> PoolType;

	FVector Velocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Velocity = ActorForwardVector * 2000.f;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector DeltaMove = Velocity * DeltaTime;

		FVector StartLocation = ActorLocation;
		FVector EndLocation = StartLocation + DeltaMove;
		TArray<EObjectTypeQuery> Types;
		Types.Add(EObjectTypeQuery::WorldStatic);
		TArray<AActor> ActorsToIgnore;
		FHitResult Hit;
		System::LineTraceSingleForObjects(StartLocation, EndLocation, Types, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);

		if (Hit.bBlockingHit)
		{
			if (PoolType.IsValid())
				SpawnActor(PoolType, Hit.ImpactPoint, FRotator::MakeFromZ(Hit.ImpactNormal), NAME_None, false, Level);

			DestroyActor();
		}
		else
			AddActorWorldOffset(DeltaMove);
	}
}