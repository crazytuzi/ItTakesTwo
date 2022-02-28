import Cake.LevelSpecific.Music.Classic.MusicalFollower.MusicalFollower;

import void AddFollowerToList(AHazeActor, AMusicalFollower) from "Cake.LevelSpecific.Music.Classic.MusicalFollower.MusicalFollowerComponent";
import AMusicalFollower GetLastFollower(AHazeActor) from "Cake.LevelSpecific.Music.Classic.MusicalFollower.MusicalFollowerComponent";
import void RemoveFromList(AHazeActor, AMusicalFollower) from "Cake.LevelSpecific.Music.Classic.MusicalFollower.MusicalFollowerComponent";

event void FOnMusicalFollowerClothFoundTargetDestination(AMusicalFollower Follower);

class AMusicalFollowerClothes : AMusicalFollower
{
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeCharacterSkeletalMeshComponent CharacterMesh;
	
	UPROPERTY(Category = Movement)
	float VelocityMaximum = 2500.0f;

	UPROPERTY(Category = Movement)
	float Acceleration = 900.0f;

	FVector CurrentVelocity;
	
	UPROPERTY()
	FOnMusicalFollowerClothFoundTargetDestination OnMusicalFollowerClothFoundTargetDestination;

	FTimerHandle RandomizeLocationTimerHandle;

	AHazeActor Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		AddCapability(n"MusicalFollowerCollisionCapability");
		AddCapability(n"MusicalFollowerMovementCapability");
	}

	void SetNewTargetLocation()
	{
		SteeringBehavior.Seek.SetTargetLocation(SteeringBehavior.RandomLocationInBoidArea);
	}

	void SetNewTimer()
	{
		System::ClearAndInvalidateTimerHandle(RandomizeLocationTimerHandle);
		RandomizeLocationTimerHandle = System::SetTimer(this, n"Handle_RandomizeTimerDone", FMath::RandRange(5.0f, 10.0f), false);
	}

	UFUNCTION()
	void Handle_RandomizeTimerDone()
	{
		SetNewTargetLocation();
		SetNewTimer();
	}

	private void SetupFollower(AHazeActor InPlayer)
	{
		SteeringBehavior.bEnableFollowBehavior = true;

		AMusicalFollower LastMusicalFollower = GetLastFollower(InPlayer);

		if(LastMusicalFollower == nullptr)
		{
			SteeringBehavior.Follow.FollowTarget = InPlayer;
		}
		else
		{
			SteeringBehavior.Follow.FollowTarget = LastMusicalFollower;
		}

		AddFollowerToList(InPlayer, this);
		Player = InPlayer;
	}

	void HandleFoundTargetDestination()
	{
		RemoveFromList(Player, this);
		OnMusicalFollowerClothFoundTargetDestination.Broadcast(this);
		Super::HandleFoundTargetDestination();
	}
}
