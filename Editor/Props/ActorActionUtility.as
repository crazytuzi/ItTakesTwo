import Vino.Movement.Grinding.GrindSpline;

class UHazeActorActionUtility : UActorActionUtility
{
	UFUNCTION(BlueprintOverride)
	UClass GetSupportedClass() const
	{
		return AActor::StaticClass();
	}

	UFUNCTION(BlueprintPure)
	UClass GetClassFromSubclass(TSubclassOf<AActor> SubClass) const
	{
		return SubClass.Get();
	}


	UFUNCTION(CallInEditor, Category = "Select", ToolTip = "Select all actors which can be assumed to be duplicates.")
	void SelectDuplicates()
	{
		TArray<AActor> AllActors;
		GetAllActorsOfClass(AllActors);

		TArray<AActor> Duplicates;

		for (AActor Actor : AllActors)
		{
			for (AActor Other : AllActors)
			{
				if (Actor == Other)
					continue;

				// Check they are of same class,
				if (Actor.Class != Other.Class)
					continue;

				// Check that they are right on top of each other,
				if (!FMath::IsNearlyZero(Actor.GetDistanceTo(Other)))
					continue;

				// Get their first primitive component and check it matches, 
				UStaticMeshComponent ActorComponent = Cast<UStaticMeshComponent>(Actor.GetComponentByClass(UStaticMeshComponent::StaticClass()));
				UStaticMeshComponent OtherComponent = Cast<UStaticMeshComponent>(Other.GetComponentByClass(UStaticMeshComponent::StaticClass()));

				// Never not nullcheck
				if (ActorComponent == nullptr || OtherComponent == nullptr)
					continue;

				if (ActorComponent.StaticMesh == OtherComponent.StaticMesh)
					Duplicates.AddUnique(Other); // It's this or solve TSet => TArray
			}
		}
		
		EditorLevel::SetSelectedLevelActors(Duplicates);
	}

	// Some landscapes found a way to become movable, which caused issues with lightmaps, so here is a quick bandaid for this potential issue.
	UFUNCTION(CallInEditor, Category = "Tech Art", ToolTip = "Log all components for selected actors")
	void SetAllComponentsMobilityStatic()
	{
		for (AActor Actor: EditorUtility::GetSelectionSet())
		{
			TArray<USceneComponent> Components;
			Actor.GetRootComponent().GetChildrenComponents(true, Components);

			Print("Setting "+Actor.GetName()+" components to all become EComponentMobility::Static");
			for (USceneComponent Component: Components)
			{
				Component.SetMobility(EComponentMobility::Static);
			}
		}
	}

	UFUNCTION(CallInEditor, Category = "Tech Art")
	void LandscapeDebug()
	{
		for (AActor Actor: EditorUtility::GetSelectionSet())
		{
			ALandscape Landscape = Cast<ALandscape>(Actor);
			if (Landscape==nullptr)
				continue;
			Editor::CleanupLandscape(Landscape);
		}
	}
	UFUNCTION(CallInEditor, Category = "Performance", ToolTip = "Select all currently rendered actors.")
	void SelectRenderedActors()
	{
		// Get all actors in the active Level
		TArray<AActor> Actors;
		GetAllActorsOfClass(Actors);

		TArray<AActor> RenderedActors;
		
		// For each actor, check if any of their primitive components have been
		// rendred recently, if so, add actor to the array for selecting.
		for (AActor Actor : Actors) 
		{
			for (UActorComponent Component : Actor.GetComponentsByClass(UPrimitiveComponent::StaticClass()))
			{
				UPrimitiveComponent Primitive = Cast<UPrimitiveComponent>(Component);
				if (Primitive.WasRecentlyRendered())
				{
					RenderedActors.Add(Actor);
					break;
				}
			}
		}

		EditorLevel::SetSelectedLevelActors(RenderedActors);
	}

	// For all selected actors, iterate their staticmeshcomponents and restore the material to default.
	UFUNCTION(CallInEditor, Category = "Materials")
	void ClearOverrides()
	{
		TArray<AActor> SelectedActors = EditorUtility::GetSelectionSet();
		for (AActor Actor : SelectedActors)
		{
			for (UActorComponent Component : Actor.GetComponentsByClass(UStaticMeshComponent::StaticClass()))
			{
				UStaticMeshComponent StaticMeshComponent = Cast<UStaticMeshComponent>(Component);
				if (StaticMeshComponent == nullptr)
					continue;

				for (int Index = 0; Index < StaticMeshComponent.GetNumMaterials(); Index++)
				{
					StaticMeshComponent.SetMaterial(Index, StaticMeshComponent.GetStaticMesh().GetMaterial(Index));
				}
			}
		}
	}

