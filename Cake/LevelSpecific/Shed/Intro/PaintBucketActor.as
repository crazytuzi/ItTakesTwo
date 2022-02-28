class APaintBucketActor : AHazeActor
{
    FVector DirectionToPlayer;
    FVector NDirectionToPlayer;

    UPROPERTY()
    float CurrentSpeed;

    float TargetSpeed;

    UPROPERTY()
    AHazePlayerCharacter PlayerRef;

    UPROPERTY()
    bool PlayerInsideBucket = false;

    UPROPERTY()
    float DistanceToPlayer = 0.f;

    UPROPERTY()
    UStaticMeshComponent BucketMesh;

    UFUNCTION()
    void SetPlayerInBucket(bool InBucket, AHazePlayerCharacter InPlayerRef)
    {
        PlayerInsideBucket = InBucket;
        PlayerRef = InPlayerRef;
    }


    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
        if(PlayerInsideBucket && PlayerRef != nullptr)
        {
            CalculateTargetVelocity();
        }
        else
        {
            TargetSpeed = 0.f;
        }

        CurrentSpeed = FMath::FInterpTo(CurrentSpeed,TargetSpeed,DeltaTime,0.5f);

        if(BucketMesh != nullptr)
            MoveBucket(DeltaTime);
    }

    void CalculateTargetVelocity()
    {
        DirectionToPlayer = PlayerRef.GetActorLocation() - GetActorLocation();
        DirectionToPlayer = Math::ConstrainVectorToDirection(DirectionToPlayer, GetActorForwardVector());
        NDirectionToPlayer = DirectionToPlayer.GetSafeNormal();
        DistanceToPlayer = GetActorLocation().Dist2D(PlayerRef.ActorLocation, GetActorRightVector());

        TargetSpeed = DistanceToPlayer * NDirectionToPlayer.X * -1;
    }

    void MoveBucket(float DeltaTime)
    {
        SetActorLocation(GetActorLocation()+(-GetActorForwardVector() * CurrentSpeed/20.f));
        BucketMesh.AddLocalRotation(FRotator(0,-CurrentSpeed * 1 * DeltaTime,0));
    }

}