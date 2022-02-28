event void FPlayerReachedFinishLine(AHazePlayerCharacter Player);

class ATimeBombFinishArea : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent PuffSystem;
	
	FPlayerReachedFinishLine EventPlayerReachedFinishLine;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MeshComp.SetCullDistance(Editor::GetDefaultCullingDistance(MeshComp) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MeshComp.SetHiddenInGame(false);
		PuffSystem.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		MeshComp.SetHiddenInGame(false);
		PuffSystem.Deactivate();
	}
}