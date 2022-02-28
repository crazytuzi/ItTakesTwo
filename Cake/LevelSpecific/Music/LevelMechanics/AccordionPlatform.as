import Cake.LevelSpecific.Music.Singing.SongReactionComponent;
import Cake.LevelSpecific.Music.Singing.SongOfLife.SongOfLifeComponent;

UCLASS(Abstract, HideCategories = "Rendering Debug Collision Replication Actor LOD Input Cooking")
class AAccordionPlatform : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent AccordionRoot;

	UPROPERTY(DefaultComponent, Attach = AccordionRoot)
	UStaticMeshComponent AccordionMesh;

	UPROPERTY(DefaultComponent, Attach = AccordionRoot)
	UStaticMeshComponent AccordionPlatform;

	UPROPERTY(DefaultComponent, Attach = AccordionRoot)
	USongOfLifeComponent SongOfLifeComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveAccordionTimeLike;
	default MoveAccordionTimeLike.Duration = 1.f;
	default MoveAccordionTimeLike.bLoop = true;
	default MoveAccordionTimeLike.bSyncOverNetwork = true;
	default MoveAccordionTimeLike.SyncTag = n"Accordion";

	UPROPERTY(Category = "Properties", meta = (ClampMin = "0.0", UIMin = "0.0"))
	float MaximumHeight = 2.f;
	UPROPERTY(Category = "Properties", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float StartFraction = 0.f;

	UPROPERTY()
	AActor ActorToAttach;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		UCurveFloat Curve = MoveAccordionTimeLike.Curve.ExternalCurve;
		float CurAlpha = Curve.GetFloatValue(StartFraction);
		float CurHeight = FMath::Lerp(0.25f, MaximumHeight, CurAlpha);
		AccordionMesh.SetWorldScale3D(FVector(CurHeight, 1.f, 1.f));
		AccordionPlatform.SetRelativeLocation(FVector(0.f, 0.f, CurHeight * 800.f));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SongOfLifeComp.OnStartAffectedBySongOfLife.AddUFunction(this, n"StartSongOfLife");
		SongOfLifeComp.OnStopAffectedBySongOfLife.AddUFunction(this, n"StopSongOfLife");

		MoveAccordionTimeLike.SetNewTime(StartFraction);
		MoveAccordionTimeLike.SetPlayRate(0.25f);
		MoveAccordionTimeLike.BindUpdate(this, n"UpdateMoveAccordion");

		if (ActorToAttach != nullptr)
		{
			ActorToAttach.AttachToComponent(AccordionPlatform, n"", EAttachmentRule::KeepWorld);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void StartSongOfLife(FSongOfLifeInfo Info)
	{
		MoveAccordionTimeLike.PlayWithAcceleration(0.6f);
	}

	UFUNCTION(NotBlueprintCallable)
	void StopSongOfLife(FSongOfLifeInfo Info)
	{
		MoveAccordionTimeLike.StopWithDeceleration(0.6f);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateMoveAccordion(float CurValue)
	{
		float CurMeshScale = FMath::Lerp(0.25f, MaximumHeight, CurValue);
		AccordionMesh.SetWorldScale3D(FVector(CurMeshScale, 1.f, 1.f));

		float CurPlatformHeight = FMath::Lerp(200.f, MaximumHeight * 800.f, CurValue);
		AccordionPlatform.SetRelativeLocation(FVector(0.f, 0.f, CurPlatformHeight));
	}
}