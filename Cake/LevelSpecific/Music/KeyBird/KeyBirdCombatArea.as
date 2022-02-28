import Cake.SteeringBehaviors.BoidArea;
import Cake.LevelSpecific.Music.KeyBird.KeyBirdTeam;
import Cake.SteeringBehaviors.SteeringBehaviorComponent;

import bool IsKeyBirdDead(AHazeActor) from "Cake.LevelSpecific.Music.KeyBird.KeyBird";
import void KillKeyBirdAtLocation(AHazeActor, AActor) from "Cake.LevelSpecific.Music.KeyBird.KeyBird";
import void KillKeyBird(AHazeActor) from "Cake.LevelSpecific.Music.KeyBird.KeyBird";
import bool EqualsCombatArea(AHazeActor, const AKeyBirdCombatArea) from "Cake.LevelSpecific.Music.KeyBird.KeyBird";

event void FKeyBirdBehaviorManagerDelegate(AHazeActor KeyBird, AHazeActor Target);

class AKeyBirdCombatArea : ABoidArea
{
	UPROPERTY(DefaultComponent, ShowOnActor, Attach = RootComp)
	UBoidShapeComponent CombatAreaShape;
	default CombatAreaShape.VisualizerColor = FLinearColor::Blue;

	default PrimaryActorTick.bStartWithTickEnabled = true;

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

	// Used in debug to test 
	bool bCanStealKey = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(n"KeyBirdEvaluationSeekKeyCapability");
		AddCapability(n"KeyBirdEvaluationStealKeyCapability");
	}

	private bool bDoOne = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bDoOne)
		{
			UHazeAITeam AITeam = HazeAIBlueprintHelper::GetTeam(n"KeyBirdTeam");

			if(AITeam == nullptr)
				return;

			UKeyBirdTeam KeyBirdTeam = Cast<UKeyBirdTeam>(AITeam);

			if(KeyBirdTeam == nullptr)
				return;

			KeyBirdTeam.OnKeyBirdStealKeyStart.AddUFunction(this, n"Handle_KeyBirdStealKeyStart");
			KeyBirdTeam.OnKeyBirdStealKeyStop.AddUFunction(this, n"Handle_KeyBirdStealKeyStop");
			bDoOne = true;
		}


		//SetActorTickEnabled(false);

		//Shape.DrawShape();
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
	void KillAllKeyBirds()
	{
		TArray<AHazeActor> KeyBirdCollection;
		GetAllKeyBirds(KeyBirdCollection);

		for(AHazeActor KeyBirdActor : KeyBirdCollection)
		{
			KillKeyBird(KeyBirdActor);
		}
	}

	UFUNCTION()
	void EnableSeekBehaviorOnAllBirds()
	{
		TArray<AHazeActor> KeyBirdCollection;
		GetAllKeyBirds(KeyBirdCollection);

		for(AHazeActor KeyBird : KeyBirdCollection)
		{
			USteeringBehaviorComponent Steering = USteeringBehaviorComponent::Get(KeyBird);

			if(Steering != nullptr)
			{
				Steering.bEnableSeekBehavior = true;
			}
		}
	}

	bool IsInsideCombatArea(FVector LocationToTest) const
	{
		return CombatAreaShape.IsPointOverlapping(LocationToTest);
	}

	void GetAllKeyBirds(TArray<AHazeActor>& OutKeyBirdCollection) const
	{

		UHazeAITeam AITeam = HazeAIBlueprintHelper::GetTeam(n"KeyBirdTeam");

		if(AITeam == nullptr)
			return;

		TSet<AHazeActor> Members = AITeam.GetMembers();

		OutKeyBirdCollection.Empty();
		for(AHazeActor KeyBirdActor : Members)
		{
			if(IsKeyBirdDead(KeyBirdActor))
				continue;

			if(!EqualsCombatArea(KeyBirdActor, this))
				continue;

			OutKeyBirdCollection.Add(KeyBirdActor);
		}
	}

	UFUNCTION()
	void MoveAllBirdsToActorAndDie(AActor TargetActor)
	{
		TArray<AHazeActor> KeyBirdCollection;
		GetAllKeyBirds(KeyBirdCollection);

		for(AHazeActor KeyBirdActor : KeyBirdCollection)
		{
			KillKeyBirdAtLocation(KeyBirdActor, TargetActor);
		}
	}

	UPROPERTY()
	FKeyBirdBehaviorManagerDelegate OnKeyBirdStealKey_Approach;

	UPROPERTY()
	FKeyBirdBehaviorManagerDelegate OnKeyBirdStealKey_HitPlayer;
}
