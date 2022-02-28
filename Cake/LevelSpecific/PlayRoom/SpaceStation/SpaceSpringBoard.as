UCLASS(Abstract)
class ASpaceSpringBoard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SpringRoot;

	UPROPERTY(DefaultComponent, Attach = SpringRoot)
	UStaticMeshComponent SpringMesh;

	UPROPERTY(DefaultComponent, Attach = SpringRoot)
	UStaticMeshComponent BoardMesh;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect LaunchRumble;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartSpringAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopSpringAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SpringFullyTurnedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SpringStoppedAfterReleaseAudioEvent;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.bRenderWhileDisabled = true;
	default DisableComponent.AutoDisableRange = 8000.f;

	float CurrentTension = 0.f;
	float PreviousTension = 0.f;
	float LaunchAlpha = 0.f;

	bool bMayLaunchedThisReset = false;

	FVector DefaultScale;

	bool bResetting = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DefaultScale = SpringMesh.WorldScale;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector CurScale = FMath::Lerp(DefaultScale, FVector(DefaultScale.X, DefaultScale.Y, 0.25f), CurrentTension);
		SpringMesh.SetWorldScale3D(CurScale);

		float CurBoardLoc = FMath::Lerp(400.f, 35.f, CurrentTension);
		BoardMesh.SetRelativeLocation(FVector(0.f, 0.f, CurBoardLoc));

		if (bResetting)
		{
			FVector TraceStartLoc = BoardMesh.WorldLocation - FVector(0.f, 0.f, 35.f);
			TArray<AActor> ActorsToIgnore;
			FHitResult Hit;
			System::BoxTraceSingle(TraceStartLoc, TraceStartLoc - FVector(0.f, 0.f, 36.f), FVector(120.f, 120.f, 25.f), FRotator::ZeroRotator, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);
			if (Hit.Actor != nullptr)
			{
				if (Hit.Actor == Game::GetMay() && !bMayLaunchedThisReset)
				{
					LaunchMay();
				}
			}
		}
	}

	void UpdateTension(float Tension)
	{
		PreviousTension = CurrentTension;
		CurrentTension = Tension;

		if (Game::GetMay().HasControl())
		{
			if (bResetting)
			{
				if (CurrentTension == 0.f)
				{
					bResetting = false;
					bMayLaunchedThisReset = false;
				}
			}
		}
	}

	void ValveReleased()
	{
		if (CurrentTension != 0.f)
		{
			bMayLaunchedThisReset = false;
			LaunchAlpha = CurrentTension;
			bResetting = true;
		}
	}

	void LaunchMay()
	{
		bMayLaunchedThisReset = true;
		float LaunchForce = FMath::Lerp(0.f, 6000.f, LaunchAlpha);
		Game::GetMay().AddImpulse(Game::GetMay().MovementWorldUp * LaunchForce);
		Game::GetMay().PlayForceFeedback(LaunchRumble, false, true, n"SpringBoard");
	}
}