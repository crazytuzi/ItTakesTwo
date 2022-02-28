import Cake.LevelSpecific.Shed.Vacuum.VacuumableWeight;
import Peanuts.Spline.SplineComponent;

event void FVacuumWeightSpawnerEvent();

class AVacuumWeightSpawner : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UBillboardComponent Billboard;

	UPROPERTY()
	TSubclassOf<AVacuumableWeight> WeightClass;

    UPROPERTY()
    TArray<AActor> LandingTargets;
    TArray<AActor> AvailableTargets;
	TArray<UHazeSplineComponent> AvailableSplines;

    AActor LastLandingTarget;

	UPROPERTY()
	AActor TutorialLandingTarget;
	bool bTutorialCompleted = false;
	UPROPERTY(NotEditable)
	UHazeSplineComponent TutorialSpline;
	AHazePlayerCharacter TutorialPlayer;

    UPROPERTY()
    int MaxAllowedWeights = 3;

	int NetworkIndex = 0;

	UPROPERTY(NotEditable)
	TArray<UHazeSplineComponent> Splines;

	TArray<AVacuumableWeight> AvailableWeights;
	TArray<AVacuumableWeight> ActiveWeights;

	AVacuumableWeight TutorialWeight;

	bool bSpawningAllowed = true;

	UPROPERTY()
	FOnWeightVacuumed OnWeightDestroyed;

	UPROPERTY()
	FVacuumWeightSpawnerEvent OnAllWeightsDestroyed;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Splines.Empty();

		for (AActor CurLandingTarget : LandingTargets)
		{
			UHazeSplineComponent CurSpline = UHazeSplineComponent::Create(this);
			FVector MidPoint = (ActorLocation/2) + (CurLandingTarget.ActorLocation/2);
			FVector DirToPoint = CurLandingTarget.ActorLocation - ActorLocation;
			DirToPoint = Math::ConstrainVectorToPlane(DirToPoint, FVector::UpVector);
			DirToPoint.Normalize();
			MidPoint += DirToPoint * 200.f;

			CurSpline.AddSplinePoint(MidPoint, ESplineCoordinateSpace::World);
			CurSpline.SetTangentAtSplinePoint(0, FVector(0.f, 0.f, 1200.f), ESplineCoordinateSpace::Local);
			CurSpline.SetLocationAtSplinePoint(1, MidPoint + FVector(0.f, 0.f, 700.f), ESplineCoordinateSpace::World);
			CurSpline.SetLocationAtSplinePoint(2, CurLandingTarget.ActorLocation + FVector(0.f, 0.f, 40.f), ESplineCoordinateSpace::World);
			CurSpline.SetTangentAtSplinePoint(2, FVector(0.f, 0.f, -1800.f), ESplineCoordinateSpace::Local);
			Splines.Add(CurSpline);
		}

		if (TutorialLandingTarget == nullptr)
			return;

		TutorialSpline = UHazeSplineComponent::Create(this);
		FVector MidPoint = (ActorLocation/2) + (TutorialLandingTarget.ActorLocation/2);
		FVector DirToPoint = TutorialLandingTarget.ActorLocation - ActorLocation;
		DirToPoint = Math::ConstrainVectorToPlane(DirToPoint, FVector::UpVector);
		DirToPoint.Normalize();
		MidPoint += DirToPoint * 200.f;
		TutorialSpline.AddSplinePoint(MidPoint, ESplineCoordinateSpace::World);
		TutorialSpline.SetTangentAtSplinePoint(0, FVector(0.f, 0.f, 1200.f), ESplineCoordinateSpace::Local);
		TutorialSpline.SetLocationAtSplinePoint(1, MidPoint + FVector(0.f, 0.f, 700.f), ESplineCoordinateSpace::World);
		TutorialSpline.SetLocationAtSplinePoint(2, TutorialLandingTarget.ActorLocation + FVector(0.f, 0.f, 40.f), ESplineCoordinateSpace::World);
		TutorialSpline.SetTangentAtSplinePoint(2, FVector(0.f, 0.f, -1800.f), ESplineCoordinateSpace::Local);
	}

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        AvailableTargets = LandingTargets;
		AvailableSplines = Splines;
    }

	UFUNCTION()
    void OccupyInitialTargets()
    {
        for (int Index = 0, Count = MaxAllowedWeights; Index < Count; ++ Index)
        {
			int TargetIndex = FMath::RandRange(0, AvailableTargets.Num() - 1);
        	AActor CurrentTarget = AvailableTargets[Index];
			UHazeSplineComponent CurSpline = AvailableSplines[Index];
            AVacuumableWeight Weight = Cast<AVacuumableWeight>(SpawnActor(WeightClass, CurrentTarget.ActorLocation, FRotator::ZeroRotator, NAME_None, false, GetLevel()));
			Weight.SplineToFollow = CurSpline;
			Weight.MakeNetworked(this, NetworkIndex);
			NetworkIndex++;
            Weight.LandingTarget = CurrentTarget;
            Weight.OnWeightVacuumed.AddUFunction(this, n"WeightVacuumed");
            AvailableTargets.Remove(CurrentTarget);
			AvailableSplines.Remove(CurSpline);
			Weight.OnWeightDestroyed.AddUFunction(this, n"WeightDestroyed");
			ActiveWeights.Add(Weight);
        }
    }

    UFUNCTION()
    void WeightVacuumed(AVacuumableWeight Weight)
    {
        LaunchWeight();

		if (bTutorialCompleted)
		{
        	AvailableTargets.Add(Weight.LandingTarget);
			AvailableSplines.Add(Weight.SplineToFollow);
		}
    }

	UFUNCTION()
    void LaunchWeight()
    {
		if (!HasControl())
			return;

		if (!bSpawningAllowed)
			return;

		AVacuumableWeight Weight;
		if (AvailableWeights.Num() != 0)
			Weight = AvailableWeights[0];

		int Index = FMath::RandRange(0, AvailableTargets.Num() - 1);
        AActor CurrentTarget = AvailableTargets[Index];
		UHazeSplineComponent CurSpline = AvailableSplines[Index];

		NetLaunchWeight(Weight, CurrentTarget, CurSpline);
    }

	UFUNCTION(NetFunction)
	void NetLaunchWeight(AVacuumableWeight CurWeight, AActor Target, UHazeSplineComponent Spline)
	{
		AVacuumableWeight Weight;
		if (CurWeight == nullptr)
		{
			Weight = Cast<AVacuumableWeight>(SpawnActor(WeightClass, ActorLocation, FRotator::ZeroRotator, NAME_None, true));
			Weight.MakeNetworked(this, NetworkIndex);
			FinishSpawningActor(Weight);
			NetworkIndex++;
		}
		else
			Weight = CurWeight;

		ActiveWeights.Add(Weight);
		Weight.VisibleMesh.SetHiddenInGame(false);
		Weight.TeleportActor(ActorLocation, FRotator::ZeroRotator);
		Weight.VacuumableComponent.bCanEnterVacuum = true;
		Weight.VacuumableComponent.bAffectedByVacuum = true;
        Weight.LandingTarget = Target;
        Weight.OnWeightVacuumed.AddUFunction(this, n"WeightVacuumed");
        Weight.LaunchFromSpawner(Spline);
        AvailableTargets.Remove(Target);
		AvailableSplines.Remove(Spline);
		Weight.OnWeightDestroyed.AddUFunction(this, n"WeightDestroyed");
		if (AvailableWeights.Contains(Weight))
			AvailableWeights.Remove(Weight);
	}

	UFUNCTION(NotBlueprintCallable)
	void WeightDestroyed(AVacuumableWeight Weight)
	{
		AvailableWeights.Add(Weight);
		ActiveWeights.Remove(Weight);
		OnWeightDestroyed.Broadcast(Weight);

		if (!bSpawningAllowed && ActiveWeights.Num() == 0)
		{
			OnAllWeightsDestroyed.Broadcast();
		}
	}

	UFUNCTION()
	void StopSpawning()
	{
		bSpawningAllowed = false;
	}

	UFUNCTION()
	AVacuumableWeight SpawnTutorialWeight()
	{
		System::SetTimer(this, n"LaunchTutorialWeight", 1.2f, false);
        AVacuumableWeight Weight = Cast<AVacuumableWeight>(SpawnActor(WeightClass, ActorLocation, FRotator::ZeroRotator, NAME_None));
		Weight.MakeNetworked(this, NetworkIndex);
		NetworkIndex++;
		Weight.SetActorHiddenInGame(true);
        Weight.LandingTarget = TutorialLandingTarget;
		Weight.OnWeightVacuumed.AddUFunction(this, n"WeightVacuumed");
        TutorialWeight = Weight;

		return Weight;
	}

	UFUNCTION(NotBlueprintCallable)
	void LaunchTutorialWeight()
	{
		TutorialWeight.LaunchFromSpawner(TutorialSpline);
		TutorialWeight.SetActorHiddenInGame(false);
	}

	UFUNCTION(NotBlueprintCallable)
	void ClearFoV()
	{
		TutorialPlayer.ClearFieldOfViewByInstigator(this, 1.5f);
	}

	UFUNCTION()
	void SetTutorialCompleted()
	{
		bTutorialCompleted = true;
	}
}