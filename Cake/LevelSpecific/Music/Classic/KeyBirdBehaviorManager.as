import Cake.LevelSpecific.Music.KeyBird.KeyBirdTeam;
import Cake.SteeringBehaviors.SteeringBehaviorComponent;
import Cake.SteeringBehaviors.BoidArea;
import Cake.SteeringBehaviors.BoidObstacleStatics;
import Cake.SteeringBehaviors.BoidShapeVisualizer;
/*
class UKeyBirdBehaviorManagerDummyComponent : UActorComponent {}

#if EDITOR

class UKeyBirdBehaviorManagerComponentVisualizer : UBoidObstacleShapeVisualizer
{
    default VisualizedClass = UKeyBirdBehaviorManagerDummyComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        if (!ensure((Component != nullptr) && (Component.Owner != nullptr)))
			return;

		AKeyBirdBehaviorManager BehaviorMgr = Cast<AKeyBirdBehaviorManager>(Component.Owner);

		if(BehaviorMgr == nullptr)
			return;

		if(BehaviorMgr.CombatArea == nullptr)
			return;

		UBoidShapeComponent BoidShape = UBoidShapeComponent::Get(BehaviorMgr.CombatArea);

		DrawBoidShape(BoidShape);
    }
}

#endif // EDITOR

event void FKeyBirdBehaviorManagerDelegate(AHazeActor KeyBird, AHazeActor Target);
*/
UCLASS(Deprecated)
class AKeyBirdBehaviorManager : AHazeActor
{
	/*UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, NotEditable)
	UKeyBirdBehaviorManagerDummyComponent DummyVisualizer;
	default DummyVisualizer.bIsEditorOnly = true;

	UPROPERTY()
	ABoidArea CombatArea;

	UPROPERTY(Category = Settings)
	bool bActivateManager = true;

	// Smallest delay between attempting to locate a key to seek towards. Final value is randomized.
	UPROPERTY(Category = "Settings|SeekKey")
	float SeekKeyFrequencyMin = 2.0f;

	// Largest delay between attempting to locate a key to seek towards. Final value is randomized.
	UPROPERTY(Category = "Settings|SeekKey")
	float SeekKeyFrequencyMax = 4.0f;

	UPROPERTY(Category = "Settings|SeekKey")
	int MaxNumKeySeekers = 1;

	// The bird that is closest to this distance is the one we prefer to pick as seeker.
	UPROPERTY(Category = "Settings|SeekKey")
	float AverageDistanceSeek = 18000.0f;

	// Smallest delay between attempting to locate a key to steal. Final value is randomized.
	UPROPERTY(Category = "Settings|StealKey")
	float StealKeyFrequencyMin = 2.5f;

	// Largest delay between attempting to locate a key to steal. Final value is randomized.
	UPROPERTY(Category = "Settings|StealKey")
	float StealKeyFrequencyMax = 5.0f;

	UPROPERTY(Category = "Settings|StealKey")
	int MaxNumKeyStealers = 1;

	// The bird that is closest to this distance is the one we prefer to pick as seeker.
	UPROPERTY(Category = "Settings|SeekKey")
	float AverageDistanceSteal = 20000.0f;

	UPROPERTY(Category = Settings)
	float RangeMaximum = 10000.0f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(n"KeyBirdEvaluationSeekKeyCapability");
		AddCapability(n"KeyBirdEvaluationStealKeyCapability");
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(CombatArea == nullptr)
			CombatArea = FindClosestBoidArea(ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UHazeAITeam AITeam = HazeAIBlueprintHelper::GetTeam(n"KeyBirdTeam");

		if(AITeam == nullptr)
			return;

		UKeyBirdTeam KeyBirdTeam = Cast<UKeyBirdTeam>(AITeam);

		if(KeyBirdTeam == nullptr)
			return;

		KeyBirdTeam.OnKeyBirdStealKeyStart.AddUFunction(this, n"Handle_KeyBirdStealKeyStart");
		KeyBirdTeam.OnKeyBirdStealKeyStop.AddUFunction(this, n"Handle_KeyBirdStealKeyStop");

		SetActorTickEnabled(false);
	}

	UFUNCTION()
	void Handle_KeyBirdStealKeyStart(AHazeActor KeyBird, AHazeActor Target)
	{
		OnKeyBirdStealKey_Approach.Broadcast(KeyBird, Target);
	}

	UFUNCTION()
	void Handle_KeyBirdStealKeyStop(AHazeActor KeyBird, AHazeActor Target, bool bSuccess)
	{
		if(bSuccess)
		{
			OnKeyBirdStealKey_HitPlayer.Broadcast(KeyBird, Target);
		}
	}

	UFUNCTION()
	void EnableSeekBehaviorOnAllBirds()
	{
		UHazeAITeam AITeam = HazeAIBlueprintHelper::GetTeam(n"KeyBirdTeam");

		if(AITeam == nullptr)
			return;

		TSet<AHazeActor> Members = AITeam.GetMembers();

		for(AHazeActor KeyBird : Members)
		{
			USteeringBehaviorComponent Steering = USteeringBehaviorComponent::Get(KeyBird);

			if(Steering != nullptr)
			{
				Steering.bEnableSeekBehavior = true;
			}
		}
	}

	UPROPERTY()
	FKeyBirdBehaviorManagerDelegate OnKeyBirdStealKey_Approach;

	UPROPERTY()
	FKeyBirdBehaviorManagerDelegate OnKeyBirdStealKey_HitPlayer;
	*/
}
