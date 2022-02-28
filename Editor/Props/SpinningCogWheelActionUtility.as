import Cake.Environment.SpinningCogWheel;

// Utility struct to help in comparing similar Blueprints
struct FMatchObject
{
	UStaticMesh Mesh = nullptr;
	float TimeForFullCircle = 0.0;
	int Steps = 0;
	bool Reverse = false;
	TArray<UMaterialInterface> Materials;
	// @todo: Add MaterialInterfaces for each slot
}

class USpinningCogWheelActionUtility : UActorActionUtility
{
	UFUNCTION(BlueprintOverride)
	UClass GetSupportedClass() const
	{
		return ASpinningCogWheel::StaticClass();
	}

	// Given a BP Spinning Cog Wheel, return struct with values we want to filter on.
	FMatchObject GetMatchObject(ASpinningCogWheel CogWheel)
	{
		FMatchObject Result;

		UStaticMeshComponent StaticMeshComponent = Cast<UStaticMeshComponent>(
			CogWheel.GetComponentByClass(UStaticMeshComponent::StaticClass())
		);

		Result.Mesh = StaticMeshComponent.StaticMesh;
		Result.TimeForFullCircle = CogWheel.TimeForFullCircle;
		Result.Steps = CogWheel.Steps;
		Result.Reverse = CogWheel.Reverse;
		Result.Materials = StaticMeshComponent.GetMaterials();

		return Result;
	}

	UFUNCTION(CallInEditor, Category = "Select")
	void SelectMatching()
	{
		TArray<FMatchObject> MatchObjects;
		TArray<AActor> ActorsToSelect;

		// Iterate over selection and 
		for (AActor Actor : EditorUtility::GetSelectionSet())
		{
			ASpinningCogWheel CogWheel = Cast<ASpinningCogWheel>(Actor);
			if(CogWheel == nullptr)
				continue;

			FMatchObject MatchObject = GetMatchObject(CogWheel);

			if (!MatchObjects.Contains(MatchObject))
				MatchObjects.Add(MatchObject);
		}

		for (AActor Actor : EditorLevel::GetAllLevelActors())
		{
			ASpinningCogWheel CogWheel = Cast<ASpinningCogWheel>(Actor);
			if(CogWheel == nullptr)
				continue;

			FMatchObject MatchObject = GetMatchObject(CogWheel);

			if (MatchObjects.Contains(MatchObject))
				ActorsToSelect.Add(Actor);
		}

		EditorLevel::SetSelectedLevelActors(ActorsToSelect);

		// Output some result to the log also
		Print("Selected " + ActorsToSelect.Num() + " Actors.");
	}

	/* A BP_SpinningCogWheel costs about ~0.3 ms, so let's allow for a quick conversion to using our shader solution */
	UFUNCTION(CallInEditor, Category = "Performance")
	void ConvertToHazeProp()
	{
		// Get an iterate over selection
		TArray<AActor> SelectedActors = EditorUtility::GetSelectionSet();
		for (AActor Actor : SelectedActors)
		{
			// Cast to ASpinningCogWheel to filter out any actors that aren't of the supported class
			ASpinningCogWheel CogWheel = Cast<ASpinningCogWheel>(Actor);

			// Pass on all actors not of class ASpinningCogWheel
			if(CogWheel == nullptr)
				continue;
		
			UActorComponent ActorComponents = CogWheel.GetComponentByClass(UStaticMeshComponent::StaticClass());
			UStaticMeshComponent StaticMeshComponent = Cast<UStaticMeshComponent>(ActorComponents);

			if(StaticMeshComponent == nullptr)
				continue;

			FVector Location = CogWheel.GetActorLocation();

			AActor CopiedActor = EditorLevel::SpawnActorFromClass(AHazeProp::StaticClass(), Location);
			AHazeProp HazeProp = Cast<AHazeProp>(CopiedActor);

			// Assign the static mesh to be used for the haze prop
			FHazePropSettings NewSettings;
			NewSettings.StaticMesh = StaticMeshComponent.StaticMesh;
			HazeProp.OverrideSettings(NewSettings);

			// @todo: Set material overrides, get materials from StaticMeshComponent

			// Rerun the construction script so the prop is initiated.
			HazeProp.RerunConstructionScripts();			
		}
	}
}