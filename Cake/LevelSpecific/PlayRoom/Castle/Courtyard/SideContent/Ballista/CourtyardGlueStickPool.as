class ACourtyardGlueStickPool : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent Box;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	TSubclassOf<UHazeCapability> StuckCapability;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
	}

	UFUNCTION()
    void OnBeginOverlap(AActor OverlappingActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (!Player.HasControl())
			return;

		Player.SetCapabilityAttributeObject(n"GluePool", this);
		Print("StartedOverlapping: " + OtherActor.Name);
	}
}