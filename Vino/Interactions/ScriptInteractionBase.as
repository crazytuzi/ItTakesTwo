
enum EScriptInteractionExclusiveMode
{
	None,
	ExclusiveToMay,
	ExclusiveToCody,
};

UCLASS(Abstract, HideCategories = "Physics Collision Rendering Input Actor LOD Cooking")
class AScriptInteractionBase : AHazeInteractionActor
{
	/* Whether this interaction should be displayed as an exclusive interaction. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Activation", AdvancedDisplay)
	EScriptInteractionExclusiveMode ExclusiveMode = EScriptInteractionExclusiveMode::None;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		if (ExclusiveMode == EScriptInteractionExclusiveMode::ExclusiveToCody)
			TriggerComponent.SetExclusiveForPlayer(EHazePlayer::Cody);
		else if (ExclusiveMode == EScriptInteractionExclusiveMode::ExclusiveToMay)
			TriggerComponent.SetExclusiveForPlayer(EHazePlayer::May);
	}

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        // Add an editor mesh for the actual point in the interaction
        UStaticMeshComponent PointMesh = UStaticMeshComponent::Create(this);
        PointMesh.SetStaticMesh(Asset("/Game/Editor/Interaction/EditorGizmos_Interactpoint"));
		PointMesh.SetHiddenInGame(true);
        PointMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		PointMesh.bIsEditorOnly = true;
    }
};