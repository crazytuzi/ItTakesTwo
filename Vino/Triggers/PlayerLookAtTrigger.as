import Vino.Triggers.PlayerLookAtTriggerComponent;

UCLASS(hideCategories="Rendering Cooking Input Actor LOD AssetUserData Collision Replication Activation Physics")
class APlayerLookAtTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Billboard;
	default Billboard.Sprite = Asset("/Engine/EditorMaterials/MAT_Groups_Visibility.MAT_Groups_Visibility");
	default Billboard.WorldScale3D = FVector(5.f); 

	UPROPERTY(DefaultComponent, ShowOnActor)
	UPlayerLookAtTriggerComponent LookAtTrigger;

	UPROPERTY()
	FPlayerLookAtEvent OnBeginLookAt;

	UPROPERTY()
	FPlayerLookAtEvent OnEndLookAt;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LookAtTrigger.OnBeginLookAt.AddUFunction(this, n"BeginLookAt");
		LookAtTrigger.OnEndLookAt.AddUFunction(this, n"EndLookAt");
	}

	UFUNCTION(NotBlueprintCallable)
	void BeginLookAt(AHazePlayerCharacter Player)
	{
		OnBeginLookAt.Broadcast(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void EndLookAt(AHazePlayerCharacter Player)
	{
		OnEndLookAt.Broadcast(Player);
	}
}
