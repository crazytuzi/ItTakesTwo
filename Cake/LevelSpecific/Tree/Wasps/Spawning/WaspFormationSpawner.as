import Peanuts.Actor.ActorCommonEvents;
import Cake.LevelSpecific.Tree.Wasps.Spawning.WaspSpawner;
import Cake.LevelSpecific.Tree.Wasps.Scenepoints.WaspFormationScenepoint;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;

class AWaspFormationSpawner : AWaspEnemySpawner
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Billboard;
	default Billboard.Sprite = Asset("/Engine/EditorResources/Ai_Spawnpoint.Ai_Spawnpoint");
	
	// The points used for movement of spawned wasps. 
	UPROPERTY(Category = "Formation")
	TArray<AWaspFormationScenepoint> FormationPoints;

	// Own copies of formation points, so we can muck around with them without affecting any other spawners
	// Maps template point -> copy
	UPROPERTY(NotVisible, BlueprintHidden)
	TMap<AWaspFormationScenepoint, AWaspFormationScenepoint> FormationPointCopies;

	TArray<AWaspFormationScenepoint> AvailablePoints;

	// When activated, spawner will rotate this many degrees per second around it's up vector.
	UPROPERTY(Category = "Formation")
	float RotationSpeed = 0.f;

	// If true, spawn wave size etc will always be set to a factor of the number of scene points
	UPROPERTY(Category = "Formation")
	bool bMatchNumbersWithPoints = true;

	default IsActivated = false;
	default SpawnWaveSize = 3;
	default MaxActiveEnemies = 3;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();

		if (bMatchNumbersWithPoints)
			ConstructionMatchNumbersWithPoints();

		ReconstructFormationPoints();
	}

	void ConstructionMatchNumbersWithPoints()
	{
		int NumSps = 0;
		for (AWaspFormationScenepoint Sp : FormationPoints)
		{
			if (Sp != nullptr)
				NumSps++;			
		}
		if (NumSps == 0)
			return;

		SpawnWaveSize = NumSps;
		MaxActiveEnemies = NumSps;
		SpawnPoolSize = NumSps;
	}

	void ReconstructFormationPoints()
	{
		// Clean away points which has been deleted outside. Note that any copies associated with those 
		// will be destroyed below in the 'Remove any attached scenepoints...' step
		if (FormationPointCopies.Contains(nullptr))
			FormationPoints.RemoveAll(nullptr);
		// UE4 bug: maps won't rehash when their UObject keys are destroyed, so just trying to remove nullptr won't work. 
		// Thus we recreate the map when we find a null key below instead
		FormationPointCopies.Remove(nullptr); // Let's keep this if it gets fixed in the future

		// Make sure we don't have any copies of another sp in our formation points list
		for (int i = 0; i < FormationPoints.Num(); i++)
		{
			if (FormationPoints[i] == nullptr) // E.g. we've just added an empty slot
				continue;

			AWaspFormationSpawner Parent = Cast<AWaspFormationSpawner>(FormationPoints[i].GetAttachParentActor());
			if ((Parent != nullptr) && !Parent.FormationPointCopies.Contains(FormationPoints[i]))
			{
				// Replace any copy by the template	
				for (auto Slot : Parent.FormationPointCopies)
				{
					if (Slot.Value == FormationPoints[i])
					{
						FormationPoints[i] = Slot.Key;
						break;
					}
				}
			}
		}

		// Recreate formation points map if there are any copies which are not attached to us. 
		// This will happen e.g. when you duplicate a spawner.
		bool bRecreate = false;
		for (auto Slot : FormationPointCopies)
		{
			if ((Slot.Key == nullptr) || (Slot.Value == nullptr) || (Slot.Value.GetAttachParentActor() != this))
			{
				// Bad slot or copy!
				bRecreate = true;
				break;
			}
		}
		if (bRecreate)
		{
			// Destroy all copies which does not belong to another spawner, then clear map
			for (auto Slot : FormationPointCopies)
			{
				if (Slot.Value != nullptr)
				{
					AWaspFormationSpawner Other = Cast<AWaspFormationSpawner>(Slot.Value.GetAttachParentActor());
					if ((Other == nullptr) || (Other == this) || !Other.HasFormationPointCopy(Slot.Value))
						Slot.Value.DestroyActor();
				}
			}
			FormationPointCopies.Empty(FormationPointCopies.Num());
		}

		// Remove any attached scenepoints which are neither templates nor copies (these are most likely erroneously added sps)
		// Note: This can cause issues when you've duplicated a spawner with attached sps, so don't do this for now.
		// TArray<AActor> AttachedActors;
		// GetAttachedActors(AttachedActors);
		// for (AActor Attachee : AttachedActors)
		// {
		// 	AWaspFormationScenepoint AttachedSp = Cast<AWaspFormationScenepoint>(Attachee);
		// 	if (AttachedSp == nullptr)
		// 		continue;
		// 	if (FormationPoints.Contains(AttachedSp))
		// 		continue; // Template
		// 	if (HasFormationPointCopy(AttachedSp))
		// 		continue; // Copy
		// 	AWaspFormationSpawner Other = Cast<AWaspFormationSpawner>(AttachedSp.GetAttachParentActor());
		// 	if ((Other == nullptr) || (Other == this) || !Other.HasFormationPointCopy(Slot.Value))
		// 	AttachedSp.DestroyActor();
		// }

		// Remove any copies which no longer has a template among the formation points
		TArray<AWaspFormationScenepoint> DeletedPoints;
		TArray<AWaspFormationScenepoint> NewPoints = FormationPoints;
		for (auto Slot : FormationPointCopies)
		{
			if (NewPoints.RemoveAll(Slot.Key) == 0)
			{
				// This template has been removed from formation points list, delete copy
				DeletedPoints.Add(Slot.Key);
			}
		}

		// Delete any copies whose templates have been removed
		for (AWaspFormationScenepoint DeletedPoint : DeletedPoints)
		{
			if (DeletedPoint != nullptr)
				DeletedPoint.OnConstructionScript.Unbind(this, n"OnFormationPointConstruction");
			AWaspFormationScenepoint OldCopy;
			if (FormationPointCopies.Find(DeletedPoint, OldCopy) && (OldCopy != nullptr))
				OldCopy.DestroyActor();
			FormationPointCopies.Remove(DeletedPoint);
		}

		// Add copies for all new formation points
		for (AWaspFormationScenepoint NewPoint : NewPoints)
		{
			if (NewPoint != nullptr)
			{
				ConstructFormationPointCopy(NewPoint);

				// Make sure we can catch any changes to template points
				NewPoint.OnConstructionScript.AddUFunction(this, n"OnFormationPointConstruction");
			}
		}

		// Make sure any copies are at same world location as their templates
		for (auto Slot : FormationPointCopies)
		{
			if (ensure((Slot.Key != nullptr) && (Slot.Value != nullptr)))
			{
				Slot.Value.ActorTransform = Slot.Key.ActorTransform;
			}
		}
	}

	void ConstructFormationPointCopy(AWaspFormationScenepoint Point)
	{
		if (Point == nullptr)
			return;

		if (!FormationPoints.Contains(Point))	
			return; // Can happen e.g. due to construction script of the copy being called on spawn, before we've unbound event

		// Duplicate point and attach copy to ourselves. This way several spawners can use the same template scene points
		// without moving each other's points around.
		AWaspFormationScenepoint Copy = Cast<AWaspFormationScenepoint>(Point.SpawnDuplicateActor(bAllowDuringConstructionScript = true));
		Copy.OnConstructionScript.UnbindObject(this);
		Copy.RootComponent.SetVisibility(false, true);
		Copy.AttachToActor(this, AttachmentRule = EAttachmentRule::KeepWorld);
		FormationPointCopies.Add(Point, Copy);
	}

	bool HasFormationPointCopy(AWaspFormationScenepoint Scenepoint)
	{
		for (auto Slot : FormationPointCopies)
		{
			if (Slot.Value == Scenepoint)
				return true;
		}
		return false;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnFormationPointConstruction(AActor Actor)
	{
		AWaspFormationScenepoint Point = Cast<AWaspFormationScenepoint>(Actor);
		if (Point == nullptr)
			return;

		AWaspFormationScenepoint OldCopy;
		if (FormationPointCopies.Find(Point, OldCopy))
			OldCopy.DestroyActor();
		ConstructFormationPointCopy(Point); 
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Replace template formation points with own copies before we do anything else, including calling super.
		// Formation points may contain duplicates, so iterate over array using map instead of iterating over map.
		for (int i = 0; i < FormationPoints.Num(); i++)
		{
			if (FormationPoints[i] == nullptr) // Ignore empty slots
				continue;
			FormationPointCopies.Find(FormationPoints[i], FormationPoints[i]);
		}
		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);

		if (RotationSpeed != 0.f)
		{
			FRotator NewRot = GetActorRotation();
			NewRot.Yaw += RotationSpeed * DeltaTime;
			SetActorRotation(NewRot);
		}
	}

	UFUNCTION(BlueprintOverride)
	FWaspSpawnParameters GetSpawnParameters()
	{
		FWaspSpawnParameters Params;

		// Set spawn scene point		
		if (AvailablePoints.Num() == 0)
			AvailablePoints = FormationPoints;
		UWaspFormationScenepointComponent FormationPoint = GetBestScenepoint();
		Params.Scenepoint = FormationPoint;
		if (Params.Scenepoint != nullptr)
		{
			Params.Location = FormationPoint.GetFormationSpawnLocation();
			Params.Rotation = FormationPoint.WorldRotation;

			// Don't use this point again until all others have been used
			AvailablePoints.Remove(Cast<AWaspFormationScenepoint>(Params.Scenepoint.GetOwner()));
		}

		return Params;
	}

	UFUNCTION(BlueprintOverride)
	void PostSpawn(AHazeActor Enemy, FWaspSpawnParameters Params)
	{
		Super::PostSpawn(Enemy, Params);

		UWaspFormationScenepointComponent Scenepoint = Cast<UWaspFormationScenepointComponent>(Params.Scenepoint);
		if (Scenepoint == nullptr)
		{
			// Can't spawn this, disable it to allow reuse
			Enemy.DisableActor(Enemy);
			return; 
		}

		FVector SpawnLoc = Scenepoint.GetFormationSpawnLocation();
		FRotator SpawnRot = (Scenepoint.GetWorldLocation() - SpawnLoc).Rotation();
		Enemy.TeleportActor(SpawnLoc, SpawnRot);

		UWaspBehaviourComponent BehaviourComp = UWaspBehaviourComponent::Get(Enemy);
		if (BehaviourComp != nullptr)
		{
			BehaviourComp.UseScenepoint(Scenepoint);
			BehaviourComp.MovementBase = Scenepoint;			
			Enemy.AttachToComponent(Scenepoint, NAME_None, EAttachmentRule::KeepWorld);
		}
	}

	UFUNCTION()
	UWaspFormationScenepointComponent GetBestScenepoint()
	{
		if (AvailablePoints.Num() == 0)
			return nullptr;

		AHazePlayerCharacter Cody = Game::GetCody();
		AHazePlayerCharacter May = Game::GetMay();
		if ((Cody != nullptr) && (May != nullptr))
		{
			// Get random point in any players view
			TArray<AWaspFormationScenepoint> OnScreenPoints;
			for (AWaspFormationScenepoint Scenepoint : AvailablePoints)
			{
				if ((Scenepoint == nullptr) || (Scenepoint.FormationComp == nullptr))
					continue;
				FVector Loc = Scenepoint.FormationComp.GetWorldLocation();
				if (SceneView::IsInView(Cody, Loc) || SceneView::IsInView(May, Loc))
					OnScreenPoints.Add(Scenepoint);
			}
			if (OnScreenPoints.Num() > 0)
				return GetRandomScenepoint(OnScreenPoints);
		}

		// Could not find any points even close to player view, just use random
		return GetRandomScenepoint(AvailablePoints);
	}	

	UWaspFormationScenepointComponent GetRandomScenepoint(const TArray<AWaspFormationScenepoint>& Scenepoints)
	{
		if (Scenepoints.Num() == 0)
			return nullptr;

		int i = FMath::RandRange(0, Scenepoints.Num() - 1);
		return Scenepoints[i].FormationComp;
	}
}
