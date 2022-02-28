import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;
import Vino.Interactions.InteractionComponent;

UCLASS(Abstract, HideCategories = "Rendering Replication Input Debug Actor LOD Cooking")
class AControllablePlantSeed : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent SeedContainerMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SeedRoot;

	UPROPERTY(DefaultComponent, Attach = SeedRoot)
	UStaticMeshComponent SeedMesh;

	UPROPERTY(DefaultComponent, Attach = SeedRoot)
    UInteractionComponent InteractionPoint;
	default InteractionPoint.ActionShape.Type = EHazeShapeType::Sphere;
	default InteractionPoint.ActionShape.SphereRadius = 350.f;
	default InteractionPoint.FocusShape.Type = EHazeShapeType::Sphere;
	default InteractionPoint.FocusShape.SphereRadius = 1000.f;
	default InteractionPoint.Visuals.VisualOffset.Location = FVector(0.f, 0.f, 25.f);

	UPROPERTY(DefaultComponent)
	UWaterHoseImpactComponent WaterHoseImpactComp;
	
	UPROPERTY(EditDefaultsOnly)
	TArray<FWaterLevelColor> Colors;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RevealSeedTimelike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike BobSeedTimeLike;

	bool bSeedRevealStarted = false;
	bool bSeedFullyRevealed = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{}

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		InteractionPoint.Disable(n"Revealed");
		InteractionPoint.OnActivated.AddUFunction(this, n"OnInteractionActivated");
		InteractionPoint.DisableForPlayer(Game::GetMay(), n"May");

		RevealSeedTimelike.BindUpdate(this, n"UpdateRevealSeed");
		RevealSeedTimelike.BindFinished(this, n"FinishRevealSeed");

		BobSeedTimeLike.SetPlayRate(0.25f);
		BobSeedTimeLike.BindUpdate(this, n"UpdateBobSeed");
    }

	UFUNCTION()
	void UpdateRevealSeed(float CurValue)
	{
		float CurHeight = FMath::Lerp(0.f, 360.f, CurValue);
		SeedRoot.SetRelativeLocation(FVector(0.f, 0.f, CurHeight));
	}

	UFUNCTION()
	void FinishRevealSeed()
	{
		bSeedFullyRevealed = true;
		BobSeedTimeLike.PlayFromStart();
		InteractionPoint.Enable(n"Revealed");
	}

	UFUNCTION()
	void UpdateBobSeed(float CurValue)
	{
		float CurHeight = FMath::Lerp(360.f, 300.f, CurValue);
		SeedRoot.SetRelativeLocation(FVector(0.f, 0.f, CurHeight));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		WaterHoseImpactComp.UpdateColorBasedOnWaterLevel(SeedContainerMesh, Colors);

		if (!bSeedRevealStarted && WaterHoseImpactComp.bFullyWatered)
		{
			bSeedRevealStarted = true;
			RevealSeedTimelike.PlayFromStart();
			SetActorTickEnabled(false);
		}
	}

    UFUNCTION()
    void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		UControllablePlantsComponent PlantsComp = UControllablePlantsComponent::Get(Player);

		if (PlantsComp != nullptr)
		{
			InteractionPoint.Disable(n"PickedUp");
			SeedMesh.SetHiddenInGame(true);
		}
    }
}