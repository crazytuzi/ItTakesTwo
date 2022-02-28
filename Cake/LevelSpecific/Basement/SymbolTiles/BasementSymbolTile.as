event void FOnSymbolTileReappeared(int Index);
event void FOnSymbolTileHidden(int Index);

UCLASS(Abstract, HideCategories = "Rendering Debug Replication Input Actor LOD Cooking")
class ABasementSymbolTile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TileRoot;

	UPROPERTY(DefaultComponent, Attach = TileRoot)
	UStaticMeshComponent TileMesh;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ShakeTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RevealPillarTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike HidePillarTimeLike;

	UPROPERTY(meta = (ClampMin = "-1", ClampMax = "9", UIMin = "-1", UIMax = "8"))
	int SymbolIndex = -1;

	bool bSymbolHidden = true;

	UPROPERTY()
	bool bStartRevealed = false;

	UPROPERTY(EditDefaultsOnly)
	TArray<FBasementSymbolMaterialSet> MaterialSets;

	FOnSymbolTileReappeared OnSymbolTileRevealed;
	FOnSymbolTileHidden OnSymbolTileHidden;

	float MaxRotation = 3.f;

	UPROPERTY()
	float TopLocation = 6000.f;

	UPROPERTY()
	float DownTime = 2.8f;

	bool bDisappearing = false;

	bool bPermanentlyDisappeared = false;

	UDecalComponent CurrentDecal;

	UPROPERTY()
	float RevealTime = 1.f;

	UPROPERTY()
	float HideTime = 1.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bStartRevealed)
			TileRoot.SetRelativeLocation(FVector(0.f, 0.f, TopLocation));
		else
			TileRoot.SetRelativeLocation(FVector::ZeroVector);

		if (SymbolIndex == -1)
		{
			CurrentDecal = nullptr;
			return;
		}

		CurrentDecal = UDecalComponent(this);
		CurrentDecal.SetDecalMaterial(MaterialSets[SymbolIndex].DecalMaterial);
		CurrentDecal.AttachToComponent(TileRoot, NAME_None, EAttachmentRule::SnapToTarget);
		CurrentDecal.SetRelativeRotation(FRotator(-90.f, 0.f, 0.f));
		CurrentDecal.SetHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ShakeTimeLike.BindUpdate(this, n"UpdateShake");
		ShakeTimeLike.BindFinished(this, n"FinishShake");

		RevealPillarTimeLike.BindUpdate(this, n"UpdateRevealPillar");
		RevealPillarTimeLike.BindFinished(this, n"FinishRevealPillar");

		HidePillarTimeLike.BindUpdate(this, n"UpdateHidePillar");
		HidePillarTimeLike.BindFinished(this, n"FinishHidePillar");

		RevealPillarTimeLike.SetPlayRate(1.f/RevealTime);
		HidePillarTimeLike.SetPlayRate(1.f/HideTime);
	}

	UFUNCTION()
	void SetSymbolVisibility(bool bHide = false)
	{
		bSymbolHidden = bHide;

		if (bSymbolHidden)
		{
			CurrentDecal.SetFadeOut(0.f, 1.f, false);
		}
		else
		{
			CurrentDecal = Gameplay::SpawnDecalAttached(MaterialSets[SymbolIndex].DecalMaterial, FVector(128.f, 256.f, 256.f), TileRoot, NAME_None, TileRoot.WorldLocation, FRotator(-90.f, 0.f, 0.f), EAttachLocation::KeepWorldPosition, 0.f);
			CurrentDecal.SetFadeIn(0.5f, 1.5f);
		}
	}

	UFUNCTION()
	void HidePillar()
	{
		ShakeTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void HidePillarWithDelay(float Delay)
	{
		System::SetTimer(this, n"HidePillar", Delay, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateShake(float CurValue)
	{
		float Roll = FMath::RandRange(-MaxRotation, MaxRotation) * CurValue;
		float Pitch = FMath::RandRange(-MaxRotation, MaxRotation) * CurValue;
		float Yaw = FMath::RandRange(-MaxRotation, MaxRotation) * CurValue;

		TileMesh.SetRelativeRotation(FRotator(Pitch, Yaw, Roll));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishShake()
	{
		HidePillarTimeLike.PlayFromStart();
		bDisappearing = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateHidePillar(float CurValue)
	{
		float CurLoc = FMath::Lerp(TopLocation, 0.f, CurValue);
		TileRoot.SetRelativeLocation(FVector(0.f, 0.f, CurLoc));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishHidePillar()
	{
		OnSymbolTileHidden.Broadcast(SymbolIndex);
		
		if (SymbolIndex == -1)
			return;

		if (bPermanentlyDisappeared)
			return;

		System::SetTimer(this, n"RevealPillar", DownTime, false);
		BP_PillarHidden();
	}

	UFUNCTION()
	void RevealPillar()
	{
		if (bPermanentlyDisappeared)
			return;

		RevealPillarTimeLike.PlayFromStart();
		BP_PillarRevealed();
	}

	UFUNCTION()
	void RevealPillarWithDelay(float Delay)
	{
		if (bPermanentlyDisappeared)
			return;

		System::SetTimer(this, n"RevealPillar", Delay, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateRevealPillar(float CurValue)
	{
		float CurLoc = FMath::Lerp(0.f, TopLocation, CurValue);
		TileRoot.SetRelativeLocation(FVector(0.f, 0.f, CurLoc));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishRevealPillar()
	{
		OnSymbolTileRevealed.Broadcast(SymbolIndex);
	}

	UFUNCTION(BlueprintEvent)
	void BP_PillarHidden()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_PillarRevealed()
	{}
}

struct FBasementSymbolMaterialSet
{
	UPROPERTY()
	UMaterialInstance SymbolMaterial;

	UPROPERTY()
	UMaterialInstance DecalMaterial;
}