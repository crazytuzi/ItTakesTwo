class ADiabolo : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh01;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh02;

    UPROPERTY(DefaultComponent, Attach = Root)
    UBoxComponent BoxCollision;
    
    UPROPERTY()
    float MaxDegreesToRotate;

    TArray<AActor> PlayersOnPlatform;
    FRotator TargetRotation;
    bool bShouldOnlyTiltSideways = true;
    FHazeAcceleratedRotator AcceleratedRot; 
    float RotationInterpSpeed = 1.0f;
    FRotator RotationLastTick;

	FVector TargetLoc;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"BoxBeginOverlap");
        BoxCollision.OnComponentEndOverlap.AddUFunction(this, n"BoxEndOverlap");
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float Delta)
    {
        //Root.SetRelativeRotation(AcceleratedRot.AccelerateTo(GetTiltRotation(), RotationInterpSpeed, ActorDeltaSeconds));

        //RotationLastTick = Root.RelativeRotation;

		// if (HasControl())
		// {
		// 	if (Game::GetCody().HasControl())
		// 	{
		// 		Print("Cody Has Control");
		// 	} else 
		// 	{
		// 		Print("Cody Does Not Have Control");
		// 	}

		// 	if (Game::GetMay().HasControl())
		// 	{
		// 		Print("May Has Control");
		// 		System::DrawDebugSphere(Game::GetMay().GetActorLocation());
		// 		NetSyncSphereLocation(Game::GetMay().GetActorLocation());
		// 	} else 
		// 	{
		// 		Print("May Does Not Have Control");
		// 	}

		// 	if (HasControl())
		// 	{
		// 		Print("Actor Has Control");
		// 	} else 
		// 	{
		// 		Print("Actor Does Not Have Control");
		// 	}
		// } else 
		// {
		// 	System::DrawDebugSphere(TargetLoc);
		// }
    }

	UFUNCTION(NetFunction)
	void NetSyncSphereLocation(FVector Loc)
	{
		TargetLoc = Loc;
		
	}

    UFUNCTION()
    void BoxBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
       UPrimitiveComponent OtherComponent, int OtherBodyIndex,
       bool bFromSweep, FHitResult& Hit)
       {
           if (Cast<AHazePlayerCharacter>(OtherActor) != nullptr)
           {
               PlayersOnPlatform.AddUnique(OtherActor);
           }
       }

    UFUNCTION()
    void BoxEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
       UPrimitiveComponent OtherComponent, int OtherBodyIndex)
       {
           if (Cast<AHazePlayerCharacter>(OtherActor) != nullptr)
           {
               PlayersOnPlatform.Remove(OtherActor);
           }
       }

    FRotator GetTiltRotation()
    {
        TargetRotation = FRotator::ZeroRotator;

    for (int i = 0, c = PlayersOnPlatform.Num(); i < c; i++)
    {
        FVector YDirection = FVector(PlayersOnPlatform[i].GetActorLocation() - Root.GetWorldLocation());
        YDirection.Normalize();
        float YDot = YDirection.DotProduct(Root.GetRightVector());
        YDot = YDot * 1.0f;

        FVector XDirection = FVector(PlayersOnPlatform[i].GetActorLocation() - Root.GetWorldLocation());
        float XDot = XDirection.DotProduct(Root.GetForwardVector());
        XDot = XDot * -1.0f;

        float YDotMapped = FMath::GetMappedRangeValueClamped(FVector2D(-2100.f, 2100.f), FVector2D(-MaxDegreesToRotate, MaxDegreesToRotate), YDot);
        float XDotMapped = FMath::GetMappedRangeValueClamped(FVector2D(-2100.f, 2100.f), FVector2D(-MaxDegreesToRotate, MaxDegreesToRotate), XDot);       

        if (bShouldOnlyTiltSideways)
            TargetRotation = TargetRotation.Compose(FRotator(XDotMapped, 0.0f, 0.0f));

        else 
            TargetRotation = TargetRotation.Compose(FRotator(XDotMapped, 0.0f, YDotMapped));
    }

    return TargetRotation;
    }
}