class ARailcartPhysicsBalloon : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BalloonMesh;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY()
	bool bGiveImpulse = true;


	UFUNCTION()
	void ActivateBalloon()
	{
		BalloonMesh.SetSimulatePhysics(true);
		

		if (!bGiveImpulse)
		{
			return;
		}
		
		FVector Randomvector = FVector::UpVector;
		
		float UpForce = 2000000.f;
		UpForce = FMath::RandRange(1500000.f,2500000.f);

		Randomvector.X = FMath::RandRange(0.f, 0.4f);
		Randomvector.Y = FMath::RandRange(0.f, 0.4f);
		BalloonMesh.AddImpulse(Randomvector * UpForce);
		
	}
}