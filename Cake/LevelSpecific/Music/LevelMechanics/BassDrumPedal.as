import Cake.LevelSpecific.Music.LevelMechanics.BassDrum;
import Cake.LevelSpecific.Music.Singing.InstrumentActivation.InstrumentActivationComponent;
import Cake.LevelSpecific.Music.Singing.SongOfLife.SongOfLifeComponent;

UCLASS(Abstract)
class ABassDrumPedal : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PedalFrame;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PedalMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PedalBeater;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USongOfLifeComponent SongOfLifeComp;

	UPROPERTY(DefaultComponent)
	UInstrumentActivationComponent ActivationComp;

	UPROPERTY()
	ABassDrum TargetBassDrum;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike PedalTimeLike;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> PlayerCapability;

	bool bActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PedalTimeLike.BindUpdate(this, n"UpdatePedal");
		PedalTimeLike.BindFinished(this, n"FinishPedal");

		SongOfLifeComp.OnStartAffectedBySongOfLife.AddUFunction(this, n"StartMoving");
		SongOfLifeComp.OnStopAffectedBySongOfLife.AddUFunction(this, n"StopMoving");
	}

	UFUNCTION()
	void StartMoving(FSongOfLifeInfo Info)
	{
		bActive = true;
		if (!PedalTimeLike.IsPlaying())
		{
			PedalTimeLike.PlayFromStart();
			TargetBassDrum.HitByPedal();
		}
	}

	UFUNCTION()
	void StopMoving(FSongOfLifeInfo Info)
	{
		bActive = false;
	}

	UFUNCTION()
	void UpdatePedal(float CurValue)
	{
		float PedalRot = FMath::Lerp(20.f, 5.f, CurValue);
		PedalMesh.SetRelativeRotation(FRotator(PedalRot, 0.f, 0.f));

		float BeaterRot = FMath::Lerp(0.f, -52.f, CurValue);
		PedalBeater.SetRelativeRotation(FRotator(BeaterRot, 0.f, 0.f));
	}

	UFUNCTION()
	void FinishPedal()
	{
		if (bActive)
		{
			PedalTimeLike.PlayFromStart();
			TargetBassDrum.HitByPedal();
		}
	}
}