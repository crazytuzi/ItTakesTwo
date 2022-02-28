import Cake.LevelSpecific.Music.NightClub.RhythmTempoActor;


class URhythmData : UDataAsset
{
	UPROPERTY(Category = Setup)
	int TempoCount = 0;

	UPROPERTY(Category = Setup)
	TArray<TSubclassOf<ARhythmTempoActor>> Tempos;

	TSubclassOf<ARhythmTempoActor> GetRhythmTempoActor(int Index) const
	{
		return Tempos[Index];
	}

	int GetNumTempos() const property { return Tempos.Num(); }

	UFUNCTION(CallInEditor, Category = Randomize)
	void RandomizeTempo()
	{
		for(int Index = AvailableTempoActors.Num() - 1; Index >= 0; --Index)
		{
			if(!AvailableTempoActors[Index].IsValid())
			{
				AvailableTempoActors.RemoveAt(Index);
			}
		}

		if(AvailableTempoActors.Num() == 0)
		{
			return;
		}

		const int Max = AvailableTempoActors.Num() - 1;

		Tempos.SetNum(TempoCount);
		for(int Index = 0; Index < TempoCount; ++Index)
		{
			int RandomNumber = FMath::RandRange(0, Max);
			Tempos[Index] = AvailableTempoActors[RandomNumber];
		}
	}

	UPROPERTY(Category = Setup)
	TArray<TSubclassOf<ARhythmTempoActor> > AvailableTempoActors;
}
