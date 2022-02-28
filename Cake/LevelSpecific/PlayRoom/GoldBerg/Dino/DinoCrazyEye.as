class ADinosaurCrazyEye : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	FVector GetMiddlePosition() property
	{
		FVector MiddlePos = FVector::OneVector;

		for (auto Player : Game::Players)
		{
			MiddlePos += Player.ActorLocation;
		}

		MiddlePos *= 0.5f;
		return MiddlePos;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float Delta)
	{
		FVector LookDirection =  MiddlePosition - ActorLocation;
		LookDirection.Normalize();
		FRotator LookRotation = FRotator::MakeFromX(LookDirection);
		SetActorRotation(LookRotation);
	}
}