	float ComputeBoundsScreenSize(FVector BoundsOrigin, float SphereRadius, FVector ViewOrigin, FMatrix ProjMatrix)
	{
		// float Dist = FVector::Dist(BoundsOrigin, ViewOrigin);
		float Dist = BoundsOrigin.Distance(ViewOrigin);

		// Get projection multiple accounting for view scaling.
		// float ScreenMultiple = FMath::Max(0.5f * ProjMatrix[0][0], 0.5f * ProjMatrix[1][1]);
		float ScreenMultiple = FMath::Max(0.5f * ProjMatrix.XPlane.X, 0.5f * ProjMatrix.YPlane.Y); // Can only assume mtx[0][0] is XPlane.X and 1,1 Y.y

		// Calculate screen-space projected radius
		// float ScreenRadius = ScreenMultiple * SphereRadius / FMath::Max(1.0f, Dist);
		float ScreenRadius = ScreenMultiple * SphereRadius / FMath::Max(1.0f, Dist);

		// // For clarity, we end up comparing the diameter
		return ScreenRadius * 2.0f;
	}

	UFUNCTION(CallInEditor, Category = "Tech Art")
	void PrintSize()
	{
		FMatrix ViewMatrix;
		FMatrix ProjectionMatrix;
		FMatrix ViewProjectionMatrix;

		FMinimalViewInfo View; // Create a View Info that is required to get the projection matrix,
		View.Location = Editor::GetEditorViewLocation();
		View.Rotation = Editor::GetEditorViewRotation();
		View.FOV = Editor::GetEditorViewFOV();
		FVector2D Resolution = Editor::GetEditorViewResolution();
		View.AspectRatio = Resolution.X / Resolution.Y;		
		
		Gameplay::GetViewProjectionMatrix(View, ViewMatrix, ProjectionMatrix, ViewProjectionMatrix);
		
		TArray<AActor> SelectedActors = EditorUtility::GetSelectionSet();
		for (AActor Actor : SelectedActors)
		{
			for (UActorComponent Component : Actor.GetComponentsByClass(UStaticMeshComponent::StaticClass()))
			{
				UStaticMeshComponent StaticMeshComponent = Cast<UStaticMeshComponent>(Component);
				if (StaticMeshComponent == nullptr)
					continue;

				float ScreenSize = ComputeBoundsScreenSize(
					StaticMeshComponent.BoundsOrigin,
					StaticMeshComponent.BoundsRadius,
					View.Location,
					ProjectionMatrix
				);

				Print("Calculated Screensize <" + StaticMeshComponent.GetName() +">: " + ScreenSize);
			}
		}
	}

	UFUNCTION(CallInEditor, Category = "Performance", ToolTip = "Set Default Culling Distance for all Primitives on Selected Actors.")
	void SetDefaultCullingDistance(float Multiplier = 1.0f, bool bOverride = false)
	{
		for (AActor Actor : EditorUtility::GetSelectionSet())
		{
			for (UActorComponent Component : Actor.GetComponentsByClass(UPrimitiveComponent::StaticClass()))
			{
				UPrimitiveComponent Primitive = Cast<UPrimitiveComponent>(Component);
				if (Primitive == nullptr)
					continue;

				if (Primitive.LDMaxDrawDistance > 0.0f && !bOverride)
					continue;

				float CullDistance = Editor::GetDefaultCullingDistance(Primitive) * Multiplier;
				Primitive.SetCullDistance(CullDistance);
			}
		}
	}
	
	UFUNCTION(CallInEditor, Category = "Debug", ToolTip = "Display the bounding box and sphere for selected actors.")
	void ShowActorBounds()
	{
		TArray<AActor> SelectedActors = EditorUtility::GetSelectionSet();
		for (AActor Actor : SelectedActors)
		{
			FBoxSphereBounds Bounds;

			Actor.GetActorBounds(false, Bounds.Origin, Bounds.BoxExtent, false);
			Bounds.SphereRadius = Bounds.BoxExtent.Size();

			USceneComponent RootComponent = Actor.GetRootComponent();
			UStaticMeshComponent StaticMeshComponent = Cast<UStaticMeshComponent>(RootComponent);
			if (StaticMeshComponent != nullptr)
			{
				Bounds.Origin = StaticMeshComponent.GetBoundsOrigin();
				Bounds.BoxExtent = StaticMeshComponent.GetBoundsExtent();
				Bounds.SphereRadius = StaticMeshComponent.GetBoundsRadius();
			}

			System::DrawDebugBox(Bounds.Origin, Bounds.BoxExtent, FLinearColor(0.0, 1.0, 0.0), FRotator(), 10.0f);
			System::DrawDebugSphere(Bounds.Origin, Bounds.SphereRadius, 24, FLinearColor(1.0, 0.752941176471, 0.796078431373), 10.0f);
		}
	}

