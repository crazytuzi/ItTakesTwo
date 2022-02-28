event void FPillowFloorEvent(int NumberOfInstancesInPlace);

class APillowFloor : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    UInstancedStaticMeshComponent InstancedStaticMesh;

    UPROPERTY(DefaultComponent, Attach = InstancedStaticMesh)
    UStaticMeshComponent InvisiblePlatformMesh;

    UPROPERTY(DefaultComponent, Attach = InstancedStaticMesh)
    UBoxComponent BoxCollision;

    UPROPERTY()
    int MaxY;

    UPROPERTY()
    int MaxX;

    UPROPERTY()
    int TileSize;

    UPROPERTY()
    FVector MeshScale;

    UPROPERTY()
    float InterpSpeed;

    UPROPERTY()
    float HideZLength;
    default HideZLength = 10000.f;

    UPROPERTY()
    FPillowFloorEvent PillowFlorEvent;

    float HalfSize = 500.f * MeshScale.Z;

    default MaxY = 5;
    default MaxX = 5;
    default MeshScale = FVector(0.5f, 0.5f, 0.5f);
    default TileSize = 1000;
    default InterpSpeed = 5.f;
    default InvisiblePlatformMesh.bHiddenInGame = true;
    default InstancedStaticMesh.bShouldUpdatePhysicsVolume = true;

    TArray<FVector> TilesTargetLocations;
    TArray<int> PlatformsToMove;
    TArray<AHazePlayerCharacter> PlayerArray;
    int CurrentArraySize;

    UFUNCTION(CallInEditor)
    void BuildTile()
    {
        HalfSize = 500.f * MeshScale.Z;
        InstancedStaticMesh.ClearInstances();

        int y = (MaxX * MaxY);
        
        for(int i = 0; i < y; i++)
        {
            float XLocation;
            float YLocation;

            XLocation = (i / MaxY) * TileSize;
            YLocation = (i % MaxY) * TileSize;

            FTransform InstMeshTrans;
            InstMeshTrans.Location = FVector(XLocation, YLocation, 0.f);
            InstMeshTrans.Scale3D = MeshScale;

            InstancedStaticMesh.AddInstance(InstMeshTrans);
        }

        InvisiblePlatformMesh.SetWorldScale3D(FVector(MaxX * MeshScale.X, MaxY * MeshScale.Y, MeshScale.Z));
        InvisiblePlatformMesh.SetRelativeLocation(FVector((MaxX - 1) * HalfSize, (MaxY - 1) * HalfSize, -100.f));

        BoxCollision.SetBoxExtent(FVector(FVector(MaxX * HalfSize, MaxY * HalfSize, HalfSize)));
        BoxCollision.SetRelativeLocation(FVector((MaxX - 1) * HalfSize, (MaxY - 1) * HalfSize, HalfSize));
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        BuildTile();

        BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"BoxCollisionOverlap");
        BoxCollision.OnComponentEndOverlap.AddUFunction(this, n"BoxCollisionEndOverlap");

        for (int i = 0; i < InstancedStaticMesh.GetInstanceCount(); i++)
        {
            FTransform InstanceTransform;
            InstancedStaticMesh.GetInstanceTransform(i, InstanceTransform, true);

            TilesTargetLocations.Add(InstanceTransform.GetLocation());
        }

        HideInstancedMeshes();

        BoxCollision.SetBoxExtent(FVector(FVector(MaxX * HalfSize, MaxY * HalfSize, HalfSize)));
        BoxCollision.SetRelativeLocation(FVector((MaxX - 1) * HalfSize, (MaxY - 1) * HalfSize, HalfSize));
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float Delta)
    {
        if (PlayerArray.Num() != 0)
        {

            for (int i = 0; i < PlatformsToMove.Num(); i++)
            {
                if (!IsInstanceInTargetLocation(PlatformsToMove[i]) && PlatformsToMove[i] < TilesTargetLocations.Num() && PlatformsToMove[i] >= 0)
                {
                    SetInstanceLocation(PlatformsToMove[i], TilesTargetLocations[PlatformsToMove[i]], true);
                }
            }

            if (CurrentArraySize < PlatformsToMove.Num())
            {
                CurrentArraySize++;
                PillowFlorEvent.Broadcast(PlatformsToMove.Num());
            }

            for (AHazePlayerCharacter Player : PlayerArray)
            {
                int CurrentTile = GetTilePlayerStandOn(Player);

                    FVector Direction = (GetPlayerDirectionOnTile(CurrentTile, Player));
                    int AdjecentTile;
                    int X = CurrentTile % MaxX;
                    int Y = CurrentTile / MaxX;
                    X = FMath::Max(X, 0);
                    Y = FMath::Max(Y, 0);
                    float VelocityThreshold = .2f;
          
                    int AdjecentX;
                    int AdjecentY;

                    AdjecentX = X;
                    AdjecentY = Y;

                    PlatformsToMove.AddUnique(CurrentTile);

                    FVector PlayerVelocity;
                    
                    // TODO - Fix this ugly hack
                    if (GetActorRotation().Euler().Z > 170.f || GetActorRotation().Euler().Z < -170.f)
                    {
                        PlayerVelocity = Player.ActorVelocity * -1;
                    } else 
                    {
                        PlayerVelocity = Player.ActorVelocity;
                    }
                    
                    PlayerVelocity.Normalize();

                    if (PlayerVelocity.X > VelocityThreshold)
                    {
                        AdjecentY = Y + 1;
                        AdjecentTile = MaxX * AdjecentY + X;
                        
                        if (AdjecentY >= 0 && AdjecentY < MaxX && X >= 0 && X < MaxX)
                            PlatformsToMove.AddUnique(AdjecentTile);
                    
                    } else if (PlayerVelocity.X < -VelocityThreshold)
                    {
                        AdjecentY = Y - 1;
                        AdjecentTile = MaxX * AdjecentY + X;
                        
                        if (AdjecentY >= 0 && AdjecentY < MaxX && X >= 0 && X < MaxX)
                            PlatformsToMove.AddUnique(AdjecentTile);

                    } 
                    
                    if (PlayerVelocity.Y > VelocityThreshold)
                    {
                        AdjecentX = X + 1;
                        AdjecentTile = MaxX * Y + AdjecentX;
                        
                        if (Y >= 0 && Y < MaxX && AdjecentX >= 0 && AdjecentX < MaxX)
                            PlatformsToMove.AddUnique(AdjecentTile);
                    
                    } else if (PlayerVelocity.Y < -VelocityThreshold)
                    {
                        AdjecentX = X - 1;
                        AdjecentTile = MaxX * Y + AdjecentX;

                        if (Y >= 0 && Y < MaxX && AdjecentX >= 0 && AdjecentX < MaxX)
                            PlatformsToMove.AddUnique(AdjecentTile);
                    } 

                    if (AdjecentY >= 0 && AdjecentY < MaxX && AdjecentX >= 0 && AdjecentX < MaxX)
                    {
                        AdjecentTile = MaxX * AdjecentY + AdjecentX;

                        FVector StartLoc;
                        FVector EndLoc;

                        if (AdjecentTile < TilesTargetLocations.Num() && AdjecentTile >= 0)
                        {
                            StartLoc = TilesTargetLocations[AdjecentTile];
                            EndLoc = FVector(TilesTargetLocations[AdjecentTile] + FVector(0,0,500000));
                        }

                        //System::DrawDebugLine(StartLoc,EndLoc);
                        //System::DrawDebugArrow(Player.GetActorLocation(), FVector(Player.GetActorLocation() + FVector(PlayerVelocity * 200.f)));

                        PlatformsToMove.AddUnique(AdjecentTile);
                    }
                }
        }
    }


    UFUNCTION()
    void SetInstanceLocation(int Index, FVector NewLocation, bool bShouldInterp)
    {

        if (bShouldInterp)
        {
            FTransform NewTransform;
            FTransform InterpTrans;
            InstancedStaticMesh.GetInstanceTransform(Index, InterpTrans, true);
            FVector CurrentLocation = InterpTrans.Location;
            NewTransform.Location = FMath::VInterpTo(CurrentLocation, NewLocation, ActorDeltaSeconds, InterpSpeed);
            NewTransform.Scale3D = MeshScale;
            NewTransform.SetRotation(GetActorRotation());
            InstancedStaticMesh.UpdateInstanceTransform(Index, NewTransform, true, true);
        } else 
        {
            FTransform NewTransform;
            NewTransform.Location = NewLocation;
            NewTransform.Scale3D = MeshScale;
            NewTransform.SetRotation(GetActorRotation());
            InstancedStaticMesh.UpdateInstanceTransform(Index, NewTransform, true, true);
        }
    }

    UFUNCTION()
    void HideInstancedMeshes()
    {
        for (int i = 0; i < InstancedStaticMesh.GetInstanceCount(); i++)
        {
            FVector LocationToAdd = FVector (0.f, 0.f, -HideZLength);
            FTransform CurrentInstanceTransform;
            InstancedStaticMesh.GetInstanceTransform(i, CurrentInstanceTransform, true);
            FVector CurrentInstanceLocation = CurrentInstanceTransform.Location;
            SetInstanceLocation(i, FVector(CurrentInstanceLocation + LocationToAdd), false);
            
        }
    }

    UFUNCTION()
    void BoxCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {
        AHazePlayerCharacter PlayerOverlapped;
        PlayerOverlapped = Cast<AHazePlayerCharacter>(OtherActor);

        if (PlayerOverlapped != nullptr)
        {
            PlayerArray.AddUnique(PlayerOverlapped);
        }
    }

    UFUNCTION()
    void BoxCollisionEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
        AHazePlayerCharacter PlayerEndOverlap;
        PlayerEndOverlap = Cast<AHazePlayerCharacter>(OtherActor);

        if (PlayerEndOverlap != nullptr)
        {
            PlayerArray.Remove(PlayerEndOverlap);
        }
    }

    int GetTilePlayerStandOn(AHazePlayerCharacter Player)
    {
        float MinLength = 10000000.f;
        int IndexOfClosestTile;

        for (int i = 0; i < TilesTargetLocations.Num(); i++)
        {
            FVector DistanceVector = FVector(Player.GetActorLocation() - TilesTargetLocations[i]);
            float LengthToCheck = DistanceVector.Size();

            if (LengthToCheck < MinLength)
            {
                MinLength = LengthToCheck;
                IndexOfClosestTile = i;
            }
        }
        return IndexOfClosestTile;
    }

    bool IsInstanceInTargetLocation(int Index)
    {
        if (Index < TilesTargetLocations.Num() && Index >= 0)
        {
            FTransform InstTrans;
            InstancedStaticMesh.GetInstanceTransform(Index, InstTrans, true);
            
            if (TilesTargetLocations[Index] == InstTrans.Location)
                return true;

            else 
                return false;
        }

        else
        {
            return false;
        }
    }

    FVector GetInstanceLocation(int TileIndex)
    {
        FTransform InstTrans;
        InstancedStaticMesh.GetInstanceTransform(TileIndex, InstTrans, true);


        return InstTrans.Location;
    }

    // *Function not in use*
    // Gets a value between 0 and 1, where 1 is where 
    // the player is standing on an edge of a platform
    // and 0 is in the middle.
    float GetLerpValue(int TileIndex, AHazePlayerCharacter Player)
    {
        FVector Direction = FVector(Player.GetActorLocation() - TilesTargetLocations[TileIndex]);
        Direction = FVector(Direction.X, Direction.Y, 0.f);
        float Lenght = Direction.Size();
        float LengthMapped = FMath::GetMappedRangeValueClamped(FVector2D(0.f, HalfSize), FVector2D(0.f, 1.f), Lenght);

        return LengthMapped;
    }

    // Gets the direction the player is facing from
    // the middle of the a platform.
    FVector GetPlayerDirectionOnTile(int TileIndex, AHazePlayerCharacter Player)
    {
        FVector Direction = FVector(Player.GetActorLocation() - TilesTargetLocations[TileIndex]);
        Direction = FVector(Direction.X, Direction.Y, 0.f);
        Direction.Normalize();

        return Direction;
    }
}