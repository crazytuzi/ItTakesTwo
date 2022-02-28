UCLASS(Abstract)

event void FOnLogIsInWater();
event void FOnLogSinked();
event void FOnPlayersLeftLog();

class ASpinningLogActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RotationComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase LogSkelMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent FirstHoleCollisionMesh;
	default FirstHoleCollisionMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent SecondHoleCollisionMesh;
	default SecondHoleCollisionMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent EndOfLogCollider;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.f;
	default DisableComp.bRenderWhileDisabled = true;

	UPROPERTY(Category = "Animation")
	UAnimSequence DestroyedStateAnim;

	UPROPERTY()
	float Speed = 15.0f;

	UPROPERTY()
	float SinkingSpeed = 35.0f;

	UPROPERTY()
	float LowestZLocation = 4550.0f;

	UPROPERTY()
	bool bSinking = false;

	UPROPERTY()
	FOnLogIsInWater OnLogIsInWater;

	UPROPERTY()
	FOnLogSinked OnLogSinked;

	UPROPERTY()
	FOnPlayersLeftLog OnPlayersLeftLog;

	float SinkTimer = 0.0f;
	
	UPROPERTY(Category = "Settings")
	float DurationBeforeSinking = 60.0f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnLogIsInWater.AddUFunction(this, n"StartSinking");
		OnPlayersLeftLog.AddUFunction(this, n"StopSinking");

		SetActorTickEnabled(false);
	}

	UFUNCTION()
	void StartSinking()
	{
		SetActorTickEnabled(true);
		bSinking = true;
	}

	UFUNCTION()
	void StopSinking()
	{
		bSinking = false;
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
	{
		if(bSinking)
		{
			SinkTimer += DeltaTime;
			if(SinkTimer >= DurationBeforeSinking && bSinking)
			{
				bSinking = false;
				OnLogSinked.Broadcast();
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	void BreakFirstHole()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void BreakSecondHole()
	{

	}
}
