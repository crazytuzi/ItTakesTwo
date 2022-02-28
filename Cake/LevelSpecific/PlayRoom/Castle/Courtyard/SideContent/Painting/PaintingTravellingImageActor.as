event void FOnPaintingImageReachedDestination();

class APaintingTravellingImageActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent TravelSystem;
	default TravelSystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent SplashOnCopySystem;
	default SplashOnCopySystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent SplashInitiateSystem;
	default SplashInitiateSystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent AkComp;

	UPROPERTY(Category = "Setup")
	AStaticMeshActor Destination;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent TravellingAudioEvent;

	FOnPaintingImageReachedDestination OnPaintingImageReachedDestination; 

	FVector A;
	FVector B;
	FVector ControlPoint;

	FRotator RelativeCanvasRot = FRotator(-75.f, -30.f, 0.f);
	FRotator StartRot;

	FHazeAcceleratedRotator AccelRot;

	FVector StartLocation;

	float Alpha;

	float Speed = 1.2f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		A = StartLocation;
		B = Destination.ActorLocation;

		Alpha = 1.f;
		SetActorTickEnabled(false);
		StartRot = SplashInitiateSystem.RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Alpha < 1.f)
		{
			FVector NextLoc = Math::GetPointOnQuadraticBezierCurve(A, ControlPoint, B, Alpha);
			SetActorLocation(NextLoc);

			AccelRot.AccelerateTo(RelativeCanvasRot, 0.8f, DeltaTime);
			SplashInitiateSystem.SetRelativeRotation(AccelRot.Value);

			Alpha += Speed * DeltaTime;	

			if (Alpha >= 1.f)
			{
				Alpha = 1.f;

				if (HasControl())
					NetBroadcastEvent();
			}
		}
	}

	void ActivateAndSetPath()
	{
		SetActorLocation(StartLocation);

		AccelRot.SnapTo(StartRot);

		Alpha = 0.f;
		ControlPoint = (A + B) / 2;
		ControlPoint += FVector (0.f, 0.f, 1500.f);

		TravelSystem.Activate();

		SplashInitiateSystem.Activate();

		SetActorTickEnabled(true);

		AkComp.HazePostEvent(TravellingAudioEvent);
		PrintToScreen("ColorVFX", 3);
	}

	UFUNCTION(NetFunction)
	void NetBroadcastEvent()
	{
		OnPaintingImageReachedDestination.Broadcast();
		
		TravelSystem.Deactivate();

		SplashOnCopySystem.Activate();
		
		SetActorTickEnabled(false);
	}
}