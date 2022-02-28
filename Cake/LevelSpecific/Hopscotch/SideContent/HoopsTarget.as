import Cake.LevelSpecific.Hopscotch.SideContent.HoopsBall;
import Cake.LevelSpecific.Hopscotch.SideContent.HoopsSettings;
import Cake.LevelSpecific.Hopscotch.SideContent.HoopsScoreWidget;
import Cake.LevelSpecific.PlayRoom.VOBanks.HopscotchVOBank;

event void FHoopScoreEvent(AHazePlayerCharacter PlayerScored, int NewScoreToAdd, FVector Location);

class AHoopsTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	// UPROPERTY(DefaultComponent, Attach = MeshRoot)
	// UStaticMeshComponent InvisibleCollision;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UStaticMeshComponent Collision;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent HitFX;

	UPROPERTY(DefaultComponent)
    UHazeAkComponent HazeAkComponent;

	UPROPERTY()
	UHopscotchVOBank VoBank;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartMachineryAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopMachineryAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartTargetLoopAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopTargetLoopAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnePointAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent TwoPointsAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ThreePointsAudioEvent;

	UPROPERTY()
	TArray<UStaticMesh> MeshArray;

	UPROPERTY(EditDefaultsOnly, Category = "Basket")
	TSubclassOf<UHoopsScoreWidget> ScoreWidgetClass;
	UHoopsScoreWidget ScoreWidgetMay;
	UHoopsScoreWidget ScoreWidgetCody;

	UPROPERTY(Category = "Basket")
	EHoopsScoreType ScoreType;

	UPROPERTY()
	FHazeTimeLike MoveTargetTimeline;
	default MoveTargetTimeline.Duration = MoveTargetDuration;

	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float PreviewLocation = 0.f;	

	UPROPERTY()
	int ScoreToAdd = 1;

	FVector StartLoc = FVector::ZeroVector;
	
	UPROPERTY(meta = (MakeEditWidget))
	FVector TargetLoc;

	UPROPERTY()
	FHoopScoreEvent HoopScoreEvent;

	UPROPERTY()
	float TargetMoveSpeedMultiplier = 1.f;

	float MoveTargetDuration = 3.f;

	float MoveValue = 0.f;
	float MoveAlpha = 0.f;

	bool bShouldMoveTargets = false;

	float HoopsTargetVelocity = 0.f;
	FVector LocLastTick = FVector::ZeroVector;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveTargetTimeline.BindUpdate(this, n"MoveTargetTimelineUpdate");
		MeshRoot.SetRelativeLocation(FVector::ZeroVector);
		Collision.OnComponentBeginOverlap.AddUFunction(this, n"BallOverlap");		
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MeshRoot.SetRelativeLocation(FMath::Lerp(StartLoc, TargetLoc, PreviewLocation));

		Mesh.SetStaticMesh(MeshArray[ScoreType]);
		//InvisibleCollision.SetStaticMesh(MeshArray[ScoreType]);

		switch(ScoreType)
		{
			case EHoopsScoreType::Low:
				// InvisibleCollision.SetRelativeLocation(FVector(0.f, 0.f, -110.f));
				// InvisibleCollision.SetRelativeScale3D(FVector(1.28f, 1.28f, 1.28f));
				Collision.SetRelativeLocation(FVector(-60.f, 0.f, -450.f));
				Collision.SetRelativeScale3D(FVector(5.2, 5.2f, 0.5f));
				break;

			case EHoopsScoreType::Medium:
				// InvisibleCollision.SetRelativeLocation(FVector(0.f, 0.f, -140.f));
				// InvisibleCollision.SetRelativeScale3D(FVector(1.3125f, 1.3125f, 1.3125f));
				Collision.SetRelativeLocation(FVector(20.f, 0.f, -250.f));
				Collision.SetRelativeScale3D(FVector(3.2f, 3.2f, 0.5f));
				break;

			case EHoopsScoreType::High:
				// InvisibleCollision.SetRelativeLocation(FVector::ZeroVector);
				// InvisibleCollision.SetRelativeScale3D(FVector(1.2f, 1.2f, 1.2f));
				Collision.SetRelativeLocation(FVector(170.f, -210.f, 20.f));
				Collision.SetRelativeScale3D(FVector(2.375f, 2.375f, 0.46f));
				break;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bShouldMoveTargets)
		{
			MoveValue += DeltaTime * TargetMoveSpeedMultiplier;
			MoveAlpha = (FMath::Sin(MoveValue) + 1) / 2;
			FVector TargetLocation = FMath::Lerp(StartLoc, TargetLoc, MoveAlpha);
			MeshRoot.SetRelativeLocation(FMath::VInterpTo(MeshRoot.RelativeLocation, TargetLocation, DeltaTime, 2.f));

			HoopsTargetVelocity = ((MeshRoot.WorldLocation - LocLastTick) / DeltaTime).Size();
			HazeAkComponent.SetRTPCValue("Rtpc_World_SideContent_Playroom_Minigame_ThrowingHoops_TargetVelocity", HoopsTargetVelocity);
			LocLastTick = MeshRoot.WorldLocation;
		}
		else
		{
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	void CreateWidgets()
	{
		ScoreWidgetMay = Cast<UHoopsScoreWidget>(Game::May.AddWidget(ScoreWidgetClass));
		ScoreWidgetMay.ScoreType = ScoreType;

		ScoreWidgetCody = Cast<UHoopsScoreWidget>(Game::Cody.AddWidget(ScoreWidgetClass));
		ScoreWidgetCody.ScoreType = ScoreType;
	}

	UFUNCTION()
	void StartMovingTarget()
	{
		bShouldMoveTargets = true;
		MoveValue = 0.f;
		AudioTargetStartedMoving();
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void StopMovingTarget()
	{
		bShouldMoveTargets = false;
		AudioTargetStoppedMoving();
	}

	UFUNCTION()
	void MoveTargetTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(FMath::Lerp(StartLoc, TargetLoc, CurrentValue));
	}

	UFUNCTION()
	void BallOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHoopsBall Ball = Cast<AHoopsBall>(OtherActor);
		if (Ball == nullptr)
			return;

		if (OtherComponent.Name != n"Sphere")
			return;

		if (!Ball.HasControl())
			return;

		if (Ball.PlayerThrown.HasControl())
		{
			NetAddScore(Ball.PlayerThrown, ScoreToAdd);	
		}
	}	

	UFUNCTION(NetFunction)
	void NetAddScore(AHazePlayerCharacter PlayerThrown, int ScoreToAdd)
	{
		HitFX.Activate();
		HoopScoreEvent.Broadcast(PlayerThrown, ScoreToAdd, HitFX.WorldLocation);
		AudioScore();
		
		// ScoreWidgetMay.SetWidgetWorldPosition(HitFX.WorldLocation);
		// ScoreWidgetMay.PlayShowAnimation();

		// ScoreWidgetCody.SetWidgetWorldPosition(HitFX.WorldLocation);
		// ScoreWidgetCody.PlayShowAnimation();

		FName Bark = PlayerThrown == Game::GetCody() ? n"FoghornDBPlayroomHopscotchThrowingHoopsTauntCody" : n"FoghornDBPlayroomHopscotchThrowingHoopsTauntMay";
		PlayFoghornVOBankEvent(VoBank, Bark);
	}

	UFUNCTION()
	void AudioScore()
	{
		switch (ScoreType)
		{
			case EHoopsScoreType::High:
				HazeAkComponent.HazePostEvent(ThreePointsAudioEvent);
				break;

			case EHoopsScoreType::Medium:
				HazeAkComponent.HazePostEvent(TwoPointsAudioEvent);
				break;

			case EHoopsScoreType::Low:
				HazeAkComponent.HazePostEvent(OnePointAudioEvent);
				break;
		}
	}

	UFUNCTION()
	void AudioTargetStartedMoving()
	{
		HazeAkComponent.HazePostEvent(StartMachineryAudioEvent);
		HazeAkComponent.HazePostEvent(StartTargetLoopAudioEvent);
	}

	UFUNCTION()
	void AudioTargetStoppedMoving()
	{
		HazeAkComponent.HazePostEvent(StopMachineryAudioEvent);
		HazeAkComponent.HazePostEvent(StopTargetLoopAudioEvent);
	}
}