	UFUNCTION(BlueprintEvent)
	void AssignReplacementMeshes(AActor Actor, TArray<UObject> Assets)
	{
		AGrindspline SplineMesh = Cast<AGrindspline>(Actor);
		if (SplineMesh == nullptr)
		{
			Print("Failed to cast " + Actor.GetName() +  " into a Grind Spline.");
			return;
		}

		SplineMesh.ReplacementMeshes.Empty(); // Make sure previous array is empty,

		for (UObject MeshAsset : Assets)
		{
			UStaticMesh Mesh = Cast<UStaticMesh>(MeshAsset);
			if (Mesh == nullptr)
			{
				Print("Failed to cast " + MeshAsset.GetName() + " into a Static Mesh.");
				continue;
			}

			SplineMesh.ReplacementMeshes.Add(Mesh);
		}

		Editor::RerunConstructionScript(Actor);
	}

	UFUNCTION(CallInEditor, Category = "Utility", ToolTip = "For each selected actor, merge SplineMeshComponents into given number of sections.")
	void MergeSplineMeshComponents(int Sections)
	{
		// See FMeshUtilities::MergeActors to get an idea how the Context Menu "Merge Actors" work.

		if (Sections <= 0)
			return; // Exit if invalid number of sections,

		TArray<AActor> SelectedActors = EditorUtility::GetSelectionSet();
		
		if (SelectedActors.Num() == 0)
			return; // Exit early without actors selected,

		UWorld ActorWorld = SelectedActors[0].GetWorld();
		if (ActorWorld == nullptr) // Check that the world is valid, as done in FMeshUtilities::MergeActors,
			return;

		// Common settings for all merges,
		FMeshMergingSettings Settings;
		UPackage InOuter;
		
		UMaterialInterface Material;
		FVector ZeroVector = FVector::ZeroVector;

		// Make sure all LODs are considered, so we don't have to go in and edit the LODs for the merged mesh.
		Settings.LODSelectionType = EMeshLODSelectionType::AllLODs;
		Settings.bMergePhysicsData = true;
		Settings.bBakeVertexDataToMesh = true;

		FString BasePath = FString("/Game/Environment/MergedSplineMeshes/"); // Folder we want to dump the merged meshes in,

		for (AActor Actor : SelectedActors)
		{	
			TArray<UObject> AssetsToSync;
			TArray<UPrimitiveComponent> ComponentsToMerge;

			// Get all SplineMeshComponents for the actor,
			TArray<USceneComponent> Components;
			Actor.GetRootComponent().GetChildrenComponents(true, Components);
			for (USceneComponent Component : Components )
			{
				USplineMeshComponent SplineMeshComponent = Cast<USplineMeshComponent>(Component);
				if (SplineMeshComponent != nullptr)
					ComponentsToMerge.Add(Cast<UPrimitiveComponent>(SplineMeshComponent));
			}

			if (ComponentsToMerge.Num() == 0)
			{
				Print("No SplineMeshComponents to merge for " + Actor.GetName());
				continue; // No components to merge, skip for this actor,
			}

			// Get the number of components for each section,
			int ChunkSize = int(float(ComponentsToMerge.Num()) / float(Sections) + 0.5);

			// Compose each section and merge,
			for (int Section = 0; Section < Sections; Section++)
			{
				TArray<UPrimitiveComponent> ComponentsInSection;
				int ChunkEndIndex = (Section + 1 == Sections) ? ComponentsToMerge.Num() : ChunkSize * Section + ChunkSize;
				for (int ChunkIndex = ChunkSize * Section; ChunkIndex < ChunkEndIndex; ChunkIndex++)
				{
					ComponentsInSection.Add(ComponentsToMerge[ChunkIndex]);
				}

				// Concat the full name for the asset to create,
				FString OutPath = BasePath + Actor.GetName() + Section;

				// Perform the actual merge of spline components to a StaticMesh,
				Editor::MergeComponentsToStaticMesh(
					ComponentsInSection,
					Actor.GetWorld(),
					Settings,
					OutPath, 
					AssetsToSync, 
					ZeroVector
				);
			}

			for (UObject CreatedAsset : AssetsToSync)
			{	// Make the Content Browser aware of our newly created assets,				
				AssetRegistry::AssetCreated(CreatedAsset);
			}

			Print("Merged SplineMeshComponents, attempting to Assign the created meshes to Replacement Mesh");

			AssignReplacementMeshes(Actor, AssetsToSync);
		}
	}
}
