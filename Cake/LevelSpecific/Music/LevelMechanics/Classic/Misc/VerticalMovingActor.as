import Cake.Environment.HazeSphere;
import Peanuts.Audio.AudioStatics;

event void FOnTimeLineFinishedForward(AHazePlayerCharacter Player);
event void FOnTimeLineFinishedBackwards(AHazePlayerCharacter Player);

class AVerticalMovingActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshBody;

	UPROPERTY(DefaultComponent, Attach = MeshBody)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MoveDownAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MoveUpAudioEvent;

	UPROPERTY()
	FOnTimeLineFinishedForward OnTimeLineFinishedForward;
	UPROPERTY()
	FOnTimeLineFinishedBackwards OnTimeLineFinishedBackwards;
	UPROPERTY(DefaultComponent)
	UHazeSphereComponent HazeSphereComponent;

	UPROPERTY()
	float DistanceZ;
	FVector StartLocation;
	FVector TargetLocation;
	float OriginalOpacityValue;

	FHazeTimeLike MovementTimeLike;
	default MovementTimeLike.Duration = 3.65f;

	UPROPERTY()
	AHazePlayerCharacter AttachedPlayer;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = GetActorLocation();
		TargetLocation = FVector(GetActorLocation().X, GetActorLocation().Y, (GetActorLocation().Z + DistanceZ));
		MovementTimeLike.BindUpdate(this, n"OnTimeLineUpdate");
		MovementTimeLike.BindFinished(this, n"OnTimeLineFinished");
		OriginalOpacityValue = HazeSphereComponent.Opacity;
		HazeSphereComponent.SetOpacityOverTime(0, 0);
	}

	UFUNCTION()
	void OnTimeLineUpdate(float Duration)
	{
		FVector NewLocation;
		NewLocation = FMath::Lerp(StartLocation, TargetLocation, Duration);
		SetActorLocation(NewLocation);
	}

	UFUNCTION()
	void OnTimeLineFinished()
	{
		if(MovementTimeLike.IsReversed() != true)
		{
			OnTimeLineFinishedForward.Broadcast(AttachedPlayer);
		}
		else
		{
			OnTimeLineFinishedBackwards.Broadcast(AttachedPlayer);
		}
	}

	UFUNCTION()
	void PlayTimeline()
	{
		HazeSphereComponent.SetOpacityOverTime(1.3f,0);
		MovementTimeLike.Play();
		HazeAudio::SetPlayerPanning(HazeAkComp, AttachedPlayer);
		HazeAkComp.HazePostEvent(MoveDownAudioEvent);
	}

	UFUNCTION()
	void PauseTimeline()
	{
		MovementTimeLike.Stop();
	}

	UFUNCTION()
	void ReverseTimeline()
	{
		HazeSphereComponent.SetOpacityOverTime(1.5f, OriginalOpacityValue);
		MovementTimeLike.Reverse();
		HazeAudio::SetPlayerPanning(HazeAkComp, AttachedPlayer);
		HazeAkComp.HazePostEvent(MoveUpAudioEvent);
	}
}

