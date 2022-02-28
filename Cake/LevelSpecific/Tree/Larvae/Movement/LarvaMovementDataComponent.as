import Vino.AI.Scenepoints.ScenepointComponent;
import Vino.Movement.Components.MovementComponent;

#if TEST
const FConsoleVariable CVar_LarvaSolverTest("Haze.LarvaSolverTest", 0);
#endif

enum ELarvaMovementType 
{
	None,
    Crawl,
	Drop,
    Leap,
	Launch
}

// Component storing data set by behaviour capabilities to be used by movement capabilities
class ULarvaMovementDataComponent : UActorComponent
{
	AHazeActor HazeOwner;
    ELarvaMovementType MoveType = ELarvaMovementType::None;
    FVector Destination;
    bool bHasDestination = false;
	bool bTurnOnly = false;
	bool bUsingPathfindingCollision = false;
	UScenepointComponent CurrentScenepoint = nullptr;	

	int PathIndex = 0;
	FHaze2DPath Path;

	UPROPERTY(NotVisible, BlueprintReadWrite)
	UScenepointComponent HatchPoint = nullptr;

	UHazeMovementComponent MoveComp;	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		HazeOwner = Cast<AHazeActor>(Owner);
		ensure((MoveComp != nullptr) && (HazeOwner != nullptr));
	}

	UFUNCTION()
	void Reset()
	{
		MoveType = ELarvaMovementType::None;
		bHasDestination = false;
		CurrentScenepoint = nullptr;	
		HatchPoint = nullptr;
		HazeOwner.ChangeActorWorldUp(FVector(0.f, 0.f, 1.0f));				
		bTurnOnly = false;
	}

	void UseNonPathfindingCollisionSolver()
	{
		// This is currently cheaper than AICharacterSolver
		bUsingPathfindingCollision = false;
		MoveComp.UseCollisionSolver(n"DefaultCharacterCollisionSolver", n"DefaultCharacterRemoteCollisionSolver"); 
	}

	void UsePathfindingCollisionSolver()
	{
		bUsingPathfindingCollision = true;
		MoveComp.UseCollisionSolver(n"LarvaCollisionSolver", n"LarvaCollisionSolver");
#if TEST
	if (CVar_LarvaSolverTest.Int == 1)
		MoveComp.UseCollisionSolver(n"LarvaCollisionSolver", n"LarvaCollisionSolver"); 		
	if (CVar_LarvaSolverTest.Int == 2)
		MoveComp.UseCollisionSolver(n"MinimalAICharacterSolver", n"RemoteMinimalAICharacterSolver");
	if (CVar_LarvaSolverTest.Int == 3)
		MoveComp.UseCollisionSolver(n"AICharacterGroundedDetectionSolver", n"AICharacterGroundedDetectionSolver");
	if (CVar_LarvaSolverTest.Int == 4)
		MoveComp.UseCollisionSolver(n"AICharacterSolver", n"AICharacterRemoteCollisionSolver"); 
#endif		
	}

    void CrawlTo(const FVector& _Destination)
    {
        MoveType = ELarvaMovementType::Crawl;
        Destination = _Destination;
        bHasDestination = true;
		bTurnOnly = false;
    }

    void DropTo(const FVector& _Destination)
    {
        MoveType = ELarvaMovementType::Drop;
        Destination = _Destination;
        bHasDestination = true;
		bTurnOnly = false;
    }

    void LeapTowards(const FVector& _Destination)
    {
        // Always aim a set distance away in the given direction
        MoveType = ELarvaMovementType::Leap;
        FVector OwnLoc = GetOwner().GetActorLocation();
        Destination = OwnLoc + (_Destination - OwnLoc).GetSafeNormal() * 1000.f;
        bHasDestination = true;
		bTurnOnly = false;
    }

	void LaunchToScenepoint(UScenepointComponent Scenepoint)
	{
		if (Scenepoint == nullptr)
			return;

        MoveType = ELarvaMovementType::Launch;
        CurrentScenepoint = Scenepoint;
		bTurnOnly = false;
	}
}
