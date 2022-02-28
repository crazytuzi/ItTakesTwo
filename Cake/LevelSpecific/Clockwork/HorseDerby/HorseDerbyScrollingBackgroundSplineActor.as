import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.Clockwork.HorseDerby.HorseDerbyScrollingBackgroundActor;

class AHorseDerbyScrollingBackgroundSplineActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSplineComponent HazeSplineComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.f;

	UPROPERTY(EditInstanceOnly)
	TArray<TSubclassOf<AHorseDerbyScrollingBackgroundActor>> BackgroundVariations;

	UPROPERTY(EditInstanceOnly)
	TArray<AHorseDerbyScrollingBackgroundActor> BackgroundInstances;

	UPROPERTY()
	TArray<AHorseDerbyScrollingBackgroundActor> ActiveInstances;

	TArray<AHorseDerbyScrollingBackgroundActor> InstancesToRemove;

	UPROPERTY(Category = "Settings")
	float DistancePerPiece = 600.f;

	UPROPERTY(Category = "Settings")
	float PieceLength = 800.f;

	UPROPERTY(Category = "Setup")
	int PoolSizePerInstance = 2;

	int PoolSize = 0;

	UPROPERTY(Category = "Debug")
	int NextPieceIndex = 0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		auto EditorBillboard = UBillboardComponent::Create(this);
		EditorBillboard.bIsEditorOnly = true;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(AHorseDerbyScrollingBackgroundActor Instance : BackgroundInstances)
			ActiveInstances.Add(Instance);

		PoolSize = BackgroundVariations.Num() * PoolSizePerInstance; 

		if(BackgroundInstances.Num() < PoolSize && BackgroundVariations.Num() != 0)
			SpawnBackgroundActors();

		for(AHorseDerbyScrollingBackgroundActor Instance : BackgroundInstances)
			Instance.SetupObject(HazeSplineComp);

		NextPieceIndex = ActiveInstances.Num();
	}

/* 	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MoveAndValidateBackground(DeltaSeconds, 250.f);
	} */

	//Populate Pool of Actors
	void SpawnBackgroundActors()
	{
		for(int i = BackgroundInstances.Num() != 0 ? BackgroundInstances.Num() : 0; i < PoolSize; i++)
		{
			int PieceIndex = i > BackgroundVariations.Num() - 1 ? i - (i / BackgroundVariations.Num() * BackgroundVariations.Num()) : i;
			AHorseDerbyScrollingBackgroundActor Actor = Cast<AHorseDerbyScrollingBackgroundActor>(SpawnActor(BackgroundVariations[PieceIndex], Level = GetLevel(), bDeferredSpawn = true));
			Actor.MakeNetworked(this, i);
			Actor.FinishSpawningActor();

			Actor.DisableActor(this);

			BackgroundInstances.Add(Actor);
		}
	}

	void MoveAndValidateBackground(float ManagerDeltaTime, float BackgroundSpeed)
	{
		if(ActiveInstances.Num() != 0)
			VerifyAndActivateBackgroundActor();

		MoveBackgroundActors(ManagerDeltaTime, BackgroundSpeed);
		RemoveDisabledInstancesFromActive();
	}

	//Iterate through Active Actors and move along spline, Verify Actors to deactivate.
	void MoveBackgroundActors(float DeltaSeconds, float BackgroundSpeed)
	{

		FHazeSplineSystemPosition SystemPosition;

		for (AHorseDerbyScrollingBackgroundActor Instance : ActiveInstances)
		{
			Instance.SplineStatus = Instance.SplineFollowComp.UpdateSplineMovement(-BackgroundSpeed * DeltaSeconds, SystemPosition);
			
			if(Instance.SplineStatus == EHazeUpdateSplineStatusType::AtEnd)
			{
				Instance.DisableActor(this);
				InstancesToRemove.AddUnique(Instance);
			}
			else
			{
				Instance.SetActorLocation(SystemPosition.WorldLocation);
			}
		}
	}

	//Remove Disabled Actors from Active array.
	void RemoveDisabledInstancesFromActive()
	{
		for(AHorseDerbyScrollingBackgroundActor InstanceToRemove : InstancesToRemove)
			ActiveInstances.Remove(InstanceToRemove);
		
		InstancesToRemove.Empty();
	}

	//Verify if / Activate new backgroundActor.
	void VerifyAndActivateBackgroundActor()
	{
		AHorseDerbyScrollingBackgroundActor Actor;
		
		if(ActiveInstances[ActiveInstances.Num() - 1] != nullptr)
			Actor = ActiveInstances[ActiveInstances.Num() - 1];

		float SplineDistance = HazeSplineComp.GetDistanceAlongSplineAtWorldLocation(Actor.ActorLocation);

		if((HazeSplineComp.GetSplineLength() - SplineDistance) > DistancePerPiece)
		{
			AHorseDerbyScrollingBackgroundActor NewActiveActor = BackgroundInstances[NextPieceIndex];

			FVector NewRelativePosition = FVector(Actor.MeshRoot.RelativeLocation.X + PieceLength, NewActiveActor.MeshRoot.RelativeLocation.Y, NewActiveActor.MeshRoot.RelativeLocation.Z);
			FVector NewWorldPosition = Actor.RootComp.WorldTransform.TransformPosition(NewRelativePosition);

			NewActiveActor.ActivateAtWorldLocation(NewWorldPosition);
			ActiveInstances.Add(NewActiveActor);
			NewActiveActor.EnableActor(this);

			NextPieceIndex++;
			if(NextPieceIndex == BackgroundInstances.Num())
				NextPieceIndex = 0;
		}
	}
}