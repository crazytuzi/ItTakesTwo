import Cake.LevelSpecific.Hopscotch.Baseball.BaseballRotatingBall;
import Cake.LevelSpecific.Hopscotch.Baseball.BaseballPlayerComponent;
class ABaseballToyFigurine : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent StaticMesh;
	UPROPERTY(DefaultComponent)
	USceneComponent BaseballBatImpactLocation;
	UPROPERTY(DefaultComponent, Attach = BaseballBatImpactLocation)
	UBoxComponent BaseballBatSphereComponentFront;
	UPROPERTY(DefaultComponent, Attach = BaseballBatImpactLocation)
	UBoxComponent BaseballBatSphereComponentBack;
	UPROPERTY(DefaultComponent)
	USceneComponent BaseballBatImpactEffectLocation;
	UPROPERTY()
	ABaseballRotatingBall Baseball;
	AHazePlayerCharacter ControlSidePlayer;

	UPROPERTY()
	UBlendSpace CrankBS;
	UPROPERTY()
	AHazeSkeletalMeshActor Crank;

	UBaseballPlayerComponent BaseballPlayerComponent;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent FigurineHazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlaySwingRetractLoopAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopSwingRetractLoopsAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LeverAudioEvent;

	FHazeAcceleratedFloat AcceleratedFloat;
	float NormalizedSwingValue = 0;
	UPROPERTY()
	UNiagaraSystem BallImpactVFX;
	UPROPERTY()
	float BatSwingValue;
	UPROPERTY()
	float BatSwingStartValue;
	float TargetPitchValue = 0;
	float RotateTargetValue;
	bool bSwingJustHappend = false;
	UPROPERTY()
	bool bLeftP1;
	bool SwingingForward = true;
	FVector EffectLocation;
	FRotator EffectRotation;
	bool bRetractTimerActive = false;
	bool bPlayerTryingToSwing = false;
	bool bAllowPlayStartSwingSound = true;
	bool bAllowPlayRetractSwingSound = true;
	float StartSwingSoundTimer;
	float RetractSwingSoundTimer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RotateTargetValue = BatSwingStartValue;
		TargetPitchValue = RotateTargetValue;
		AcceleratedFloat.Value = TargetPitchValue;
		BaseballBatSphereComponentFront.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlapFront");
		BaseballBatSphereComponentBack.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlapBack");
		Baseball.OnSpawnHitEffect.AddUFunction(this, n"SpawnHitEffect");
		EffectLocation = BaseballBatImpactEffectLocation.GetWorldLocation();
		EffectRotation = BaseballBatImpactEffectLocation.GetWorldRotation();

		if(bLeftP1)
		{
			SetControlSide(Game::May);
			ControlSidePlayer = Game::GetMay();
		}
		else
		{

			SetControlSide(Game::Cody);
			ControlSidePlayer = Game::GetCody();
		}
	}

	UFUNCTION()
	void Activate()
	{
		SetActorTickEnabled(true);

		if(Crank != nullptr)
			Crank.PlayBlendSpace(CrankBS);
	}

	UFUNCTION()
	void Deactivate()
	{
		SetActorTickEnabled(false);
		
		if(Crank != nullptr)
			Crank.StopBlendSpace();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//PrintToScreen("AcceleratedFloat.Value " + AcceleratedFloat.Value);

		//PrintToScreen("SwingingForward " + SwingingForward);

		if(SwingingForward)
			AcceleratedFloat.SpringTo(RotateTargetValue, 385, 0.85f, DeltaSeconds);
		if(!SwingingForward)
			AcceleratedFloat.SpringTo(RotateTargetValue, 100, 0.85f, DeltaSeconds);

		if(bLeftP1)
		{
			NormalizedSwingValue = FMath::Abs((AcceleratedFloat.Value /(120) + 0.5f)); 
		}
		else
		{
			NormalizedSwingValue = FMath::Abs((AcceleratedFloat.Value /(120) - 0.5f)); 
		}

		NormalizedSwingValue = FMath::GetMappedRangeValueClamped(FVector2D(0.05f,0.95f), FVector2D(0.f,1.f), NormalizedSwingValue);

		if(NormalizedSwingValue < 0.05)
		{
			StartSwingSoundTimer -= DeltaSeconds;

			if(StartSwingSoundTimer < 0)
			{
				bAllowPlayStartSwingSound = true;
			}
		}
		if(NormalizedSwingValue > 0.95)
		{
			RetractSwingSoundTimer -= DeltaSeconds;

			if(RetractSwingSoundTimer < 0)
			{
				bAllowPlayRetractSwingSound = true;
			}
		}
		
		FigurineHazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Minigames_Baseball_NormalizedSwingValue", NormalizedSwingValue); 
		//PrintToScreen("NormalizedSwingValue " + NormalizedSwingValue);
		
		if(ControlSidePlayer == Game::GetMay())
		{
			BaseballPlayerComponent = Cast<UBaseballPlayerComponent>(ControlSidePlayer.GetComponentByClass(UBaseballPlayerComponent::StaticClass()));
		}
		else if(ControlSidePlayer == Game::GetCody())
		{
			BaseballPlayerComponent = Cast<UBaseballPlayerComponent>(ControlSidePlayer.GetComponentByClass(UBaseballPlayerComponent::StaticClass()));
		}

		if(BaseballPlayerComponent != nullptr)
			BaseballPlayerComponent.BlendSpaceValue = NormalizedSwingValue;

		if(Crank != nullptr)
			Crank.SetBlendSpaceValues(NormalizedSwingValue, NormalizedSwingValue, false);
	

		TargetPitchValue = AcceleratedFloat.Value;
		FHitResult Hit;
		SetActorRelativeRotation(FRotator(0, TargetPitchValue, 0), false, Hit, true);
	}

	
	UFUNCTION(NetFunction)
	void Swing()
	{
		if(bSwingJustHappend)
			return;
	
		SwingingForward = true;
		bSwingJustHappend = true;
		bRetractTimerActive = false;
		RotateTargetValue = BatSwingValue;

		StartSwingSoundTimer = 0.15f;
		
		if(bAllowPlayStartSwingSound)
		{
			FigurineHazeAkComp.HazePostEvent(LeverAudioEvent);
			bAllowPlayStartSwingSound = false;
		}
	}
	UFUNCTION(NetFunction)
	void RetractSwing()
	{
		if(bRetractTimerActive)
			return;

		bRetractTimerActive = true;
		System::SetTimer(this, n"RetractSwingTimer", 0.20f, false);
		RetractSwingSoundTimer = 0.40f;
		
		if(bAllowPlayRetractSwingSound)
		{
			FigurineHazeAkComp.HazePostEvent(LeverAudioEvent);
						bAllowPlayRetractSwingSound = false;
		}
	}
	UFUNCTION()
	void RetractSwingTimer()
	{
		SwingingForward = false;
		bSwingJustHappend = false;
		bRetractTimerActive = false;
	 	RotateTargetValue = BatSwingStartValue;

		if(bPlayerTryingToSwing == true)
		{
			if(ControlSidePlayer.HasControl())
				Swing();
		}
	}

	UFUNCTION(NetFunction)
	void SpawnHitEffect()
	{
		Niagara::SpawnSystemAtLocation(BallImpactVFX, EffectLocation, EffectRotation);
		//PrintToScreen("HIT VFX!", 1);
	}

	UFUNCTION()
	void OnComponentBeginOverlapFront(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
	UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if(OtherActor == Baseball)
		{
			if(ControlSidePlayer.HasControl())
			{
				if(SwingingForward)
					Baseball.Impacted(true);
			}
		}
	}
	UFUNCTION()
	void OnComponentBeginOverlapBack(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
	UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if(OtherActor == Baseball)
		{
			if(ControlSidePlayer.HasControl())
			{
				Baseball.Impacted(false);
			}
		}
	}
}
