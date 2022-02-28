import Rice.Props.PropBaseActor;

struct FHazeBPPropMatch
{
	TArray<UStaticMesh> Meshes;
};

class UHazeBPPropActionUtility : UActorActionUtility
{
    UFUNCTION(BlueprintOverride)
    UClass GetSupportedClass() const
    {
        return APropBaseActor::StaticClass();
    }

    /* Select all Props in the editor world that have the same static mesh as one of the currently selected props. */
	// Get the meshes for current selection, if any actor in world has same meshes, add to selection
    UFUNCTION(CallInEditor, Category = "Prop Actions")
    void SelectPropsWithMatchingStaticMesh()
    {
		TArray<FHazeBPPropMatch> MeshArrays;
        TArray<AActor> SelectedActors = EditorUtility::GetSelectionSet();
        for (AActor Actor : SelectedActors)
        {
            APropBaseActor PropActor = Cast<APropBaseActor>(Actor);
            if (PropActor == nullptr)
                continue;

			// The meshes used by current selected actor
			TArray<UStaticMesh> Meshes = PropActor.GetUsedMeshes();

			// If list number of meshes for selected actor is not empty, add to container.
			if ( Meshes.Num() != 0 )
			{
				FHazeBPPropMatch Match;
				Match.Meshes = Meshes;
				MeshArrays.Add(Match);
			}
		}

		TArray<AActor> Actors;
		TArray<APropBaseActor> AllProps;
		GetAllActorsOfClass(AllProps);
		for (APropBaseActor Prop : AllProps)
		{
			TArray<UStaticMesh> Meshes = Prop.GetUsedMeshes();

			bool bFoundMatch = false;
			for (const FHazeBPPropMatch& Match : MeshArrays)
			{
				if (Match.Meshes == Meshes)
				{
					bFoundMatch = true;
					break;
				}
			}

			if (bFoundMatch)
				Actors.Add(Prop);
		}

		EditorLevel::SetSelectedLevelActors(Actors);
	}
};