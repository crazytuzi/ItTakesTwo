import Cake.LevelSpecific.Clockwork.Actors.PortalRoom.TimeDimensionRune;

event void FTimeDimensionRuneDoorSignature();

class ATimeDimensionRuneDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent DoorMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Lamp01;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Lamp02;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Lamp03;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent RuneBoxCollision;

	UPROPERTY()
	FTimeDimensionRuneDoorSignature DoorOpenedEvent;

	UPROPERTY()
	FHazeTimeLike OpenDoorTimeline;
	default OpenDoorTimeline.Duration = 3.f;

	TArray<ATimeDimensionRune> Runes;
	TArray<UStaticMeshComponent> LampArray;
	default LampArray.Add(Lamp01);
	default LampArray.Add(Lamp02);
	default LampArray.Add(Lamp03);

	int CurrentRuneNumber = 0;
	int CurrentRunePressIndex = 0;

	bool bWrongCombination = false;

	FVector Red = FVector(10.f, 0.f, 0.f);
	FVector Green = FVector(0.f, 10.f, 0.f);
	FVector White = FVector(1.f, 1.f, 1.f);

	FVector DoorStartingLocation;
	FVector DoorTargetLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> ActorArray;	
		RuneBoxCollision.GetOverlappingActors(ActorArray);

		for (AActor Actor : ActorArray)
		{
			ATimeDimensionRune TempRune = Cast<ATimeDimensionRune>(Actor);

			if (TempRune != nullptr)
			{
				Runes.Add(TempRune);
			}
		}

		for(ATimeDimensionRune Rune : Runes)
		{
			Rune.RunePressedEvent.AddUFunction(this, n"RunePressed");
		}

		OpenDoorTimeline.BindUpdate(this, n"OpenDoorTimelineUpdate");

		DoorStartingLocation = DoorMesh.RelativeLocation;
		DoorTargetLocation = DoorStartingLocation + FVector(0.f, 0.f, 700.f);

		SetAllLampsToColor(White);		
	}

	void SetOneLampColor(int Index, FVector Color)
	{
		LampArray[Index].SetVectorParameterValueOnMaterialIndex(0, n"EmissiveColor", Color);
	}
	
	void SetAllLampsToColor(FVector Color)
	{
		for (UStaticMeshComponent Lamp : LampArray)
		{
			Lamp.SetVectorParameterValueOnMaterialIndex(0, n"EmissiveColor", Color);
		}
	}

	void SetAllRunesEnabled(bool bEnabled)
	{
		for (ATimeDimensionRune Rune : Runes)
		{
			Rune.SetRuneEnabled(bEnabled);
		}

		if (bEnabled)
			SetAllLampsToColor(White);
	}

	UFUNCTION()
	void ResetRunes()
	{
		SetAllRunesEnabled(true);
	}

	UFUNCTION()
	void RunePressed(int RuneNumber)
	{
		SetOneLampColor(CurrentRunePressIndex, Green);
		CurrentRunePressIndex++;

		if (RuneNumber == -1)
			bWrongCombination = true;

		int NextRuneNumber = CurrentRuneNumber + 1;
		if (RuneNumber == NextRuneNumber)
		{
			CurrentRuneNumber++;
		} else 
		{
			bWrongCombination = true;
		}

		if (CurrentRunePressIndex == 3)
		{
			SetAllRunesEnabled(false);
			
			if (bWrongCombination)
				System::SetTimer(this, n"WrongRuneWasPressed", 1.f, false);
			else
				System::SetTimer(this, n"OpenDoor", 1.f, false);
		}
	}

	UFUNCTION()
	void OpenDoor()
	{
		OpenDoorTimeline.PlayFromStart();
		DoorOpenedEvent.Broadcast();
	}

	UFUNCTION()
	void OpenDoorTimelineUpdate(float CurrentValue)
	{
		DoorMesh.SetRelativeLocation(FMath::Lerp(DoorStartingLocation, DoorTargetLocation, CurrentValue));
	}

	UFUNCTION()
	void WrongRuneWasPressed()
	{
		CurrentRuneNumber = 0;
		CurrentRunePressIndex = 0;
		bWrongCombination = false;
		SetAllLampsToColor(Red);
		SetAllRunesEnabled(false);
		System::SetTimer(this, n"ResetRunes", 2.f, false);
	}
}