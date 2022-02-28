import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.Shed.Vacuum.VacuumGeneratorFrayedCables;

event void FVacuumGeneratorFrayedCableEvent();
event void FVacuumGeneratorFrayedCableChargeDisruptedEvent(int Index);

class AVacuumGeneratorFrayedCableCharge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent ChargeComp;
	default ChargeComp.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = ChargeComp)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartChargeAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopChargeAudioEvent;
	
	UPROPERTY()
	FVacuumGeneratorFrayedCableEvent OnChargeReachedEnd;

	UPROPERTY()
	FVacuumGeneratorFrayedCableChargeDisruptedEvent OnChargeDisrupted;

	UPROPERTY()
	TArray<AHazeActor> Cables;

	UPROPERTY()
	TArray<AVacuumGeneratorFrayedCables> FrayedCables;

	UHazeSplineComponent CurrentSplineComp;
	AHazeActor CurrentSplineActor;
	AVacuumGeneratorFrayedCables TargetFrayedCables;
	AVacuumGeneratorFrayedCables PreviousFrayedCables;

	UPROPERTY(NotEditable)
	bool bMovingAlongSpline = false;
	float CurrentDistanceAlongSpline;

	int CurrentIndex = 0;

	bool bReachedEnd = false;

	float SpeedAlongSpline = 550.f;

	AHazePlayerCharacter CurrentControlPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetTargetCables();
	}

	void SetNewSpline(AHazeActor Actor)
	{
		if (Actor == nullptr)
			return;

		UHazeSplineComponent SplineComp = UHazeSplineComponent::Get(Actor);
		if (SplineComp == nullptr)
			return;

		CurrentSplineComp = SplineComp;
	}

	UFUNCTION()
	void ActivateCharge(AHazePlayerCharacter Player)
	{
		CurrentControlPlayer = Player.OtherPlayer;
		CurrentIndex = 0;
		SetTargetCables();
		TeleportActor(Cables[0].ActorLocation, FRotator::ZeroRotator);
		ChargeComp.Activate(true);
		StartMovingAlongSpline();
		ChargeComp.Activate(true);
		SetActorTickEnabled(true);
		HazeAkComp.HazePostEvent(StartChargeAudioEvent);
	}

	UFUNCTION(NetFunction)
	void NetStartMovingAlongNextSpline()
	{
		if (bReachedEnd)
			return;

		bMovingAlongSpline = false;

		if (PreviousFrayedCables != nullptr)
			PreviousFrayedCables.ReleaseElectrifiedPlayer();

		PreviousFrayedCables = TargetFrayedCables;
		TargetFrayedCables.ElectricChargePassedThrough();

		CurrentControlPlayer = CurrentControlPlayer.OtherPlayer;
		CurrentIndex++;
		SetTargetCables();
		StartMovingAlongSpline();
	}

	void SetTargetCables()
	{
		CurrentSplineActor = Cables[CurrentIndex];
		CurrentSplineComp = UHazeSplineComponent::Get(CurrentSplineActor);
		if (CurrentIndex <= FrayedCables.Num() - 1)
			TargetFrayedCables = FrayedCables[CurrentIndex];
	}

	UFUNCTION()
	void StartMovingAlongSpline()
	{
		CurrentDistanceAlongSpline = 0.f;
		bMovingAlongSpline = true;
	}

	UFUNCTION(NetFunction)
	void NetChainDisrupted()
	{
		OnChargeDisrupted.Broadcast(CurrentIndex);
		bMovingAlongSpline = false;
		CurrentDistanceAlongSpline = 0.f;
		CurrentIndex = 0;
		ChargeComp.Deactivate();
		SetActorTickEnabled(false);
		HazeAkComp.HazePostEvent(StopChargeAudioEvent);
		BP_DisableBulge();

		if (PreviousFrayedCables != nullptr)
		{
			PreviousFrayedCables.ReleaseElectrifiedPlayer();
			PreviousFrayedCables = nullptr;
		}
	}

	UFUNCTION(NetFunction)
	void NetReachedEnd()
	{
		if (bReachedEnd)
			return;

		bMovingAlongSpline = false;

		bReachedEnd = true;
		OnChargeReachedEnd.Broadcast();
		HazeAkComp.HazePostEvent(StopChargeAudioEvent);
		ChargeComp.Deactivate();
		SetActorTickEnabled(false);
		BP_DisableBulge();

		if (PreviousFrayedCables != nullptr)
		{
			PreviousFrayedCables.ReleaseElectrifiedPlayer();
			PreviousFrayedCables = nullptr;
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_DisableBulge() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bReachedEnd)
			return;

		if (!bMovingAlongSpline)
			return;

		if (CurrentSplineComp == nullptr)
			return;

		CurrentDistanceAlongSpline += SpeedAlongSpline * DeltaTime;
		FVector CurLoc = CurrentSplineComp.GetLocationAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
		SetActorLocation(CurLoc);

		if (CurrentDistanceAlongSpline >= CurrentSplineComp.SplineLength && CurrentControlPlayer.HasControl())
		{
			if (CurrentIndex >= Cables.Num() - 1)
			{
				NetReachedEnd();
			}
			else if (TargetFrayedCables.bCablesHeld)
			{
				NetStartMovingAlongNextSpline();
			}
			else
			{
				NetChainDisrupted();
			}
		}
	}
}