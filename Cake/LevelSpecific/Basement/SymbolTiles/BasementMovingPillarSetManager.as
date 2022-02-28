import Cake.LevelSpecific.Basement.SymbolTiles.BasementMovingPillar;
import Rice.Positions.SortListByDistance;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;

class ABasementMovingPillarSetManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;

	UPROPERTY()
	TArray<FBasementMovingPillarSet> PillarSets;

	UFUNCTION()
	void ActivatePillarSet(int Index, bool bReverse = false)
	{
		TArray<AHazeActor> InActors;
		for (ABasementMovingPillar CurPillar : PillarSets[Index].Pillars)
		{
			AHazeActor HazeActor = Cast<AHazeActor>(CurPillar);
			InActors.Add(HazeActor);
		}
		TArray<AHazeActor> OutActors = SortActorArrayByDistance(InActors, GetActiveParentBlobActor().ActorLocation, false);

		int CurIndex = 0;
		for (AHazeActor CurActor : OutActors)
		{
			ABasementMovingPillar CurPillar = Cast<ABasementMovingPillar>(CurActor);
			if (CurPillar != nullptr)
			{
				float Delay = CurIndex == 0 ? 0.1f : CurIndex * 0.1f;
				CurPillar.StartMovingPillar(Delay, bReverse);
			}
			CurIndex++;
		}
	}

	UFUNCTION()
	void UpdatePillarEndLocation(int Index, float NewEndLocation)
	{
		for (ABasementMovingPillar CurPillar : PillarSets[Index].Pillars)
		{
			CurPillar.SetNewEndLocation(NewEndLocation);
		}
	}
}

struct FBasementMovingPillarSet
{
	UPROPERTY()
	TArray<ABasementMovingPillar> Pillars;
}