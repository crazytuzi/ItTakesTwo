import Cake.LevelSpecific.Hopscotch.CardboardNumberCube;
import Cake.LevelSpecific.Hopscotch.NumberCube;

class AMovingCardboardCubesManager : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	UBillboardComponent Root;

    UPROPERTY(DefaultComponent)
    UBoxComponent BoxCollision;

    UPROPERTY()
    EHopScotchNumber HopscotchNumber;

    UPROPERTY()
    float MoveInterval;
    default MoveInterval = 1.0f;

    TArray<ACardboardNumberCube> CardboardCubeArray;
    TArray<AActor> ActorArray;

    bool bReverse;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        BoxCollision.GetOverlappingActors(ActorArray);
        for (AActor Actor : ActorArray)
        {
            ACardboardNumberCube Cube = Cast<ACardboardNumberCube>(Actor);

            if (Cube != nullptr)
                CardboardCubeArray.Add(Cube);
        }
        HopscotchNumber = EHopScotchNumber::Hopscotch01;
        StartMoveCubesTimer();
    }

    UFUNCTION()
    void StartMoveCubesTimer()
    {
        if (CardboardCubeArray.Num() != 0)
        {
            System::SetTimer(this, n"MoveCubes", MoveInterval, true);
        }
    }

    UFUNCTION()
    void MoveCubes()
    {
        if (!bReverse)
        {
            for (ACardboardNumberCube Cube : CardboardCubeArray)
			{
				if (Cube.HopscotchNumber == HopscotchNumber)
				{
					Cube.ActivateCube();
				}
			}
		}
		else 
		{
			for (ACardboardNumberCube Cube : CardboardCubeArray)
			{
				if (Cube.HopscotchNumber == HopscotchNumber)
				{
					Cube.DeactivateCube();
				}
			}
		}
		ChangeHopscotchNumber();
    }

    void ChangeHopscotchNumber()
    {
        switch (HopscotchNumber)
        {
        case EHopScotchNumber::Hopscotch01:
            HopscotchNumber = EHopScotchNumber::Hopscotch02;
        break;
        case EHopScotchNumber::Hopscotch02:
            HopscotchNumber = EHopScotchNumber::Hopscotch03;
        break;
        case EHopScotchNumber::Hopscotch03:
            HopscotchNumber = EHopScotchNumber::Hopscotch01;
            bReverse = !bReverse;
        }
    }
}