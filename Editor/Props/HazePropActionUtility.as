
class UHazePropActionUtility : UActorActionUtility
{
    UFUNCTION(BlueprintOverride)
    UClass GetSupportedClass() const
    {
        return AHazeProp::StaticClass();
    }

    /* Select all Props in the editor world that have the same static mesh as one of the currently selected props. */
    UFUNCTION(CallInEditor, Category = "Prop Actions")
    void SelectPropsWithMatchingStaticMesh()
    {
        TSet<UStaticMesh> PropMeshesToSelect;

        // Determine which meshes to select props for
        TArray<AActor> SelectedActors = EditorUtility::GetSelectionSet();
        for (AActor Actor : SelectedActors)
        {
            AHazeProp PropActor = Cast<AHazeProp>(Actor);
            if (PropActor == nullptr)
                continue;

            PropMeshesToSelect.Add(PropActor.PropSettings.StaticMesh);
        }

        EditorLevel::SelectNothing();

        // Go over all actors in the level and select the ones that have one of those meshes
        TArray<AHazeProp> AllProps;
		GetAllActorsOfClass(AllProps);

        for (AHazeProp PropActor : AllProps)
        {
            if (!PropMeshesToSelect.Contains(PropActor.PropSettings.StaticMesh))
                continue;
            if (PropActor.PropSettings.StaticMesh == nullptr)
                continue;
            
            EditorLevel::SetActorSelectionState(PropActor, true);
        }
    }

    /* Prints out all props in the map and how many times they were used. */
    UFUNCTION(CallInEditor, Category = "Prop Actions")
    void ListMostUsedProps()
    {
        TSet<UStaticMesh> PropMeshesToSelect;

        TArray<AHazeProp> AllProps;
		GetAllActorsOfClass(AllProps);

		TArray<UStaticMesh> Meshes = TArray<UStaticMesh>();
		TArray<int> Counts = TArray<int>();

        for (AHazeProp PropActor : AllProps)
        {
			auto Mesh = PropActor.PropSettings.StaticMesh;

            if (Mesh == nullptr)
                continue;
			bool found = false;
			for (int i = 0; i < Meshes.Num(); i++)
			{
				if(Meshes[i] == Mesh)
				{
					found = true;
					Counts[i] += 1;
				}
			}
			
			if(!found)
			{
				Meshes.Add(Mesh);
				Counts.Add(1);
			}
        }
		int current = 0;
		
		// "??? sort" (somebody stop me)
		// no for real someone make me not write code like this.
		TArray<UStaticMesh> SortedMeshes = TArray<UStaticMesh>();
		TArray<int> SortedCounts = TArray<int>();
		for (int i = 0; i < 10000; i++)
		{
			for (int j = 0; j < Meshes.Num(); j++)
			{
				if(Counts[j] == i)
				{
					SortedMeshes.Add(Meshes[j]);
					SortedCounts.Add(Counts[j]);
				}
			}
		}
		
		for (int i = 0; i < SortedMeshes.Num(); i++)
		{
			Print("" + SortedCounts[i] + " " + SortedMeshes[i].Name + "");
		}
    }
};