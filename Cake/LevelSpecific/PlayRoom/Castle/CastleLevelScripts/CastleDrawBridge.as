class ACastleDrawbridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent EnemyCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent BridgeRoot;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LowerBridgeAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RaiseBridgeAudioEvent;

	UPROPERTY()
	float SlideTime = 0.3f;

	UPROPERTY()
	float GraceTime = 0.2f;

	UPROPERTY()
	float BridgeLength = 1750.f;

	UPROPERTY()
	bool bStartLowered = false;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	private bool bWantLowered = false;
	private bool bIsLowered = false;
	private bool bIsLowering = false;
	private bool bIsRaising = false;
	private float RaiseTime = 0.f;
	private float CurPosition = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bStartLowered)
		{
			SetPosition(1.f);
			CurPosition = 1.f;
			bWantLowered = true;
			bIsLowered = true;
		}
		else
		{
			SetPosition(0.f);
		}
	}

	UFUNCTION()
	void RaiseBridge()
	{
		SetActorTickEnabled(true);
		bWantLowered = false;
		RaiseTime = Time::GetGameTimeSeconds();
		UHazeAkComponent::HazePostEventFireForget(RaiseBridgeAudioEvent, this.GetActorTransform());
	}

	UFUNCTION()
	void LowerBridge()
	{
		SetActorTickEnabled(true);
		bWantLowered = true;
		UHazeAkComponent::HazePostEventFireForget(LowerBridgeAudioEvent, this.GetActorTransform());
	}

	void SetPosition(float Position)
	{
		BridgeRoot.RelativeLocation = FVector::ForwardVector * BridgeLength * (1.f - Position) * -1.f;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{			
		if (bIsRaising)
		{
			CurPosition = FMath::FInterpConstantTo(CurPosition, 0.f, DeltaTime, 1.f / SlideTime);
			SetPosition(CurPosition);

			if (CurPosition <= 0.f)
			{
				EnemyCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
				bIsRaising = false;
				bIsLowered = false;
			}
		}
		else if (bIsLowering)
		{
			CurPosition = FMath::FInterpConstantTo(CurPosition, 1.f, DeltaTime, 1.f / SlideTime);
			SetPosition(CurPosition);
			EnemyCollision.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

			if (CurPosition >= 1.f)
			{
				bIsLowering = false;
				bIsLowered = true;
			}
		}
		else if (bWantLowered != bIsLowered)
		{
			if (!bWantLowered)
			{
				if (Time::GetGameTimeSince(RaiseTime) > GraceTime)
				{
					bIsRaising = true;
				}
			}
			else
			{
				bIsLowering = true;
			}
		}
		else
		{
			SetActorTickEnabled(false);
		}
	}
}