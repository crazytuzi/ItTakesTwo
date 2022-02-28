enum EWalkingState
{
    Idle,
    WalkingToLocation,
    Fleeing,
    SelfDestruct,
};

class ACritter : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USphereComponent Collider;
    default Collider.SphereRadius = 16;
    default Collider.SimulatePhysics = true;

    UPROPERTY(DefaultComponent, Attach = Collider)
    USkeletalMeshComponent Model;
    default Model.RelativeLocation = FVector(-2, 0, -16);

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {

    }

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
        LastPosition = GetActorLocation();
        WaitTime = FMath::RandRange(1.0, 4.0);
    }


    UPROPERTY()
    float speed = 0;

    UPROPERTY()
    EWalkingState CurrentState;

    FVector CurrentTarget;
    FRotator CurrentRotation;

    FVector LastPosition;

    float WaitTime = 1;
    FVector FleeingHole;


    FVector GetClosestPlayerLocation(FVector Location)
    {
        float MayDist = Game::GetMay().GetActorLocation().Distance(Location);
        float CodyDist = Game::GetCody().GetActorLocation().Distance(Location);
        float ClosestDistance = FMath::Min(MayDist, CodyDist);
        if(ClosestDistance == MayDist)
            return Game::GetMay().GetActorLocation();
        else
            return Game::GetCody().GetActorLocation();
    }
    float GetDistanceToAnyPlayer(FVector Location)
    {
        float MayDist = Game::GetMay().GetActorLocation().Distance(Location);
        float CodyDist = Game::GetCody().GetActorLocation().Distance(Location);
        return FMath::Min(MayDist, CodyDist);
    }

    void GoToIdle()
    {
        CurrentState = EWalkingState::Idle;
        WaitTime = FMath::RandRange(1.0, 4.0);
    }
    void GoToFleeing()
    {
        // Direction away from player
        CurrentState = EWalkingState::Fleeing;
        WaitTime = FMath::RandRange(1.0, 4.0);
        FVector VectorAwayFromPlayer = (GetActorLocation() - GetClosestPlayerLocation(GetActorLocation()));
        CurrentTarget = GetActorLocation() + VectorAwayFromPlayer * 1000;
    }
    void GoToWalking()
    {
        // Random direction
        CurrentState = EWalkingState::WalkingToLocation;
        FVector NewDirection = FVector(FMath::RandRange(-1, 1), FMath::RandRange(-1, 1), 0);
        NewDirection.Normalize();
        CurrentTarget = GetActorLocation() + NewDirection * FMath::RandRange(100, 400);
    }

    void MoveActorTowardsTarget(float DeltaSeconds, float MoveSpeed, float RotateSpeed = 2.0)
    {
        FVector VectorTowardsGoal = (CurrentTarget - GetActorLocation());
        VectorTowardsGoal.Normalize();
        FRotator TargetRotation = Math::MakeRotFromXZ(VectorTowardsGoal, FVector(0,0,1));
        CurrentRotation = QuatLerp(CurrentRotation, TargetRotation, DeltaSeconds * RotateSpeed);
        AddActorLocalOffset(FVector(DeltaSeconds * MoveSpeed, 0, 0));
        SetActorRotation(CurrentRotation);
        //DebugDrawVector(GetActorLocation(), VectorTowardsGoal * 100);
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
        // State switching
        if(CurrentState == EWalkingState::WalkingToLocation)
        {
            if(CurrentTarget.Distance(GetActorLocation()) < 50)
            {
                GoToIdle();
            }
        }
        else if(CurrentState == EWalkingState::Idle)
        {
            WaitTime -= DeltaSeconds;
            if(WaitTime < 0)
            {
                GoToWalking();
            }
        }
        else if(CurrentState == EWalkingState::Fleeing)
        {
            WaitTime -= DeltaSeconds;
            if(WaitTime < 0)
            {
                GoToIdle();
            }
        }
        if(GetClosestPlayerLocation(GetActorLocation()).Distance(GetActorLocation()) < 200)
        {
            GoToFleeing();
        }
        

        // State Behaviours
        if(CurrentState == EWalkingState::WalkingToLocation)
        {
            MoveActorTowardsTarget(DeltaSeconds, 100, 2);
        }
        else if(CurrentState == EWalkingState::Fleeing)
        {
            MoveActorTowardsTarget(DeltaSeconds, 200, 10);
        }
        else if(CurrentState == EWalkingState::Idle)
        {
            
        }
        //Model.RelativeLocation = FVector(0,0,0);
        //DebugDrawVector(GetActorLocation(), FVector(0, 0, 100));

        speed = (LastPosition - GetActorLocation()).Size() / 4.0;
        LastPosition = GetActorLocation();
    }


    // Utility functions

    void DebugDrawVector(FVector Location, FVector Vector, int color = 0)
    {
        int Color1 = color + 1;
        int Color2 = color + 2;
        int Color3 = color + 3;
        FVector vec = Vector;
        System::DrawDebugLine(Location, Location + vec, FLinearColor((Color1 % 3)/2.0, (Color2 % 3)/2.0, (Color3 % 3) / 2.0, 0), 0, 5);
    }

    FRotator QuatLerp(FRotator A, FRotator B, float Alpha)
    {
		FQuat AQuat(A);
		FQuat BQuat(B);
		FQuat Result = FQuat::Slerp(AQuat, BQuat, Alpha);
		Result.Normalize();
		return Result.Rotator();
    }

};