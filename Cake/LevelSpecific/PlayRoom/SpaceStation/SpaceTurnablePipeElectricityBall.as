import Peanuts.Spline.SplineComponent;
import Rice.Positions.GetClosestActorOfClassToLocation;

event void FSpaceElectricityBallReachedEndEvent();

UCLASS(Abstract)
class ASpaceTurnablePipeElectricityBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent EffectComp;

	UHazeSplineComponent CurrentSplineComp;

	UPROPERTY(DefaultComponent, Attach = EffectComp)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ElectricityBallStartAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ElectricityBallStopAudioEvent;

	UPROPERTY()
	FSpaceElectricityBallReachedEndEvent OnReachedEnd;

	float CurrentDistanceAlongSpline = 0.f;
	float SpeedAlongSpline = 5000.f;
	bool bActive = false;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION()
	void ActivateElectricityBall(UHazeSplineComponent TargetSpline)
	{
		if (TargetSpline == nullptr)
			return;

		HazeAkComp.HazePostEvent(ElectricityBallStartAudioEvent);
		CurrentDistanceAlongSpline = 0.f;
		CurrentSplineComp = TargetSpline;
		TeleportActor(CurrentSplineComp.GetLocationAtDistanceAlongSpline(0.f, ESplineCoordinateSpace::World), FRotator::ZeroRotator);
		EffectComp.Activate(true);
		SetActorHiddenInGame(false);
		bActive = true;
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (CurrentSplineComp == nullptr)
		{
			SetActorTickEnabled(false);
			return;
		}

		if (!bActive)
		{
			SetActorTickEnabled(false);
			return;
		}

		CurrentDistanceAlongSpline += SpeedAlongSpline * DeltaTime;
		SetActorLocation(CurrentSplineComp.GetLocationAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World));
		float DistanceAlongSplineNormalized = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 7500.f), FVector2D(0.f, 1.f), CurrentDistanceAlongSpline);
		HazeAkComp.SetRTPCValue("Rtpc_World_Shared_Interactables_ElectricBall_Progress", DistanceAlongSplineNormalized);

		if (CurrentDistanceAlongSpline >= CurrentSplineComp.SplineLength)
		{
			bActive = false;
			SetActorTickEnabled(false);
			OnReachedEnd.Broadcast();
			HazeAkComp.HazePostEvent(ElectricityBallStopAudioEvent);
			EffectComp.Deactivate();
		}
	}
}