import Cake.LevelSpecific.Basement.SymbolTiles.BasementSymbolTile;
import Rice.Positions.SortListByDistance;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;

event void FOnSymbolSpawned();
event void FOnTilesDropped();

UCLASS(Abstract, HideCategories = "Rendering Debug Collision Actor Input LOD Cooking Replication")
class ABasementSymbolTileManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent DoorRoot;

	UPROPERTY(DefaultComponent, Attach = DoorRoot)
	UStaticMeshComponent DoorMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SymbolRoot;

	UPROPERTY(DefaultComponent, Attach = SymbolRoot)
	UStaticMeshComponent SymbolPlane;

	UPROPERTY(DefaultComponent, Attach = SymbolRoot)
	UHazeSkeletalMeshComponentBase HandMesh;

	UPROPERTY(NotEditable, NotVisible)
	TArray<ABasementSymbolTile> AllFloorTiles;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike OpenDoorTimeLike;
	default OpenDoorTimeLike.Duration = 0.5f;

	UPROPERTY(EditDefaultsOnly)
	TArray<FLinearColor> DebugColors;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CloseHandAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence OpenHandAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence HandMH;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ShowSymbolRumble;
	
	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect RevealPillarSetRumble;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect HidePillarSetRumble;
	
	UPROPERTY()
	FOnSymbolSpawned OnSymbolSpawned;

	UPROPERTY()
	FOnTilesDropped OnTilesDropped;

	TArray<int> FallenIndexes;

	int CurrentTileSetIndex = 0;

	UPROPERTY(NotVisible)
	TArray<ABasementSymbolTile> TilesToFall;

	UPROPERTY()
	TArray<FBasementSymbolTileSets> TileSets;

	bool bActive = false;

	bool bShowSymbols = true;

	float TimeUntilFall = 2.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		int CurIndex = 0;
		for (FBasementSymbolTileSets CurTileSet : TileSets)
		{
			FLinearColor Color;
			if (DebugColors.Num() - 1 <= CurIndex)
				 Color = FLinearColor::LucBlue;
			else
				Color = DebugColors[CurIndex];
				
			if (CurTileSet.bVisualizeSet)
			{
				for (ABasementSymbolTile CurTile : CurTileSet.Tiles)
				{
					if (CurTile != nullptr)
					{
						UBasementSymbolTileVisualizerComponent Visualizer = UBasementSymbolTileVisualizerComponent::Create(this);
						FVector DebugDrawLoc = CurTile.bStartRevealed ?CurTile.ActorLocation + FVector(0.f, 0.f, CurTile.TopLocation) : CurTile.ActorLocation;
						Visualizer.SetVisualizerProperties(DebugDrawLoc, Color);
					}
				}
			}
			CurIndex++;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OpenDoorTimeLike.BindUpdate(this, n"UpdateOpenDoor");
		OpenDoorTimeLike.BindFinished(this, n"FinishOpenDoor");

		FindAllTiles();

		if (bActive)
		{
			ActivateTileFall();
			OpenDoorTimeLike.PlayFromStart();
		}
	}

	UFUNCTION()
	void DisableSymbols()
	{
		bShowSymbols = false;
		HandMesh.SetHiddenInGame(true);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateOpenDoor(float CurValue)
	{
		float CurRot = FMath::Lerp(0.f, 125.f, CurValue);
		DoorRoot.SetRelativeRotation(FRotator(0, CurRot, 0.f));

		if (!bShowSymbols)
			return;

		FVector CurPlaneScale = FMath::Lerp(0.f, 30.f, CurValue);
		SymbolPlane.SetRelativeScale3D(CurPlaneScale);

		FVector PlaneStartPos = FVector(1650.f, -1900.f, 750.f);
		FVector PlaneEndPos = FVector(1650.f, 1000.f, 1300.f);
		FVector CurPlanePos = FMath::Lerp(PlaneStartPos, PlaneEndPos, CurValue);
		SymbolRoot.SetRelativeLocation(CurPlanePos);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishOpenDoor()
	{

	}

	UFUNCTION()
	void ActivateSymbolTiles()
	{
		bActive = true;
		OpenDoorTimeLike.PlayFromStart();
		ShowNewSymbol();
	}
	
	UFUNCTION()
	void OpenDoor()
	{
		OpenDoorTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void CloseDoor()
	{
		OpenDoorTimeLike.ReverseFromEnd();
	}

	UFUNCTION()
	void SetTileSetIndex(int Index)
	{
		CurrentTileSetIndex = Index;
	}

	UFUNCTION(NotBlueprintCallable)
	void ShowNewSymbol()
	{
		if (!bActive)
			return;

		PlayHandMH();
		SymbolPlane.SetHiddenInGame(false);

		TilesToFall.Empty();

		TArray<int> CurrentTileSetIndexes;
		for (ABasementSymbolTile CurTile : TileSets[CurrentTileSetIndex].Tiles)
		{
			CurrentTileSetIndexes.AddUnique(CurTile.SymbolIndex);
		}

		int TileIndex = 0;
		CurrentTileSetIndexes.Shuffle();
		for (int CurIndex : CurrentTileSetIndexes)
		{
			if (!FallenIndexes.Contains(CurIndex))
			{
				TileIndex = CurIndex;
				continue;
			}
		}

		FallenIndexes.Add(TileIndex);
		for (ABasementSymbolTile CurTile : TileSets[CurrentTileSetIndex].Tiles)
		{
			if (CurTile.SymbolIndex == TileIndex)
				TilesToFall.Add(CurTile);
		}

		UMaterialInstance SymbolMat = TilesToFall[0].MaterialSets[TilesToFall[0].SymbolIndex].SymbolMaterial;
		SymbolPlane.SetMaterial(0, SymbolMat);

		System::SetTimer(this, n"ActivateTileFall", TimeUntilFall, false);

		BP_ShowNewSymbol();

		OnSymbolSpawned.Broadcast();

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayForceFeedback(ShowSymbolRumble, false, true, NAME_None);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ShowNewSymbol()
	{}

	UFUNCTION(NotBlueprintCallable)
	void ActivateTileFall()
	{
		for (ABasementSymbolTile CurTile : TilesToFall)
		{
			CurTile.HidePillar();
		}

		TilesToFall[0].OnSymbolTileRevealed.AddUFunction(this, n"ReaddSymbolAsValid");

		OnTilesDropped.Broadcast();
		CloseHand();
	}

	void CloseHand()
	{
		SymbolPlane.SetHiddenInGame(true);

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = CloseHandAnim;
		AnimParams.PlayRate = 1.5f;

		FHazeAnimationDelegate AnimFinished;
		AnimFinished.BindUFunction(this, n"OpenHand");

		HandMesh.PlaySlotAnimation(FHazeAnimationDelegate(), AnimFinished, AnimParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void OpenHand()
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = OpenHandAnim;
		AnimParams.PlayRate = 1.5f;

		FHazeAnimationDelegate AnimFinished;
		AnimFinished.BindUFunction(this, n"ShowNewSymbol");

		HandMesh.PlaySlotAnimation(FHazeAnimationDelegate(), AnimFinished, AnimParams);
	}

	void PlayHandMH()
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = HandMH;
		AnimParams.bLoop = true;

		HandMesh.PlaySlotAnimation(AnimParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void ReaddSymbolAsValid(int Index)
	{
		FallenIndexes.Remove(Index);
	}

	UFUNCTION()
	void DeactivateTileManager()
	{
		bActive = false;
	}

	void FindAllTiles()
	{
		if (TileSets.Num() == 0)
			return;

		AllFloorTiles.Empty();

		TArray<AActor> Actors;
		Gameplay::GetAllActorsOfClass(ABasementSymbolTile::StaticClass(), Actors);

		for (AActor CurActor : Actors)
		{
			ABasementSymbolTile CurTile = Cast<ABasementSymbolTile>(CurActor);
			if (CurTile != nullptr)
			{
				AllFloorTiles.Add(CurTile);
			}
		}
	}

	UFUNCTION(BlueprintPure)
	TArray<ABasementSymbolTile> GetCurrentTiles()
	{
		return TileSets[CurrentTileSetIndex].Tiles;
	}

	UFUNCTION(BlueprintPure)
	TArray<ABasementSymbolTile> GetTileSet(int Index)
	{
		return TileSets[Index].Tiles;
	}

	UFUNCTION()
	void RevealPillarSet(int Index)
	{
		TArray<AHazeActor> InActors;
		for (ABasementSymbolTile CurPillar : TileSets[Index].Tiles)
		{
			AHazeActor HazeActor = Cast<AHazeActor>(CurPillar);
			InActors.Add(HazeActor);
		}
		TArray<AHazeActor> OutActors = SortActorArrayByDistance(InActors, GetActiveParentBlobActor().ActorLocation, false);
		TArray<ABasementSymbolTile> Pillars;

		for (AHazeActor CurActor : OutActors)
		{
			ABasementSymbolTile Pillar = Cast<ABasementSymbolTile>(CurActor);
			if (Pillar != nullptr)
				Pillars.Add(Pillar);
		}

		int CurIndex = 1;
		for (ABasementSymbolTile  CurPillar : Pillars)
		{
			CurPillar.RevealPillarWithDelay(CurIndex * 0.05f);
			CurIndex++;
		}

		Pillars[Pillars.Num() - 1].OnSymbolTileRevealed.AddUFunction(this, n"LastPillarInSetRevealed");

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayForceFeedback(RevealPillarSetRumble, true, true, n"Reveal");
	}

	UFUNCTION()
	void HidePillarSet(int Index)
	{
		TArray<AHazeActor> InActors;
		for (ABasementSymbolTile CurPillar : TileSets[Index].Tiles)
		{
			AHazeActor HazeActor = Cast<AHazeActor>(CurPillar);
			InActors.Add(HazeActor);
		}
		TArray<AHazeActor> OutActors = SortActorArrayByDistance(InActors, GetActiveParentBlobActor().ActorLocation, false);
		TArray<ABasementSymbolTile> Pillars;

		for (AHazeActor CurActor : OutActors)
		{
			ABasementSymbolTile Pillar = Cast<ABasementSymbolTile>(CurActor);
			if (Pillar != nullptr)
				Pillars.Add(Pillar);
		}

		int CurIndex = 1;
		for (ABasementSymbolTile  CurPillar : Pillars)
		{
			CurPillar.HidePillarWithDelay(CurIndex * 0.05f);
			CurIndex++;
		}

		Pillars[Pillars.Num() - 1].OnSymbolTileHidden.AddUFunction(this, n"LastPillarInSetHidden");

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayForceFeedback(HidePillarSetRumble, true, true, n"Hide");
	}

	UFUNCTION()
	void LastPillarInSetRevealed(int Index)
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.StopForceFeedback(RevealPillarSetRumble, n"Reveal");
	}

	UFUNCTION()
	void LastPillarInSetHidden(int Index)
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.StopForceFeedback(HidePillarSetRumble, n"Hide");
	}

	UFUNCTION()
	void RemovePillarsFromSet(int Index, TArray<ABasementSymbolTile> Pillars)
	{
		for (ABasementSymbolTile CurPillar : Pillars)
		{
			TileSets[Index].Tiles.Remove(CurPillar);
		}
	}

	UFUNCTION()
	void AddPillarsToSet(int Index, TArray<ABasementSymbolTile> Pillars)
	{
		for (ABasementSymbolTile CurPillar : Pillars)
		{
			TileSets[Index].Tiles.AddUnique(CurPillar);
		}
	}
}

struct FBasementSymbolTileSets
{
	UPROPERTY()
	bool bVisualizeSet = true;

	UPROPERTY()
	TArray<ABasementSymbolTile> Tiles;
}

class UBasementSymbolTileVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UBasementSymbolTileVisualizerComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UBasementSymbolTileVisualizerComponent Comp = Cast<UBasementSymbolTileVisualizerComponent>(Component);
        if (Comp == nullptr)
            return;

		DrawArrow(Comp.VisualizerLocation + FVector(0.f, 0.f, 250.f), Comp.VisualizerLocation, Comp.VisualizerColor, 60.f, 15.f);
    }
}

class UBasementSymbolTileVisualizerComponent : UActorComponent
{
	FVector VisualizerLocation;
	FLinearColor VisualizerColor;

	UFUNCTION()
	void SetVisualizerProperties(FVector Location, FLinearColor Color)
	{
		VisualizerLocation = Location;
		VisualizerColor = Color;
	}
}