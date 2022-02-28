import Cake.LevelSpecific.Music.LevelMechanics.RailSpeaker.RailSpeaker;

UCLASS(Abstract)
class ARailSpeakerTurntable : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TurntableRoot;

	UPROPERTY(DefaultComponent, Attach = TurntableRoot)
	UStaticMeshComponent TurntableMesh;

	UPROPERTY(DefaultComponent, Attach = TurntableRoot)
	UStaticMeshComponent Rail1;
	
	UPROPERTY(DefaultComponent, Attach = TurntableRoot)
	UStaticMeshComponent Rail2;

	UPROPERTY(DefaultComponent, Attach = TurntableRoot)
	USphereComponent Trigger;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RotateTurntableTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike AddSpeakerTimeLike;

	float StartRot;
	float EndRot;

	FVector SpeakerStartLocation;
	FVector SpeakerEndLocation;

	ARailSpeaker CurrentSpeaker;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RotateTurntableTimeLike.BindUpdate(this, n"UpdateRotateTurntable");
		RotateTurntableTimeLike.BindFinished(this, n"FinishRotateTurntable");

		AddSpeakerTimeLike.BindUpdate(this, n"UpdateAddSpeaker");
		AddSpeakerTimeLike.BindFinished(this, n"FinishAddSpeaker");

		Trigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
		Trigger.OnComponentEndOverlap.AddUFunction(this, n"ExitTrigger");
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		ARailSpeaker RailSpeaker = Cast<ARailSpeaker>(OtherActor);
		if (RailSpeaker != nullptr)
		{
			RailSpeaker.StartAligningToTurntable(TurntableMesh.WorldLocation);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void ExitTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		ARailSpeaker RailSpeaker = Cast<ARailSpeaker>(OtherActor);
		if (RailSpeaker != nullptr)
		{
			RailSpeaker.StartAligningToTurntable(TurntableMesh.WorldLocation);
		}
	}

	UFUNCTION()
	void RotateTurntable()
	{
		StartRot = ActorRotation.Yaw;
		EndRot = StartRot + 90.f;

		RotateTurntableTimeLike.PlayFromStart();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateRotateTurntable(float CurValue)
	{
		float CurRot = FMath::Lerp(StartRot, EndRot, CurValue);
		SetActorRotation(FRotator(0.f, CurRot, 0.f));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishRotateTurntable()
	{

	}

	UFUNCTION()
	void AddSpeaker()
	{
		SpeakerStartLocation = CurrentSpeaker.ActorLocation;
		SpeakerEndLocation = TurntableRoot.WorldLocation;

		AddSpeakerTimeLike.PlayFromStart();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateAddSpeaker(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(SpeakerStartLocation, SpeakerEndLocation, CurValue);
		CurrentSpeaker.SetActorLocation(CurLoc);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishAddSpeaker()
	{

	}
}