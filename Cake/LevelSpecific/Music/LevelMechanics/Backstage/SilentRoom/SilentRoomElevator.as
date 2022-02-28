import Vino.Bounce.BounceComponent;
class ASilentRoomElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent BounceRoot;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UBounceComponent BounceComp;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UStaticMeshComponent Mesh01;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UStaticMeshComponent Mesh02;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UStaticMeshComponent Mesh03;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UStaticMeshComponent Mesh04;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ElevatorUpAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ElevatorDownAudioEvent;

	UPROPERTY()
	FHazeTimeLike RaiseElevatorTimeline;
	default RaiseElevatorTimeline.Duration = 0.5f;

	float GoingDownTimerMax = 6.5f;
	float GoingDownTimer = 0.f;
	bool bShouldTickGoingDownTimer = false;

	float StartingLocZ = 0.f;
	float TargetLocZ = 1500.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RaiseElevatorTimeline.BindUpdate(this, n"RaiseElevatorTimelineUpdate");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// if (bShouldTickGoingDownTimer)
		// {
		// 	GoingDownTimer -= DeltaTime;
		// 	if (GoingDownTimer <= 0.f)
		// 	{
		// 		bShouldTickGoingDownTimer = false;
		// 		RaiseElevator(false);
		// 	}
		// }	
	}
	
	UFUNCTION()
	void RaiseElevatorTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(FMath::Lerp(FVector(0.f, 0.f, StartingLocZ), FVector(0.f, 0.f, TargetLocZ), CurrentValue));
	}

	UFUNCTION()
	void RaiseElevator(bool bGoingUp)
	{
		if(bGoingUp)
		{
			bShouldTickGoingDownTimer = true;
			GoingDownTimer = GoingDownTimerMax;
			RaiseElevatorTimeline.PlayWithAcceleration(.5f);
			UHazeAkComponent::HazePostEventFireForget(ElevatorUpAudioEvent, this.GetActorTransform());
		}
		else
		{
			RaiseElevatorTimeline.Reverse();
			UHazeAkComponent::HazePostEventFireForget(ElevatorDownAudioEvent, this.GetActorTransform());
		}
			
	}
}